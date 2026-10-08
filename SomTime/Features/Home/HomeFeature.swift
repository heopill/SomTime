//
//  HomeFeature.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

@Reducer
struct HomeFeature {
    /// Live Activity가 시스템에 의해 자동 종료되기까지의 시간 (약 8시간)
    static let islandAutoEndInterval: TimeInterval = 8 * 60 * 60

    @ObservableState
    struct State: Equatable {
        var isIslandOn = false
        // TODO: Live Activity 이슈에서 실제 Activity 시작 시각으로 교체
        var islandStartedAt: Date?
        var isPipOn = false
        // TODO: 설정 화면 이슈에서 App Group UserDefaults 값으로 교체
        var clockDesign: ClockDesign = .classic
        var clockColor: ClockColor = .amber
        @Presents var destination: Destination.State?
    }

    enum Action {
        case islandToggled(Bool)
        case pipToggled(Bool)
        case settingsButtonTapped
        case serverTimeRowTapped
        case destination(PresentationAction<Destination.Action>)
    }

    @Dependency(\.date.now) var now

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .islandToggled(isOn):
                // TODO: Live Activity 이슈에서 Activity 시작/종료 연결
                state.isIslandOn = isOn
                state.islandStartedAt = isOn ? now : nil

                return .none

            case let .pipToggled(isOn):
                // TODO: PiP 이슈에서 PiP 시작/종료 연결
                state.isPipOn = isOn

                return .none

            case .settingsButtonTapped:
                state.destination = .settings(SettingsFeature.State())

                return .none

            case .serverTimeRowTapped:
                state.destination = .serverTime(ServerTimeFeature.State())

                return .none

            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension HomeFeature {
    @Reducer
    enum Destination {
        case settings(SettingsFeature)
        case serverTime(ServerTimeFeature)
    }
}

extension HomeFeature.Destination.State: Equatable {}
