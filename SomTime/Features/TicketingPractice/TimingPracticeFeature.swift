//
//  TimingPracticeFeature.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

@Reducer
struct TimingPracticeFeature {
    @ObservableState
    struct State: Equatable {
        var phase: Phase = .ready
        @Shared(.timingPracticeShowsMilliseconds) var showsMilliseconds
        @Shared(.timingPracticeRecords) var records
        @SharedReader(.clockDesign) var clockDesign
        @SharedReader(.clockColor) var clockColor
        @SharedReader(.isTwentyFourHour) var isTwentyFourHour
        @SharedReader(.showsDayPeriod) var showsDayPeriod

        /// 연습 시계에 쓸 표시 설정
        var clockSettings: ClockDisplaySettings {
            return ClockDisplaySettings(
                design: clockDesign,
                color: clockColor,
                isTwentyFourHour: isTwentyFourHour,
                showsSeconds: true,
                showsDayPeriod: showsDayPeriod
            )
        }

        enum Phase: Equatable {
            /// 시작 전
            case ready
            /// 진행 중 (연습 시계가 09:59:50을 가리킨 순간)
            case playing(startedAt: Date)
            /// 결과
            case result(TimingPracticeOutcome)
        }
    }

    enum Action {
        case backButtonTapped
        case showsMillisecondsChanged(Bool)
        case startButtonTapped
        case stopButtonTapped
        case bookButtonTapped
        case missTimerFired
        case quitButtonTapped
    }

    private nonisolated enum CancelID {
        case missTimer
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                // 결과 화면의 뒤로는 시작 전으로, 시작 전 화면의 뒤로는 티켓팅 연습으로 돌아간다
                if case .result = state.phase {
                    state.phase = .ready

                    return .none
                }

                return .merge(
                    .cancel(id: CancelID.missTimer),
                    .run { _ in await dismiss() }
                )

            case let .showsMillisecondsChanged(showsMilliseconds):
                state.$showsMilliseconds.withLock { $0 = showsMilliseconds }

                return .none

            case .startButtonTapped:
                state.phase = .playing(startedAt: now)

                // 정각이 지나 자동 종료 시각까지 누르지 않으면 끝낸다
                return .run { send in
                    try await clock.sleep(for: .seconds(TimingPractice.leadTime + TimingPractice.missTimeout))
                    await send(.missTimerFired)
                }
                .cancellable(id: CancelID.missTimer, cancelInFlight: true)

            case .stopButtonTapped:
                state.phase = .ready

                return .cancel(id: CancelID.missTimer)

            case .bookButtonTapped:
                guard case let .playing(startedAt) = state.phase else { return .none }

                let difference = now.timeIntervalSince(startedAt) - TimingPractice.leadTime
                state.$records.withLock { $0.add(difference) }
                state.phase = .result(.pressed(difference: difference))

                return .cancel(id: CancelID.missTimer)

            case .missTimerFired:
                guard case .playing = state.phase else { return .none }

                state.phase = .result(.missed)

                return .none

            case .quitButtonTapped:
                return .run { _ in await dismiss() }
            }
        }
    }
}
