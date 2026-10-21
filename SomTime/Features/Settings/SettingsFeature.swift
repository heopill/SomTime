//
//  SettingsFeature.swift
//  SomTime
//

import ComposableArchitecture
import MessageUI
import UIKit

@Reducer
struct SettingsFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.clockDesign) var clockDesign
        @Shared(.clockColor) var clockColor
        @Shared(.isTwentyFourHour) var isTwentyFourHour
        @Shared(.showsSeconds) var showsSeconds
        @Shared(.showsDayPeriod) var showsDayPeriod
        @Shared(.pipAspectRatio) var pipAspectRatio
        /// 광고 동의 상태 (광고 개인정보 설정 항목 표시 여부)
        @Shared(.adConsent) var adConsent
        /// 알림 권한 상태 (확인하기 전에는 nil)
        var notificationStatus: NotificationAuthorizationStatus?
        /// 문의 메일 작성 창 표시 여부
        var isMailComposePresented = false
        /// 문의 정보 복사 완료 토스트 표시 여부
        var isContactInfoCopiedToastPresented = false
        @Presents var privacyPolicy: PrivacyPolicyFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action {
        case onAppear
        case appBecameActive
        case notificationStatusLoaded(NotificationAuthorizationStatus)
        case backButtonTapped
        case designSelected(ClockDesign)
        case colorSelected(ClockColor)
        case timeFormatChanged(isTwentyFourHour: Bool)
        case showsSecondsChanged(Bool)
        case showsDayPeriodChanged(Bool)
        case pipAspectRatioChanged(PipAspectRatio)
        case languageRowTapped
        case notificationRowTapped
        case privacyPolicyRowTapped
        case contactRowTapped
        case rateAppRowTapped
        case adPrivacyOptionsRowTapped
        case mailComposeDismissed
        case contactInfoCopiedToastExpired
        case privacyPolicy(PresentationAction<PrivacyPolicyFeature.Action>)
        case alert(PresentationAction<Alert>)

        enum Alert {
            case copyContactInfoTapped
        }
    }

    private nonisolated enum CancelID {
        case contactInfoCopiedToast
    }

    @Dependency(\.adClient) var adClient
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.notificationClient) var notificationClient
    @Dependency(\.openURL) var openURL

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear, .appBecameActive:
                // 설정 앱에서 알림을 켜고 돌아왔을 때도 바뀐 상태를 보여 준다
                return loadNotificationStatus()

            case let .notificationStatusLoaded(status):
                state.notificationStatus = status

                return .none

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

            case let .showsDayPeriodChanged(showsDayPeriod):
                state.$showsDayPeriod.withLock { $0 = showsDayPeriod }

                return .none

            case let .pipAspectRatioChanged(aspectRatio):
                state.$pipAspectRatio.withLock { $0 = aspectRatio }

                return .none

            case .languageRowTapped:
                // 시스템 설정 앱의 섬타임 페이지 (언어 항목에서 앱 언어를 바꿀 수 있음)
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return .none }

                return .run { _ in await openURL(settingsURL) }

            case .notificationRowTapped:
                // 아직 묻지 않았으면 권한을 묻고 (설정 앱에 알림 항목이 아직 없다), 정해졌으면 설정 앱의 섬타임 알림 페이지로 보낸다
                guard state.notificationStatus != .notDetermined else {
                    return .run { send in
                        _ = await notificationClient.requestAuthorization()
                        await send(.notificationStatusLoaded(notificationClient.authorizationStatus()))
                    }
                }
                guard let settingsURL = URL(string: UIApplication.openNotificationSettingsURLString) else { return .none }

                return .run { _ in await openURL(settingsURL) }

            case .privacyPolicyRowTapped:
                state.privacyPolicy = PrivacyPolicyFeature.State()

                return .none

            case .contactRowTapped:
                // 메일 앱을 쓸 수 있으면 기기/앱 정보가 채워진 작성 창을, 아니면 문의 주소 안내 알럿을 띄운다
                if MFMailComposeViewController.canSendMail() {
                    state.isMailComposePresented = true
                } else {
                    state.alert = .mailUnavailable
                }

                return .none

            case .rateAppRowTapped:
                // 시스템 평가 요청 창은 1년에 3번까지만 뜨므로, 언제든 App Store 리뷰 작성 화면으로 보낸다
                guard let writeReviewURL = ReviewRequest.writeReviewURL else { return .none }

                return .run { _ in await openURL(writeReviewURL) }

            case .adPrivacyOptionsRowTapped:
                // Google 광고 동의 설정 창. 닫은 뒤 바뀐 동의 상태를 배너에 반영한다
                return .run { [adConsent = state.$adConsent] _ in
                    let consent = await adClient.presentPrivacyOptions()
                    adConsent.withLock { $0 = consent }
                }

            case .mailComposeDismissed:
                state.isMailComposePresented = false

                return .none

            case .alert(.presented(.copyContactInfoTapped)):
                let clipboardText = SupportInfo.clipboardText
                state.isContactInfoCopiedToastPresented = true

                return .run { send in
                    await MainActor.run { UIPasteboard.general.string = clipboardText }
                    try await Task.sleep(for: .seconds(2))
                    await send(.contactInfoCopiedToastExpired)
                }
                .cancellable(id: CancelID.contactInfoCopiedToast, cancelInFlight: true)

            case .contactInfoCopiedToastExpired:
                state.isContactInfoCopiedToastPresented = false

                return .none

            case .privacyPolicy, .alert:
                return .none
            }
        }
        .ifLet(\.$privacyPolicy, action: \.privacyPolicy) {
            PrivacyPolicyFeature()
        }
        .ifLet(\.$alert, action: \.alert)
    }

    /// 지금 알림 권한 상태를 읽어 온다
    private func loadNotificationStatus() -> Effect<Action> {
        return .run { send in
            await send(.notificationStatusLoaded(notificationClient.authorizationStatus()))
        }
    }
}

extension AlertState where Action == SettingsFeature.Action.Alert {
    static let mailUnavailable = AlertState {
        TextState("mailUnavailableTitle")
    } actions: {
        ButtonState(action: .copyContactInfoTapped) {
            TextState("copyContactInfo")
        }
        ButtonState(role: .cancel) {
            TextState("ok")
        }
    } message: {
        TextState("mailUnavailableMessage \(SupportInfo.recipient)")
    }
}
