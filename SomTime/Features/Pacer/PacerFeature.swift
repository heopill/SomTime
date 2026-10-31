//
//  PacerFeature.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

/// 홈 → 페이서 버튼. 페이서를 고르고, 출석 · 광고로 모은 포인트로 잠긴 페이서를 해제한다
@Reducer
struct PacerFeature {
    @ObservableState
    struct State: Equatable {
        @Shared(.pipPacer) var selectedPacer
        @Shared(.pacerWallet) var wallet
        @SharedReader(.clockDesign) var clockDesign
        @SharedReader(.clockColor) var clockColor
        @SharedReader(.isTwentyFourHour) var isTwentyFourHour
        @SharedReader(.showsSeconds) var showsSeconds
        @SharedReader(.showsDayPeriod) var showsDayPeriod
        /// 광고 동의 상태 (광고를 요청할 수 없으면 광고 버튼을 끈다)
        @SharedReader(.adConsent) var adConsent
        /// 지금 출석 보상을 받을 수 있는지 여부 (화면에 들어오거나 앱으로 돌아올 때 다시 확인한다)
        var canAttend = false
        /// 오늘 받은 광고 보상 횟수 (출석과 같은 때 다시 확인한다)
        var todayAdRewardCount = 0
        /// 보상형 광고를 띄우는 중인지 여부 (버튼을 여러 번 누르지 않도록)
        var isShowingAd = false
        var toast: PacerToast?
        @Presents var alert: AlertState<Action.Alert>?

        /// 오늘 광고 보상을 더 받을 수 있는지 여부
        var hasAdRewardsLeft: Bool {
            return todayAdRewardCount < PacerWallet.dailyAdRewardLimit
        }

        /// 광고 버튼을 누를 수 있는지 여부
        var canWatchAd: Bool {
            return adConsent?.canRequestAds == true && !isShowingAd && hasAdRewardsLeft
        }
    }

    enum Action {
        case onAppear
        case appBecameActive
        case backButtonTapped
        case pacerTapped(PipPacer)
        case attendanceButtonTapped
        case watchAdButtonTapped
        case adFinished(earnedReward: Bool)
        case adUnavailable
        case toastExpired
        case alert(PresentationAction<Alert>)

        enum Alert: Equatable {
            case unlockConfirmed(PipPacer)
        }
    }

    private nonisolated enum CancelID {
        case toast
    }

    @Dependency(\.adClient) var adClient
    @Dependency(\.continuousClock) var clock
    @Dependency(\.date.now) var now
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                refreshDailyRewards(&state)

                // 광고 버튼을 누르자마자 띄울 수 있도록 미리 불러온다
                return .run { _ in await adClient.loadRewardedAd() }

            case .appBecameActive:
                // 화면을 켜 둔 채 오전 9시가 지났으면 다시 출석 · 광고 보상을 받을 수 있게 한다
                refreshDailyRewards(&state)

                return .none

            case .backButtonTapped:
                return .run { _ in await dismiss() }

            case let .pacerTapped(pacer):
                if state.wallet.isUnlocked(pacer) {
                    state.$selectedPacer.withLock { $0 = pacer }

                    return .none
                }

                let points = state.wallet.points
                guard points >= pacer.price else {
                    return showToast(&state, .notEnoughPoints(pacer.price - points))
                }

                state.alert = .unlockConfirm(pacer, points: points)

                return .none

            case let .alert(.presented(.unlockConfirmed(pacer))):
                var didUnlock = false
                state.$wallet.withLock { didUnlock = $0.unlock(pacer) }
                guard didUnlock else { return .none }

                state.$selectedPacer.withLock { $0 = pacer }

                return .none

            case .attendanceButtonTapped:
                var didAttend = false
                state.$wallet.withLock { didAttend = $0.attend(at: now) }
                state.canAttend = false
                guard didAttend else { return .none }

                return showToast(&state, .attendance)

            case .watchAdButtonTapped:
                // 화면을 켜 둔 사이 다른 기기에서 오늘 횟수를 다 썼으면 광고를 띄우지 않는다
                refreshDailyRewards(&state)
                guard state.canWatchAd else { return .none }

                state.isShowingAd = true

                return .run { send in
                    do {
                        let earnedReward = try await adClient.showRewardedAd()
                        await send(.adFinished(earnedReward: earnedReward))
                    } catch {
                        await send(.adUnavailable)
                    }
                }

            case let .adFinished(earnedReward):
                state.isShowingAd = false
                // 끝까지 보지 않고 닫았으면 포인트를 주지 않는다
                guard earnedReward else { return .none }

                // 다른 기기에서 오늘 횟수를 다 썼으면 적립하지 않는다
                var didEarn = false
                state.$wallet.withLock { didEarn = $0.earnAdReward(at: now) }
                state.todayAdRewardCount = state.wallet.todayAdRewardCount(at: now)
                guard didEarn else { return .none }

                return showToast(&state, .adReward)

            case .adUnavailable:
                state.isShowingAd = false
                state.alert = .adUnavailable

                return .none

            case .toastExpired:
                state.toast = nil

                return .none

            case .alert:
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }

    /// 오늘 출석 · 광고 보상을 받을 수 있는지 지금 시각 기준으로 다시 확인한다
    private func refreshDailyRewards(_ state: inout State) {
        state.canAttend = state.wallet.canAttend(at: now)
        state.todayAdRewardCount = state.wallet.todayAdRewardCount(at: now)
    }

    /// 안내 토스트를 잠시 띄운다 (이미 떠 있으면 새 문구로 바꾸고 시간을 다시 잰다)
    private func showToast(_ state: inout State, _ toast: PacerToast) -> Effect<Action> {
        state.toast = toast

        return .run { send in
            try await clock.sleep(for: .seconds(2))
            await send(.toastExpired)
        }
        .cancellable(id: CancelID.toast, cancelInFlight: true)
    }
}

/// 페이서 화면 하단에 잠시 띄우는 안내
enum PacerToast: Equatable {
    case adReward
    case attendance
    case notEnoughPoints(Int)
}

extension AlertState where Action == PacerFeature.Action.Alert {
    /// 잠긴 페이서를 포인트로 해제할지 묻는다
    static func unlockConfirm(_ pacer: PipPacer, points: Int) -> Self {
        return AlertState {
            TextState(pacer.nameKey)
        } actions: {
            ButtonState(role: .cancel) {
                TextState("cancel")
            }
            ButtonState(action: .unlockConfirmed(pacer)) {
                TextState("pacerUnlock")
            }
        } message: {
            TextState("pacerUnlockConfirmMessage \(pacer.price) \(points) \(points - pacer.price)")
        }
    }

    static let adUnavailable = AlertState {
        TextState("pacerAdUnavailableTitle")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("ok")
        }
    } message: {
        TextState("pacerAdUnavailableMessage")
    }
}
