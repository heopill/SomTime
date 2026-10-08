//
//  SettingsFeature.swift
//  SomTime
//

import ComposableArchitecture
import UIKit

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.clockDesign) var clockDesign
        @Shared(.clockColor) var clockColor
        @Shared(.isTwentyFourHour) var isTwentyFourHour
        @Shared(.showsSeconds) var showsSeconds
        @Shared(.pipAspectRatio) var pipAspectRatio
    }

    enum Action {
        case backButtonTapped
        case designSelected(ClockDesign)
        case colorSelected(ClockColor)
        case timeFormatChanged(isTwentyFourHour: Bool)
        case showsSecondsChanged(Bool)
        case pipAspectRatioChanged(PipAspectRatio)
        case languageRowTapped
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.openURL) var openURL

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .backButtonTapped:
                return .run { _ in await dismiss() }

            case let .designSelected(design):
                state.$clockDesign.withLock { $0 = design }

                return .none

            case let .colorSelected(color):
                state.$clockColor.withLock { $0 = color }

                return .none

            case let .timeFormatChanged(isTwentyFourHour):
                state.$isTwentyFourHour.withLock { $0 = isTwentyFourHour }

                return .none

            case let .showsSecondsChanged(showsSeconds):
                state.$showsSeconds.withLock { $0 = showsSeconds }

                return .none

            case let .pipAspectRatioChanged(aspectRatio):
                state.$pipAspectRatio.withLock { $0 = aspectRatio }

                return .none

            case .languageRowTapped:
                // 시스템 설정 앱의 섬타임 페이지 (언어 항목에서 앱 언어를 바꿀 수 있음)
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return .none }

                return .run { _ in await openURL(settingsURL) }
            }
        }
    }
}
