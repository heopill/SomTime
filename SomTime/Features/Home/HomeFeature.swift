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
        @SharedReader(.pipAspectRatio) var pipAspectRatio
        /// 서버 시간 화면에서 켠 시계. 켜져 있는 동안 일반 시계 토글은 꺼져 있다 (시계는 한 번에 하나만)
        @Shared(.serverClockSession) var serverClock
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

        /// 서버 시간 시계에 쓸 설정 (지금 표시 설정 + 측정한 오프셋)
        func serverSettings(_ session: ServerClockSession) -> ClockDisplaySettings {
            var settings = displaySettings
            settings.serverTime = session.clock

            return settings
        }
    }

    enum Action {
        case onAppear
        case clockSettingsChanged
        case pipAspectRatioChanged
        case islandToggled(Bool)
        case islandStarted(Date)
        case islandStartFailed
        case islandRestored(Date)
        case islandEnded
        case pipToggled(Bool)
        case pipStartFailed
        case pipClosed
        case serverIslandStarted
        case serverIslandRestored(ServerTimeClock)
        case serverClockStartFailed(ServerTimeDisplayMode)
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
        case pipStart
        case pipEventObservation
    }

    @Dependency(\.liveActivityClient) var liveActivityClient
    @Dependency(\.pipClockClient) var pipClockClient
    @Dependency(\.openURL) var openURL

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 앱을 다시 실행했을 때 이미 켜져 있는 Live Activity 상태를 복원한다 (서버 시간 시계인지 구분)
                return .merge(
                    .run { send in
                        guard let running = await liveActivityClient.running() else { return }

                        if let serverTime = running.state.settings.serverTime {
                            await send(.serverIslandRestored(serverTime))
                        } else {
                            await send(.islandRestored(running.startedAt))
                        }
                    },
                    observePipEvents()
                )

            case .clockSettingsChanged:
                // 실행 중인 Live Activity와 PiP 시계에 바뀐 설정을 반영한다
                var effects: [Effect<Action>] = []
                if state.isIslandOn, state.islandStartedAt != nil {
                    effects.append(updateIsland(state.displaySettings))
                }
                if state.isPipOn {
                    effects.append(updatePip(state.displaySettings, state.pipAspectRatio))
                }
                if let session = state.serverClock {
                    let settings = state.serverSettings(session)
                    switch session.mode {
                    case .island: effects.append(updateIsland(settings))
                    case .pip: effects.append(updatePip(settings, state.pipAspectRatio))
                    }
                }

                return .merge(effects)

            case .pipAspectRatioChanged:
                // 떠 있는 PiP 시계에 바뀐 창 비율을 반영한다
                if state.isPipOn {
                    return updatePip(state.displaySettings, state.pipAspectRatio)
                }
                if let session = state.serverClock, session.mode == .pip {
                    return updatePip(state.serverSettings(session), state.pipAspectRatio)
                }

                return .none

            case let .islandToggled(isOn):
                state.isIslandOn = isOn
                guard isOn else {
                    state.islandStartedAt = nil

                    return .merge(
                        .cancel(id: CancelID.islandEndObservation),
                        .run { _ in await liveActivityClient.end() }
                    )
                }

                // 서버 시간 시계가 켜져 있으면 먼저 끈다 (시계는 한 번에 하나만)
                let stopServerClock = stopServerClock(&state)
                let contentState = activityContentState(state.displaySettings)

                return .concatenate(
                    .cancel(id: CancelID.islandEndObservation),
                    stopServerClock,
                    .run { send in
                        do {
                            let startedAt = try await liveActivityClient.start(contentState)
                            await send(.islandStarted(startedAt))
                        } catch {
                            await send(.islandStartFailed)
                        }
                    }
                )

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
                let contentState = activityContentState(state.displaySettings)

                return .merge(
                    .run { _ in await liveActivityClient.update(contentState) },
                    observeIslandEnd()
                )

            case .islandEnded:
                state.isIslandOn = false
                state.islandStartedAt = nil
                if state.serverClock?.mode == .island {
                    state.$serverClock.withLock { $0 = nil }
                }

                return .none

            case let .pipToggled(isOn):
                guard isOn else {
                    state.isPipOn = false

                    return .merge(
                        .cancel(id: CancelID.pipStart),
                        .run { _ in await pipClockClient.stop() }
                    )
                }
                guard DeviceCapability.supportsPictureInPicture else {
                    state.isPipOn = false
                    state.alert = .pipUnsupported

                    return .none
                }

                state.isPipOn = true
                // 서버 시간 시계가 켜져 있으면 먼저 끈다 (시계는 한 번에 하나만)
                let stopServerClock = stopServerClock(&state)
                let settings = state.displaySettings
                let aspectRatio = state.pipAspectRatio

                return .concatenate(
                    stopServerClock,
                    .run { send in
                        do {
                            try await pipClockClient.start(settings, aspectRatio)
                        } catch is CancellationError {
                            // 시작을 기다리는 중에 토글을 끈 경우
                        } catch {
                            await send(.pipStartFailed)
                        }
                    }
                    .cancellable(id: CancelID.pipStart, cancelInFlight: true)
                )

            case .pipStartFailed:
                state.isPipOn = false
                state.alert = .pipStartFailed

                return .none

            case .pipClosed:
                state.isPipOn = false
                if state.serverClock?.mode == .pip {
                    state.$serverClock.withLock { $0 = nil }
                }

                return .none

            case let .destination(.presented(.serverTime(.delegate(.startRequested(session))))):
                return startServerClock(&state, session: session)

            case .destination(.presented(.serverTime(.delegate(.stopRequested)))):
                return stopServerClock(&state)

            case .serverIslandStarted:
                return observeIslandEnd()

            case let .serverIslandRestored(clock):
                let session = ServerClockSession(mode: .island, clock: clock)
                state.$serverClock.withLock { $0 = session }

                return .merge(
                    updateIsland(state.serverSettings(session)),
                    observeIslandEnd()
                )

            case let .serverClockStartFailed(mode):
                if state.serverClock?.mode == mode {
                    state.$serverClock.withLock { $0 = nil }
                }
                state.alert = mode == .island ? .liveActivitiesDisabled : .pipStartFailed

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

    /// 표시 설정으로 Live Activity 표시 상태를 만든다
    private func activityContentState(_ settings: ClockDisplaySettings) -> ClockActivityAttributes.ContentState {
        return ClockActivityAttributes.ContentState(settings: settings)
    }

    /// 실행 중인 Live Activity에 표시 설정을 반영한다
    private func updateIsland(_ settings: ClockDisplaySettings) -> Effect<Action> {
        let contentState = activityContentState(settings)

        return .run { _ in await liveActivityClient.update(contentState) }
    }

    /// 서버 시간 시계를 켠다. 홈의 일반 시계 토글은 끄고, 이미 같은 자리에서 실행 중이면 새 설정만 반영한다
    private func startServerClock(_ state: inout State, session: ServerClockSession) -> Effect<Action> {
        let previous = state.serverClock
        var effects: [Effect<Action>] = []

        // 일반 시계 끄기 (같은 자리는 새 시계가 이어받으므로 끝내지 않고 관찰 · 시작 대기만 취소한다)
        if state.isIslandOn {
            state.isIslandOn = false
            state.islandStartedAt = nil
            effects.append(.cancel(id: CancelID.islandEndObservation))
            if session.mode != .island {
                effects.append(.run { _ in await liveActivityClient.end() })
            }
        }
        if state.isPipOn {
            state.isPipOn = false
            effects.append(.cancel(id: CancelID.pipStart))
            if session.mode != .pip {
                effects.append(.run { _ in await pipClockClient.stop() })
            }
        }

        // 다른 자리에서 실행 중이던 서버 시간 시계 끄기
        if let previous, previous.mode != session.mode {
            effects.append(stopEffect(for: previous.mode))
        }

        state.$serverClock.withLock { $0 = session }
        let settings = state.serverSettings(session)
        let aspectRatio = state.pipAspectRatio

        switch session.mode {
        case .island where previous?.mode == .island:
            effects.append(updateIsland(settings))

        case .island:
            let contentState = activityContentState(settings)
            effects.append(.cancel(id: CancelID.islandEndObservation))
            effects.append(.run { send in
                do {
                    _ = try await liveActivityClient.start(contentState)
                    await send(.serverIslandStarted)
                } catch {
                    await send(.serverClockStartFailed(.island))
                }
            })

        case .pip:
            // 이미 떠 있는 PiP는 창을 유지한 채 서버 시간으로 다시 그린다
            effects.append(
                .run { send in
                    do {
                        try await pipClockClient.start(settings, aspectRatio)
                    } catch is CancellationError {
                        // 시작을 기다리는 중에 끈 경우
                    } catch {
                        await send(.serverClockStartFailed(.pip))
                    }
                }
                .cancellable(id: CancelID.pipStart, cancelInFlight: true)
            )
        }

        return .concatenate(effects)
    }

    /// 실행 중인 서버 시간 시계를 끈다 (없으면 아무것도 하지 않는다)
    private func stopServerClock(_ state: inout State) -> Effect<Action> {
        guard let session = state.serverClock else { return .none }

        state.$serverClock.withLock { $0 = nil }

        return stopEffect(for: session.mode)
    }

    /// 해당 자리의 시계를 끄는 효과
    private func stopEffect(for mode: ServerTimeDisplayMode) -> Effect<Action> {
        switch mode {
        case .island:
            return .concatenate(
                .cancel(id: CancelID.islandEndObservation),
                .run { _ in await liveActivityClient.end() }
            )
        case .pip:
            return .concatenate(
                .cancel(id: CancelID.pipStart),
                .run { _ in await pipClockClient.stop() }
            )
        }
    }

    /// 실행 중인 Live Activity가 시스템이나 사용자에 의해 끝나는지 지켜본다
    private func observeIslandEnd() -> Effect<Action> {
        return .run { send in
            await liveActivityClient.ended()
            await send(.islandEnded)
        }
        .cancellable(id: CancelID.islandEndObservation, cancelInFlight: true)
    }

    /// 떠 있는 PiP 시계에 표시 설정과 창 비율을 반영한다
    private func updatePip(_ settings: ClockDisplaySettings, _ aspectRatio: PipAspectRatio) -> Effect<Action> {
        return .run { _ in await pipClockClient.update(settings, aspectRatio) }
    }

    /// 사용자나 시스템이 PiP 창을 닫는지 지켜본다
    private func observePipEvents() -> Effect<Action> {
        return .run { send in
            for await event in await pipClockClient.events() {
                switch event {
                case .closed:
                    await send(.pipClosed)
                }
            }
        }
        .cancellable(id: CancelID.pipEventObservation, cancelInFlight: true)
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

    static let pipUnsupported = AlertState {
        TextState("pipUnsupportedTitle")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("ok")
        }
    } message: {
        TextState("pipUnsupportedMessage")
    }

    static let pipStartFailed = AlertState {
        TextState("pipStartFailedTitle")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("ok")
        }
    } message: {
        TextState("pipStartFailedMessage")
    }
}
