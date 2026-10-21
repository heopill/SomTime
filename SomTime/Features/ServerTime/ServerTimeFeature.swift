//
//  ServerTimeFeature.swift
//  SomTime
//

import ComposableArchitecture
import Foundation
import UIKit

@Reducer
struct ServerTimeFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.serverTimeURL) var urlText
        @Shared(.serverTimeMeasurement) var savedMeasurement
        @Shared(.serverTimeDisplayMode) var displayMode
        @Shared(.showsServerTimeMilliseconds) var showsMilliseconds
        @Shared(.isServerTimeTargetOn) var isTargetOn
        @Shared(.serverTimeTargetDate) var targetDate
        @Shared(.vibratesBeforeServerTimeTarget) var vibratesBeforeTarget
        @Shared(.reviewRequestRecord) var reviewRequestRecord
        @SharedReader(.serverClockSession) var session
        @SharedReader(.clockDesign) var clockDesign
        @SharedReader(.clockColor) var clockColor
        @SharedReader(.isTwentyFourHour) var isTwentyFourHour
        @SharedReader(.showsSeconds) var showsSeconds
        @SharedReader(.showsDayPeriod) var showsDayPeriod
        var isMeasuring = false
        @Presents var alert: AlertState<Action.Alert>?

        /// 지금 입력한 주소로 측정한 결과 (주소를 바꾸면 측정 전 상태로 보인다)
        var measurement: ServerTimeMeasurement? {
            guard let savedMeasurement, savedMeasurement.input == urlText else { return nil }

            return savedMeasurement
        }

        /// 결과 카드와 PiP에 밀리초를 표시할지 여부 (PiP 방식에서만)
        var showsMillisecondsInResult: Bool {
            return displayMode == .pip && showsMilliseconds
        }

        var isRunning: Bool {
            return session != nil
        }

        /// 지금 입력한 주소의 서버 오프셋 (측정 전이면 0)
        var offset: TimeInterval {
            return measurement?.offset ?? 0
        }
    }

    enum Action {
        case onAppear
        case backButtonTapped
        case urlTextChanged(String)
        case measureButtonTapped
        case measureFinished(Result<ServerTimeOffsetResult, Error>)
        case displayModeSelected(ServerTimeDisplayMode)
        case showsMillisecondsChanged(Bool)
        case targetToggled(Bool)
        case targetTimeChanged(Date)
        case targetVibrationToggled(Bool)
        case notificationAuthorizationDenied
        case startButtonTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {
            case openNotificationSettingsTapped
        }

        enum Delegate {
            /// 서버 시간 시계를 시작하거나, 실행 중이면 새 설정으로 바꾼다 (홈이 일반 시계를 끄고 처리)
            case startRequested(ServerClockSession)
            /// 서버 시간 시계를 끈다
            case stopRequested
        }
    }

    private nonisolated enum CancelID {
        case measurement
    }

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.serverTimeClient) var serverTimeClient
    @Dependency(\.notificationClient) var notificationClient
    @Dependency(\.openURL) var openURL
    @Dependency(\.reviewClient) var reviewClient
    @Dependency(\.date.now) var now

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                // 지난 목표 시각은 끈다 (한 번 쓰고 끝나는 목표라 다음 날로 넘기지 않는다)
                if state.isTargetOn, state.targetDate <= now.addingTimeInterval(state.offset) {
                    state.$isTargetOn.withLock { $0 = false }
                }

                return .none

            case .backButtonTapped:
                return .run { _ in await dismiss() }

            case let .urlTextChanged(text):
                state.$urlText.withLock { $0 = text }

                return .none

            case .measureButtonTapped:
                guard !state.isMeasuring else { return .none }
                guard let url = ServerTimeURL.url(from: state.urlText) else {
                    state.alert = .invalidURL

                    return .none
                }

                state.isMeasuring = true

                return .run { send in
                    do {
                        let result = try await serverTimeClient.measure(url)
                        await send(.measureFinished(.success(result)))
                    } catch {
                        await send(.measureFinished(.failure(error)))
                    }
                }
                .cancellable(id: CancelID.measurement, cancelInFlight: true)

            case let .measureFinished(.success(result)):
                state.isMeasuring = false
                guard let host = ServerTimeURL.url(from: state.urlText)?.host() else { return .none }

                let measurement = ServerTimeMeasurement(
                    input: state.urlText,
                    host: host,
                    offset: result.offset,
                    accuracy: result.accuracy,
                    measuredAt: now
                )
                state.$savedMeasurement.withLock { $0 = measurement }
                let reviewRequest: Effect<Action> = reviewClient.recordSuccess(in: state.$reviewRequestRecord)
                // 목표 시각 알림도 다시 맞춘 오프셋으로 다시 예약한다
                let rescheduleAlerts: Effect<Action> = state.isTargetOn
                    ? scheduleTargetAlerts(state, requestsAuthorization: false)
                    : .none

                // 같은 사이트의 서버 시간 시계가 실행 중이면 다시 맞춘 오프셋을 바로 반영한다
                guard let session = state.session, session.clock.host == host else {
                    return .merge(rescheduleAlerts, reviewRequest)
                }

                return .merge(
                    rescheduleAlerts,
                    reviewRequest,
                    .send(.delegate(.startRequested(makeSession(state, mode: session.mode))))
                )

            case let .measureFinished(.failure(error)):
                state.isMeasuring = false
                guard !(error is CancellationError) else { return .none }

                state.alert = (error as? ServerTimeError) == .noDateHeader ? .noDateHeader : .measureFailed

                return .none

            case let .displayModeSelected(mode):
                state.$displayMode.withLock { $0 = mode }

                return .none

            case let .showsMillisecondsChanged(showsMilliseconds):
                state.$showsMilliseconds.withLock { $0 = showsMilliseconds }
                // 서버 시간 PiP가 실행 중이면 같은 오프셋으로 밀리초 표시만 바로 반영한다
                guard var session = state.session, session.mode == .pip else { return .none }

                session.clock.showsMilliseconds = showsMilliseconds

                return .send(.delegate(.startRequested(session)))

            case let .targetToggled(isOn):
                state.$isTargetOn.withLock { $0 = isOn }
                guard isOn else {
                    return .merge(
                        .run { _ in await notificationClient.removeTargetAlerts() },
                        updateRunningTarget(state)
                    )
                }

                // 고른 시각이 지났으면 다음 날 그 시각으로 맞춘다
                let targetDate = ServerTimeTarget.nextDate(matching: state.targetDate, after: now.addingTimeInterval(state.offset))
                state.$targetDate.withLock { $0 = targetDate }

                return .merge(
                    scheduleTargetAlerts(state, requestsAuthorization: true),
                    updateRunningTarget(state)
                )

            case let .targetTimeChanged(time):
                let targetDate = ServerTimeTarget.nextDate(matching: time, after: now.addingTimeInterval(state.offset))
                state.$targetDate.withLock { $0 = targetDate }
                guard state.isTargetOn else { return .none }

                return .merge(
                    scheduleTargetAlerts(state, requestsAuthorization: false),
                    updateRunningTarget(state)
                )

            case let .targetVibrationToggled(isOn):
                state.$vibratesBeforeTarget.withLock { $0 = isOn }

                return updateRunningTarget(state)

            case .notificationAuthorizationDenied:
                state.alert = .notificationsDisabled

                return .none

            case .alert(.presented(.openNotificationSettingsTapped)):
                guard let settingsURL = URL(string: UIApplication.openNotificationSettingsURLString) else { return .none }

                return .run { _ in await openURL(settingsURL) }

            case .startButtonTapped:
                guard !state.isRunning else {
                    return .send(.delegate(.stopRequested))
                }
                guard state.measurement != nil else { return .none }
                guard state.displayMode == .island || DeviceCapability.supportsPictureInPicture else {
                    state.alert = .pipUnsupported

                    return .none
                }

                return .send(.delegate(.startRequested(makeSession(state, mode: state.displayMode))))

            case .alert, .delegate:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    /// 마지막 측정 결과와 표시 옵션으로 서버 시간 시계를 만든다
    private func makeSession(_ state: State, mode: ServerTimeDisplayMode) -> ServerClockSession {
        let measurement = state.savedMeasurement
        let clock = ServerTimeClock(
            host: measurement?.host ?? "",
            offset: measurement?.offset ?? 0,
            showsMilliseconds: mode == .pip && state.showsMilliseconds,
            targetDate: activeTargetDate(state),
            vibratesBeforeTarget: state.vibratesBeforeTarget
        )

        return ServerClockSession(mode: mode, clock: clock)
    }

    /// 시계에 표시할 목표 시각 (꺼져 있거나 이미 지났으면 nil)
    private func activeTargetDate(_ state: State) -> Date? {
        guard state.isTargetOn, state.targetDate > now.addingTimeInterval(state.offset) else { return nil }

        return state.targetDate
    }

    /// 서버 시간 시계가 실행 중이면 같은 오프셋으로 목표 시각 · 진동 설정만 바로 반영한다
    private func updateRunningTarget(_ state: State) -> Effect<Action> {
        guard var session = state.session else { return .none }

        session.clock.targetDate = activeTargetDate(state)
        session.clock.vibratesBeforeTarget = state.vibratesBeforeTarget

        return .send(.delegate(.startRequested(session)))
    }

    /// 목표 시각 5 · 3 · 1분 전 알림을 다시 예약한다.
    /// requestsAuthorization이면 먼저 알림 권한을 묻고, 거부되어 있으면 설정으로 안내한다 (남은 시간 표시는 그대로 쓸 수 있다)
    private func scheduleTargetAlerts(_ state: State, requestsAuthorization: Bool) -> Effect<Action> {
        let alert = ServerTimeTargetAlert(
            fireDate: state.targetDate.addingTimeInterval(-state.offset),
            targetText: ClockTimeFormatter.string(
                from: state.targetDate,
                isTwentyFourHour: state.isTwentyFourHour,
                showsSeconds: false,
                showsDayPeriod: state.showsDayPeriod
            ),
            host: state.measurement?.host
        )

        return .run { send in
            if requestsAuthorization {
                guard await notificationClient.requestAuthorization() else {
                    await send(.notificationAuthorizationDenied)

                    return
                }
            }
            await notificationClient.scheduleTargetAlerts(alert)
        }
    }
}

extension AlertState where Action == ServerTimeFeature.Action.Alert {
    static let invalidURL = AlertState {
        TextState("serverTimeInvalidURLTitle")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("ok")
        }
    } message: {
        TextState("serverTimeInvalidURLMessage")
    }

    static let measureFailed = AlertState {
        TextState("serverTimeMeasureFailedTitle")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("ok")
        }
    } message: {
        TextState("serverTimeMeasureFailedMessage")
    }

    static let noDateHeader = AlertState {
        TextState("serverTimeMeasureFailedTitle")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("ok")
        }
    } message: {
        TextState("serverTimeNoDateHeaderMessage")
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

    static let notificationsDisabled = AlertState {
        TextState("notificationDisabledTitle")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("ok")
        }
        ButtonState(action: .openNotificationSettingsTapped) {
            TextState("openSettings")
        }
    } message: {
        TextState("notificationDisabledMessage")
    }
}
