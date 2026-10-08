//
//  HomeView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

struct HomeView: View {
    @Bindable var store: StoreOf<HomeFeature>

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
            .background(Color(.background))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(
                item: $store.scope(state: \.destination?.settings, action: \.destination.settings)
            ) { settingsStore in
                SettingsView(store: settingsStore)
            }
            .navigationDestination(
                item: $store.scope(state: \.destination?.serverTime, action: \.destination.serverTime)
            ) { serverTimeStore in
                ServerTimeView(store: serverTimeStore)
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
    }

    /// 홈 화면 본문 (헤더, 미리보기, 기능 카드, 설정 요약)
    private func content(now: Date) -> some View {
        VStack(spacing: Spacing.section) {
            header
            HomePreviewArea(
                time: ClockTimeFormatter.string(
                    from: now,
                    isTwentyFourHour: store.isTwentyFourHour,
                    showsSeconds: store.showsSeconds,
                    design: store.clockDesign
                ),
                design: store.clockDesign,
                isIslandOn: store.isIslandOn,
                isPipOn: store.isPipOn
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
                MenuRow(systemImage: "globe", title: "serverTime", subtitle: "serverTimeSubtitle") {
                    store.send(.serverTimeRowTapped)
                }
            }
            Spacer(minLength: 0)
            SettingsSummaryRow(design: store.clockDesign, color: store.clockColor) {
                store.send(.settingsButtonTapped)
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var header: some View {
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
            IconButton(systemImage: "gearshape", accessibilityLabel: "settings") {
                store.send(.settingsButtonTapped)
            }
        }
    }

    /// 다이나믹 아일랜드 카드의 상태 문구를 만든다 (켜짐이면 자동 종료까지 남은 시간 포함)
    private func islandStatus(now: Date) -> LocalizedStringKey {
        guard store.isIslandOn, let startedAt = store.islandStartedAt else {
            // 다이나믹 아일랜드가 없는 기기는 Live Activity가 잠금 화면에만 표시된다
            return DeviceCapability.hasDynamicIsland ? "dynamicIslandClockOffStatus" : "dynamicIslandClockLockScreenOnlyStatus"
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
