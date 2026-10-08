//
//  HomeFeature.swift
//  SomTime
//

import ComposableArchitecture
import Foundation
import UIKit

@Reducer
struct HomeFeature {
    @ObservableState
    struct State: Equatable {
        var isIslandOn = false
        var islandStartedAt: Date?
        var isPipOn = false
        @SharedReader(.clockDesign) var clockDesign
        @SharedReader(.clockColor) var clockColor
        @SharedReader(.isTwentyFourHour) var isTwentyFourHour
        @SharedReader(.showsSeconds) var showsSeconds
        @Presents var destination: Destination.State?
        @Presents var alert: AlertState<Action.Alert>?

        var displaySettings: ClockDisplaySettings {
            return ClockDisplaySettings(
                design: clockDesign,
                color: clockColor,
                isTwentyFourHour: isTwentyFourHour,
                showsSeconds: showsSeconds
            )
        }
    }

    enum Action {
        case onAppear
        case sceneBecameActive
        case clockSettingsChanged
        case islandToggled(Bool)
        case islandStarted(Date)
        case islandStartFailed
        case islandRestored(Date)
        case islandEnded
        case pipToggled(Bool)
        case settingsButtonTapped
        case serverTimeRowTapped
        case destination(PresentationAction<Destination.Action>)
        case alert(PresentationAction<Alert>)

        enum Alert {
            case openSettingsTapped
        }
    }

    private nonisolated enum CancelID {
        case islandEndObservation
    }

    @Dependency(\.liveActivityClient) var liveActivityClient
    @Dependency(\.openURL) var openURL
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 앱을 다시 실행했을 때 이미 켜져 있는 Live Activity 상태를 복원한다
                return .run { send in
                    if let startedAt = await liveActivityClient.runningStartDate() {
                        await send(.islandRestored(startedAt))
                    }
                }

            case .sceneBecameActive, .clockSettingsChanged:
                // 설정 변경을 반영하고, iOS 17 타이머의 기준 자정을 오늘로 갱신한다
                guard state.isIslandOn, state.islandStartedAt != nil else { return .none }

                let contentState = activityContentState(state)

                return .run { _ in await liveActivityClient.update(contentState) }

            case let .islandToggled(isOn):
                state.isIslandOn = isOn
                guard isOn else {
                    state.islandStartedAt = nil

                    return .merge(
                        .cancel(id: CancelID.islandEndObservation),
                        .run { _ in await liveActivityClient.end() }
                    )
                }

                let contentState = activityContentState(state)

                return .run { send in
                    do {
                        let startedAt = try await liveActivityClient.start(contentState)
                        await send(.islandStarted(startedAt))
                    } catch {
                        await send(.islandStartFailed)
                    }
                }

            case let .islandStarted(startedAt):
                state.islandStartedAt = startedAt

                return observeIslandEnd()

            case .islandStartFailed:
                state.isIslandOn = false
                state.islandStartedAt = nil
                state.alert = .liveActivitiesDisabled

                return .none

            case let .islandRestored(startedAt):
                state.isIslandOn = true
                state.islandStartedAt = startedAt
                let contentState = activityContentState(state)

                return .merge(
                    .run { _ in await liveActivityClient.update(contentState) },
                    observeIslandEnd()
                )

            case .islandEnded:
                state.isIslandOn = false
                state.islandStartedAt = nil

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

            case .alert(.presented(.openSettingsTapped)):
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return .none }

                return .run { _ in await openURL(settingsURL) }

            case .destination, .alert:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
        .ifLet(\.$alert, action: \.alert)
    }

    /// 지금 설정과 오늘 자정으로 Live Activity 표시 상태를 만든다
    private func activityContentState(_ state: State) -> ClockActivityAttributes.ContentState {
        return ClockActivityAttributes.ContentState(
            settings: state.displaySettings,
            referenceMidnight: calendar.startOfDay(for: now)
        )
    }

    /// 실행 중인 Live Activity가 시스템이나 사용자에 의해 끝나는지 지켜본다
    private func observeIslandEnd() -> Effect<Action> {
        return .run { send in
            await liveActivityClient.ended()
            await send(.islandEnded)
        }
        .cancellable(id: CancelID.islandEndObservation, cancelInFlight: true)
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

extension AlertState where Action == HomeFeature.Action.Alert {
    static let liveActivitiesDisabled = AlertState {
        TextState("liveActivityDisabledTitle")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("ok")
        }
        ButtonState(action: .openSettingsTapped) {
            TextState("openSettings")
        }
    } message: {
        TextState("liveActivityDisabledMessage")
    }
}
