//
//  TicketingPracticeFeature.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

@Reducer
struct TicketingPracticeFeature {
    @ObservableState
    struct State: Equatable {
        @SharedReader(.timingPracticeRecords) var timingRecords
        @SharedReader(.seatPracticeRecords) var seatRecords
        @SharedReader(.captchaPracticeRecords) var captchaRecords
        @SharedReader(.clockDesign) var clockDesign
        @SharedReader(.clockColor) var clockColor
        @SharedReader(.isTwentyFourHour) var isTwentyFourHour
        @SharedReader(.showsDayPeriod) var showsDayPeriod
        @Presents var destination: Destination.State?

        /// 카드 미리보기 시계에 쓸 표시 설정
        var clockSettings: ClockDisplaySettings {
            return ClockDisplaySettings(
                design: clockDesign,
                color: clockColor,
                isTwentyFourHour: isTwentyFourHour,
                showsSeconds: true,
                showsDayPeriod: showsDayPeriod
            )
        }
    }

    enum Action {
        case backButtonTapped
        case timingPracticeTapped
        case seatPracticeTapped
        case captchaPracticeTapped
        case destination(PresentationAction<Destination.Action>)
    }

    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in await dismiss() }

            case .timingPracticeTapped:
                state.destination = .timing(TimingPracticeFeature.State())

                return .none

            case .seatPracticeTapped:
                state.destination = .seat(SeatPracticeFeature.State())

                return .none

            case .captchaPracticeTapped:
                state.destination = .captcha(CaptchaPracticeFeature.State())

                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension TicketingPracticeFeature {
    @Reducer
    enum Destination {
        case timing(TimingPracticeFeature)
        case seat(SeatPracticeFeature)
        case captcha(CaptchaPracticeFeature)
    }
}

extension TicketingPracticeFeature.Destination.State: Equatable {}
