//
//  SeatPracticeFeature.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

@Reducer
struct SeatPracticeFeature {
    @ObservableState
    struct State: Equatable {
        var phase: Phase = .ready
        @Shared(.seatPracticeDifficulty) var difficulty
        @Shared(.seatPracticeSeatsVanish) var seatsVanish
        @Shared(.seatPracticeRecords) var records
        @Shared(.reviewRequestRecord) var reviewRequestRecord

        enum Phase: Equatable {
            /// 난이도 선택
            case ready
            /// 진행 중
            case playing(SeatPracticeRound)
            /// 성공 또는 시간 초과
            case result(SeatPracticeResult)
        }
    }

    enum Action {
        case backButtonTapped
        case difficultySelected(SeatDifficulty)
        case seatsVanishChanged(Bool)
        case startButtonTapped
        case stopButtonTapped
        case seatTapped(SeatID)
        case seatTaken(SeatID)
        case bookButtonTapped
        case timeLimitReached
        case changeDifficultyButtonTapped
    }

    private nonisolated enum CancelID {
        case timeLimit
        case seatTaking
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.reviewClient) var reviewClient
    @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                // 결과 화면의 뒤로는 난이도 선택으로, 난이도 선택 화면의 뒤로는 티켓팅 연습으로 돌아간다
                if case .result = state.phase {
                    state.phase = .ready

                    return .none
                }

                return .merge(
                    cancelRound(),
                    .run { _ in await dismiss() }
                )

            case let .difficultySelected(difficulty):
                state.$difficulty.withLock { $0 = difficulty }

                return .none

            case let .seatsVanishChanged(seatsVanish):
                state.$seatsVanish.withLock { $0 = seatsVanish }

                return .none

            case .startButtonTapped:
                let difficulty = state.difficulty
                let seatsVanish = state.seatsVanish
                let (availableSeats, takings) = withRandomNumberGenerator { generator in
                    let count = Int.random(in: difficulty.availableSeatRange, using: &generator)
                    let seats = Set(SeatID.all.shuffled(using: &generator).prefix(count))
                    let takings = seatsVanish
                        ? SeatTakingSchedule.make(seats: seats, timeLimit: difficulty.timeLimit, using: &generator)
                        : []

                    return (seats, takings)
                }
                state.phase = .playing(SeatPracticeRound(difficulty: difficulty, availableSeats: availableSeats, startedAt: now))

                return .merge(
                    .run { send in
                        try await clock.sleep(for: .seconds(difficulty.timeLimit))
                        await send(.timeLimitReached)
                    }
                    .cancellable(id: CancelID.timeLimit, cancelInFlight: true),
                    takeSeats(takings)
                )

            case .stopButtonTapped:
                state.phase = .ready

                return cancelRound()

            case let .seatTapped(seat):
                guard case var .playing(round) = state.phase, round.availableSeats.contains(seat) else { return .none }

                // 선택한 좌석을 다시 누르면 해제하고, 다른 빈 좌석을 누르면 그 좌석으로 바꾼다
                if round.selectedSeat == seat {
                    round.selectedSeat = nil
                    round.selectedAt = nil
                } else {
                    round.selectedSeat = seat
                    round.selectedAt = now
                }
                round.isSelectedSeatTaken = false
                state.phase = .playing(round)

                return .none

            case let .seatTaken(seat):
                guard case var .playing(round) = state.phase else { return .none }

                // 다른 사람이 먼저 잡은 좌석은 판매 완료가 되고, 고른 좌석이었다면 선택이 풀린다
                round.availableSeats.remove(seat)
                if round.selectedSeat == seat {
                    round.selectedSeat = nil
                    round.selectedAt = nil
                    round.isSelectedSeatTaken = true
                }
                state.phase = .playing(round)

                return .none

            case .bookButtonTapped:
                guard case let .playing(round) = state.phase,
                      let seat = round.selectedSeat,
                      let selectedAt = round.selectedAt else { return .none }

                let bookedAt = now
                let totalTime = bookedAt.timeIntervalSince(round.startedAt)
                // 제한 시간 알림보다 버튼 처리가 늦게 도착한 경우는 시간 초과로 본다
                guard totalTime <= round.difficulty.timeLimit else {
                    state.phase = .result(failureResult(round))

                    return cancelRound()
                }

                let isNewBest = state.$records.withLock { $0.record(totalTime, for: round.difficulty) }
                state.phase = .result(
                    SeatPracticeResult(
                        difficulty: round.difficulty,
                        seat: seat,
                        seatSelectionTime: selectedAt.timeIntervalSince(round.startedAt),
                        bookingTime: bookedAt.timeIntervalSince(selectedAt),
                        isNewBest: isNewBest
                    )
                )

                return .merge(
                    cancelRound(),
                    reviewClient.recordSuccess(in: state.$reviewRequestRecord)
                )

            case .timeLimitReached:
                guard case let .playing(round) = state.phase else { return .none }

                state.phase = .result(failureResult(round))

                return .cancel(id: CancelID.seatTaking)

            case .changeDifficultyButtonTapped:
                state.phase = .ready

                return .none
            }
        }
    }

    /// 일정에 맞춰 다른 사람이 좌석을 하나씩 잡아가게 한다
    private func takeSeats(_ takings: [SeatTaking]) -> Effect<Action> {
        guard !takings.isEmpty else { return .none }

        return .run { send in
            var elapsed: TimeInterval = 0
            for taking in takings {
                try await clock.sleep(for: .seconds(taking.time - elapsed))
                elapsed = taking.time
                await send(.seatTaken(taking.seat))
            }
        }
        .cancellable(id: CancelID.seatTaking, cancelInFlight: true)
    }

    /// 진행 중인 한 판의 제한 시간 · 좌석 사라짐 타이머를 멈춘다
    private func cancelRound() -> Effect<Action> {
        return .merge(
            .cancel(id: CancelID.timeLimit),
            .cancel(id: CancelID.seatTaking)
        )
    }

    /// 시간 초과 결과를 만든다 (그때까지 고른 좌석이 있으면 좌석 선택 시간을 남긴다)
    private func failureResult(_ round: SeatPracticeRound) -> SeatPracticeResult {
        return SeatPracticeResult(
            difficulty: round.difficulty,
            seat: round.selectedSeat,
            seatSelectionTime: round.selectedAt?.timeIntervalSince(round.startedAt),
            bookingTime: nil
        )
    }
}
