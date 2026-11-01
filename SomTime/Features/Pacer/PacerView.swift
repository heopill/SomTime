//
//  PacerView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

struct PacerView: View {
    @Bindable var store: StoreOf<PacerFeature>

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(title: "pipPacer") {
                    store.send(.backButtonTapped)
                }
                preview
                pointsCard
                pacerList
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, Spacing.section)
        }
        .scrollBounceBehavior(.basedOnSize)
        // 포인트 적립 · 부족 안내 토스트 (잠시 후 자동으로 사라짐)
        .overlay(alignment: .bottom) {
            if let toast = store.toast {
                ToastMessage(message: toast.message)
                    .padding(.bottom, 24)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.toast)
        .background(Color(.background))
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.clockAccent, store.clockColor.color)
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.send(.appBecameActive)
            }
        }
    }

    /// 지금 고른 페이서가 달리는 PiP 시계 미리보기
    private var preview: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            PipClockWindow(
                time: ClockTimeFormatter.string(
                    from: context.date,
                    isTwentyFourHour: store.isTwentyFourHour,
                    showsSeconds: store.showsSeconds,
                    showsDayPeriod: store.showsDayPeriod,
                    design: store.clockDesign
                ),
                design: store.clockDesign,
                aspectRatio: .bar,
                pacer: store.selectedPacer
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 96)
        .background(Color(.island), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color(.border), lineWidth: 1)
        }
        .accessibilityHidden(true)
    }

    /// 보유 포인트와 출석 · 광고 버튼
    private var pointsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("pacerPoints")
                .fontStyle(.caption)
                .foregroundStyle(Color(.textSecondary))
            Text("pacerPointsValue \(store.wallet.points)")
                .fontStyle(.screenTitle)
                .foregroundStyle(store.clockColor.color)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: store.wallet.points)
            HStack(spacing: 8) {
                PrimaryButton(
                    title: store.canAttend ? "pacerAttendanceButton \(PacerWallet.attendanceReward)" : "pacerAttendanceDone",
                    style: store.canAttend ? .accent : .neutral
                ) {
                    store.send(.attendanceButtonTapped)
                }
                .disabled(!store.canAttend || store.isCheckingAttendance)
                PrimaryButton(title: watchAdButtonTitle, style: .neutral) {
                    store.send(.watchAdButtonTapped)
                }
                .disabled(!store.canWatchAd)
                // 오늘 횟수를 다 쓴 경우는 출석 완료처럼 흐리게 하지 않는다
                .opacity(store.canWatchAd || !store.hasAdRewardsLeft ? 1 : 0.5)
            }
            .padding(.top, 14)
            Text("pacerDailyResetNotice")
                .fontStyle(.caption)
                .foregroundStyle(Color(.textSecondary))
                .padding(.top, 10)
        }
        .padding(Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    /// 광고 버튼 문구 (오늘 받은 횟수 / 하루 횟수, 다 받았으면 완료)
    private var watchAdButtonTitle: LocalizedStringKey {
        guard store.hasAdRewardsLeft else { return "pacerAdRewardDone" }

        return "pacerWatchAdButton \(PacerWallet.rewardPerAd) \(store.todayAdRewardCount) \(PacerWallet.dailyAdRewardLimit)"
    }

    /// 페이서 목록 (페이서 없음, 기본 페이서, 잠금 페이서 순)
    private var pacerList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("pacerListSection")
                .fontStyle(.sectionTitle)
                .foregroundStyle(Color(.textSecondary))
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                ForEach(Array(PipPacer.allCases.enumerated()), id: \.element) { index, pacer in
                    if index > 0 {
                        rowDivider
                    }
                    PacerRow(
                        pacer: pacer,
                        isSelected: store.selectedPacer == pacer,
                        isUnlocked: store.wallet.isUnlocked(pacer),
                        canAfford: store.wallet.points >= pacer.price
                    ) {
                        store.send(.pacerTapped(pacer))
                    }
                }
            }
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
        }
    }

    /// 목록의 행 구분선 (행 왼쪽 여백부터 카드 오른쪽 끝까지)
    private var rowDivider: some View {
        Rectangle()
            .fill(Color(.divider))
            .frame(height: 1)
            .padding(.leading, Spacing.cardPadding)
    }
}

extension PacerToast {
    var message: LocalizedStringKey {
        switch self {
        case .adReward: return "pacerAdRewardEarned \(PacerWallet.rewardPerAd)"
        case .attendance: return "pacerAttendanceEarned \(PacerWallet.attendanceReward)"
        case let .notEnoughPoints(points): return "pacerNotEnoughPoints \(points)"
        }
    }
}

#Preview {
    PacerView(
        store: Store(initialState: PacerFeature.State()) {
            PacerFeature()
        }
    )
}
