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
        /// 인터넷 시각 - 기기 시각 (초). 출석 · 광고 보상을 받을 때 확인하고, 앱을 떠났다 돌아오면 지운다 (그 사이 기기 시간을 바꿨을 수 있다)
        var internetTimeOffset: TimeInterval?
        /// 출석 보상을 받기 전에 인터넷 시각을 확인하는 중인지 여부 (버튼을 여러 번 누르지 않도록)
        var isCheckingAttendance = false
        /// 보상형 광고를 띄우는 중인지 여부 (인터넷 시각 확인부터 광고를 닫을 때까지. 버튼을 여러 번 누르지 않도록)
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
        case attendanceTimeChecked(offset: TimeInterval?)
        case watchAdButtonTapped
        case adTimeChecked(offset: TimeInterval?)
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
    @Dependency(\.serverTimeClient) var serverTimeClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                refreshDailyRewards(&state)

                // 광고 버튼을 누르자마자 띄울 수 있도록 미리 불러온다
                return .run { _ in await adClient.loadRewardedAd() }

            case .appBecameActive:
                // 앱을 떠난 사이 기기 시간을 바꿨을 수 있으므로 확인한 인터넷 시각을 버린다 (광고를 보는 중이면 보상에 써야 하므로 남긴다)
                if !state.isShowingAd {
                    state.internetTimeOffset = nil
                }
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
                guard state.canAttend, !state.isCheckingAttendance else { return .none }

                // 기기 시간을 앞당겨 다음 날 출석을 미리 받지 않도록 인터넷 시각으로 판정한다
                state.isCheckingAttendance = true

                return checkInternetTime { .attendanceTimeChecked(offset: $0) }

            case let .attendanceTimeChecked(offset):
                state.isCheckingAttendance = false
                guard let offset else {
                    state.alert = .internetTimeUnavailable

                    return .none
                }

                state.internetTimeOffset = offset
                let date = rewardNow(state)
                var didAttend = false
                state.$wallet.withLock { didAttend = $0.attend(at: date) }
                refreshDailyRewards(&state)
                guard didAttend else { return .none }

                return showToast(&state, .attendance)

            case .watchAdButtonTapped:
                // 화면을 켜 둔 사이 다른 기기에서 오늘 횟수를 다 썼으면 광고를 띄우지 않는다
                refreshDailyRewards(&state)
                guard state.canWatchAd else { return .none }

                // 기기 시간을 앞당겨 하루 횟수를 초기화하지 않도록 인터넷 시각으로 오늘 횟수를 다시 확인한다
                state.isShowingAd = true

                return checkInternetTime { .adTimeChecked(offset: $0) }

            case let .adTimeChecked(offset):
                guard let offset else {
                    state.isShowingAd = false
                    state.alert = .internetTimeUnavailable

                    return .none
                }

                state.internetTimeOffset = offset
                refreshDailyRewards(&state)
                guard state.hasAdRewardsLeft else {
                    state.isShowingAd = false

                    return .none
                }

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
                let date = rewardNow(state)
                var didEarn = false
                state.$wallet.withLock { didEarn = $0.earnAdReward(at: date) }
                refreshDailyRewards(&state)
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
        let date = rewardNow(state)
        state.canAttend = state.wallet.canAttend(at: date)
        state.todayAdRewardCount = state.wallet.todayAdRewardCount(at: date)
    }

    /// 보상 판정에 쓸 지금 시각 (확인한 인터넷 시각이 있으면 그 기준, 없으면 기기 시각)
    private func rewardNow(_ state: State) -> Date {
        guard let offset = state.internetTimeOffset else { return now }

        return now.addingTimeInterval(offset)
    }

    /// 인터넷 시각을 확인해 결과(인터넷 시각 - 기기 시각, 확인하지 못하면 nil)를 보낸다
    private func checkInternetTime(_ action: @escaping @Sendable (TimeInterval?) -> Action) -> Effect<Action> {
        return .run { send in
            let offset = try? await serverTimeClient.internetTimeOffset()
            await send(action(offset))
        }
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

    static let internetTimeUnavailable = AlertState {
        TextState("pacerInternetTimeUnavailableTitle")
    } actions: {
        ButtonState(role: .cancel) {
            TextState("ok")
        }
    } message: {
        TextState("pacerInternetTimeUnavailableMessage")
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
