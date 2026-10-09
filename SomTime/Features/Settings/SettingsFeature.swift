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
        @Shared(.pipAspectRatio) var pipAspectRatio
        /// 문의 메일 작성 창 표시 여부
        var isMailComposePresented = false
        /// 문의 정보 복사 완료 토스트 표시 여부
        var isContactInfoCopiedToastPresented = false
        @Presents var privacyPolicy: PrivacyPolicyFeature.State?
        @Presents var alert: AlertState<Action.Alert>?
    }

    enum Action {
        case backButtonTapped
        case designSelected(ClockDesign)
        case colorSelected(ClockColor)
        case timeFormatChanged(isTwentyFourHour: Bool)
        case showsSecondsChanged(Bool)
        case pipAspectRatioChanged(PipAspectRatio)
        case languageRowTapped
        case privacyPolicyRowTapped
        case contactRowTapped
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
