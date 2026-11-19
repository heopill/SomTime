//
//  HomeView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI
import TipKit

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

    @Environment(\.scenePhase) private var scenePhase

    /// 페이서 버튼을 처음 한 번 알려 주는 말풍선
    private let pacerTip = PacerTip()

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                GeometryReader { geometry in
                    ScrollView {
                        content(now: context.date)
                            .frame(minHeight: geometry.size.height)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            // 하단 광고 배너 (매초 다시 그리는 시계 영역 밖에 둔다)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AdBannerSlot(placement: .home)
            }
            .background(Color(.background))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(
                item: $store.scope(state: \.destination?.settings, action: \.destination.settings)
            ) { settingsStore in
                SettingsView(store: settingsStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.pacer, action: \.destination.pacer)
            ) { pacerStore in
                PacerView(store: pacerStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.serverTime, action: \.destination.serverTime)
            ) { serverTimeStore in
                ServerTimeView(store: serverTimeStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.ticketingPractice, action: \.destination.ticketingPractice)
            ) { ticketingPracticeStore in
                TicketingPracticeView(store: ticketingPracticeStore)
            }
        }
        .environment(\.clockAccent, store.clockColor.color)
        .tint(store.clockColor.color)
        .preferredColorScheme(.dark)
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            store.send(.onAppear)
        }
        .onChange(of: store.displaySettings) {
            store.send(.clockSettingsChanged)
        }
        .onChange(of: store.pipAspectRatio) {
            store.send(.pipStyleChanged)
        }
        .onChange(of: store.pipPacer) {
            store.send(.pipStyleChanged)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.send(.appBecameActive)
            }
        }
    }

    /// 홈 화면 본문 (헤더, 미리보기, 기능 카드, 서버 시간 · 티켓팅 연습 타일)
    private func content(now: Date) -> some View {
        VStack(spacing: Spacing.section) {
            header(now: now)
            HomePreviewArea(
                time: ClockTimeFormatter.string(
                    from: now,
                    isTwentyFourHour: store.isTwentyFourHour,
                    showsSeconds: store.showsSeconds,
                    showsDayPeriod: store.showsDayPeriod,
                    design: store.clockDesign
                ),
                design: store.clockDesign,
                isIslandOn: store.isIslandOn,
                isPipOn: store.isPipOn,
                pipAspectRatio: store.pipAspectRatio,
                pipPacer: store.pipPacer
            )
            VStack(spacing: Spacing.card) {
                FeatureCard(
                    systemImage: "capsule",
                    title: "dynamicIslandClock",
                    status: islandStatus(now: now),
                    isOn: $store.isIslandOn.sending(\.islandToggled)
                )
                FeatureCard(
                    systemImage: "pip",
                    title: "pipClock",
                    status: pipStatus,
                    isOn: $store.isPipOn.sending(\.pipToggled)
                )
                HStack(spacing: Spacing.card) {
                    HomeTile(systemImage: "globe", title: "serverTime", subtitle: "serverTimeSubtitle") {
                        store.send(.serverTimeTileTapped)
                    }
                    HomeTile(
                        systemImage: "ticket",
                        title: "ticketingPractice",
                        subtitle: "ticketingPracticeSubtitle",
                        showsNewBadge: !store.hasOpenedTicketingPractice
                    ) {
                        store.send(.ticketingPracticeTileTapped)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    /// 홈 화면 헤더 (제목, 페이서 · 설정 버튼)
    private func header(now: Date) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("homeSubtitle")
                    .fontStyle(.detail)
                    .foregroundStyle(Color(.textSecondary))
                Text("homeTitle")
                    .fontStyle(.homeTitle)
                    .foregroundStyle(Color(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer()
            HStack(spacing: 10) {
                pacerButton(canAttend: store.pacerWallet.canAttend(at: now))
                IconButton(systemImage: "gearshape", accessibilityLabel: "settings") {
                    store.send(.settingsButtonTapped)
                }
            }
        }
    }

    /// 페이서 화면으로 들어가는 버튼. 오늘 출석하지 않았으면 오른쪽 위에 점을 띄우고, 처음 한 번은 안내 말풍선을 띄운다
    private func pacerButton(canAttend: Bool) -> some View {
        IconButton(systemImage: "figure.run", accessibilityLabel: "pipPacer") {
            pacerTip.invalidate(reason: .actionPerformed)
            store.send(.pacerButtonTapped)
        }
        .overlay(alignment: .topTrailing) {
            if canAttend {
                Circle()
                    .fill(store.clockColor.color)
                    .frame(width: 8, height: 8)
                    .padding(2)
                    .background(Color(.background), in: Circle())
                    .allowsHitTesting(false)
            }
        }
        .accessibilityValue(canAttend ? Text("pacerAttendanceAvailable") : Text(verbatim: ""))
        // 알림창이 떠 있거나 다른 화면으로 들어가 있을 때는 말풍선을 미뤄서 겹쳐 뜨지 않게 한다
        .popoverTip(store.alert == nil && store.destination == nil ? pacerTip : nil, arrowEdge: .top)
    }

    /// 다이나믹 아일랜드 카드의 상태 문구를 만든다 (켜짐이면 자동 종료까지 남은 시간, PiP와 함께 켜면 숨김 안내)
    private func islandStatus(now: Date) -> LocalizedStringKey {
        guard store.isIslandOn, let startedAt = store.islandStartedAt else {
            // 다이나믹 아일랜드가 없는 기기는 Live Activity가 잠금 화면에만 표시된다
            return DeviceCapability.hasDynamicIsland ? "dynamicIslandClockOffStatus" : "dynamicIslandClockLockScreenOnlyStatus"
        }
        // PiP 창이 떠 있는 동안에는 시스템이 같은 앱의 Live Activity를 다이나믹 아일랜드에서 숨긴다
        if store.isPipOn, DeviceCapability.hasDynamicIsland {
            return "dynamicIslandClockHiddenByPipStatus"
        }

        let endDate = startedAt.addingTimeInterval(ClockActivityAttributes.autoEndInterval)
        let remainingMinutes = max(0, Int(endDate.timeIntervalSince(now) / 60))

        return "dynamicIslandClockOnStatus \(remainingMinutes / 60) \(remainingMinutes % 60)"
    }

    /// PiP 시계 카드의 상태 문구를 만든다 (미지원 기기, 다이나믹 아일랜드가 없는 기기 안내 포함)
    private var pipStatus: LocalizedStringKey {
        guard DeviceCapability.supportsPictureInPicture else { return "pipClockUnsupportedStatus" }
        guard !store.isPipOn else { return "pipClockOnStatus" }

        // 다이나믹 아일랜드가 없는 기기는 PiP가 영상 위에서 시계를 보는 주 기능이다
        return DeviceCapability.hasDynamicIsland ? "pipClockOffStatus" : "pipClockNoDynamicIslandStatus"
    }
}

#Preview {
    HomeView(
        store: Store(initialState: HomeFeature.State()) {
            HomeFeature()
        }
    )
}
