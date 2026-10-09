//
//  ServerTimeFeature.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

@Reducer
struct ServerTimeFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.serverTimeURL) var urlText
        @Shared(.serverTimeMeasurement) var savedMeasurement
        @Shared(.serverTimeDisplayMode) var displayMode
        @Shared(.showsServerTimeMilliseconds) var showsMilliseconds
        @SharedReader(.serverClockSession) var session
        @SharedReader(.clockDesign) var clockDesign
        @SharedReader(.clockColor) var clockColor
        @SharedReader(.isTwentyFourHour) var isTwentyFourHour
        @SharedReader(.showsSeconds) var showsSeconds
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
    }

    enum Action {
        case backButtonTapped
        case urlTextChanged(String)
        case measureButtonTapped
        case measureFinished(Result<ServerTimeOffsetResult, Error>)
        case displayModeSelected(ServerTimeDisplayMode)
        case showsMillisecondsChanged(Bool)
        case startButtonTapped
        case alert(PresentationAction<Alert>)
        case delegate(Delegate)

        enum Alert: Equatable {}

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
    @Dependency(\.date.now) var now

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
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

                // 같은 사이트의 서버 시간 시계가 실행 중이면 다시 맞춘 오프셋을 바로 반영한다
                guard let session = state.session, session.clock.host == host else { return .none }

                return .send(.delegate(.startRequested(makeSession(state, mode: session.mode))))

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
            showsMilliseconds: mode == .pip && state.showsMilliseconds
        )

        return ServerClockSession(mode: mode, clock: clock)
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
}
