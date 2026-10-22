//
//  CaptchaPracticeFeature.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

@Reducer
struct CaptchaPracticeFeature {
    @ObservableState
    struct State: Equatable {
        var phase: Phase = .ready
        @Shared(.captchaPracticeDifficulty) var difficulty
        @Shared(.captchaPracticeRecords) var records
        @Shared(.reviewRequestRecord) var reviewRequestRecord

        enum Phase: Equatable {
            /// 난이도 선택
            case ready
            /// 진행 중
            case playing(CaptchaPracticeRound)
            /// 통과
            case result(CaptchaPracticeResult)
        }
    }

    enum Action {
        case backButtonTapped
        case difficultySelected(CaptchaDifficulty)
        case startButtonTapped
        case stopButtonTapped
        case inputChanged(String)
        case refreshButtonTapped
        case submitButtonTapped
        case changeDifficultyButtonTapped
    }

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

                return .run { _ in await dismiss() }

            case let .difficultySelected(difficulty):
                state.$difficulty.withLock { $0 = difficulty }

                return .none

            case .startButtonTapped:
                let difficulty = state.difficulty
                state.phase = .playing(
                    CaptchaPracticeRound(difficulty: difficulty, challenge: makeChallenge(difficulty), startedAt: now)
                )

                return .none

            case .stopButtonTapped:
                state.phase = .ready

                return .none

            case let .inputChanged(input):
                guard case var .playing(round) = state.phase else { return .none }

                round.input = CaptchaPractice.sanitized(input)
                // 다시 입력하기 시작하면 틀렸다는 안내를 숨긴다
                if !round.input.isEmpty {
                    round.showsWrongAnswer = false
                }
                state.phase = .playing(round)

                return .none

            case .refreshButtonTapped:
                guard case var .playing(round) = state.phase else { return .none }

                // 실제 예매처처럼 새 문자로 바꿔도 시간은 이어서 잰다
                round.challenge = makeChallenge(round.difficulty)
                round.input = ""
                round.refreshCount += 1
                round.showsWrongAnswer = false
                state.phase = .playing(round)

                return .none

            case .submitButtonTapped:
                guard case var .playing(round) = state.phase, round.input.count == CaptchaPractice.length else { return .none }

                // 틀리면 새 문자로 바꾸고, 처음 문자가 뜬 순간부터 계속 잰다
                guard round.input == round.challenge.text else {
                    round.challenge = makeChallenge(round.difficulty)
                    round.input = ""
                    round.wrongCount += 1
                    round.showsWrongAnswer = true
                    state.phase = .playing(round)

                    return .none
                }

                let totalTime = now.timeIntervalSince(round.startedAt)
                let isNewBest = state.$records.withLock { $0.record(totalTime, for: round.difficulty) }
                state.phase = .result(
                    CaptchaPracticeResult(
                        difficulty: round.difficulty,
                        totalTime: totalTime,
                        wrongCount: round.wrongCount,
                        refreshCount: round.refreshCount,
                        isNewBest: isNewBest
                    )
                )

                return reviewClient.recordSuccess(in: state.$reviewRequestRecord)

            case .changeDifficultyButtonTapped:
                state.phase = .ready

                return .none
            }
        }
    }

    /// 난이도에 맞는 새 보안 문자를 만든다
    private func makeChallenge(_ difficulty: CaptchaDifficulty) -> CaptchaChallenge {
        return withRandomNumberGenerator { generator in
            CaptchaChallenge.random(difficulty: difficulty, using: &generator)
        }
    }
}
