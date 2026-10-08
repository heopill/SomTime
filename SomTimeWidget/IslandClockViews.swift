//
//  IslandClockViews.swift
//  SomTimeWidget
//

import SwiftUI
import WidgetKit

/// Compact leading: 시계 아이콘 16pt
struct IslandClockIcon: View {
    let settings: ClockDisplaySettings

    var body: some View {
        Image(systemName: "clock")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(settings.color.color)
    }
}

/// Compact trailing: 세로는 HH:mm:ss 한 줄, iOS 27 가로(폭 제한)는 시 · 분 · 초 세로 쌓기
struct IslandCompactClock: View {
    let state: ClockActivityAttributes.ContentState

    var body: some View {
        if #available(iOS 27.0, *) {
            LandscapeAwareCompactClock(state: state)
        } else {
            LiveClockText(state: state, placement: .island)
        }
    }
}

@available(iOS 27.0, *)
private struct LandscapeAwareCompactClock: View {
    let state: ClockActivityAttributes.ContentState

    @Environment(\.isDynamicIslandLimitedInWidth) private var isLimitedInWidth

    var body: some View {
        if isLimitedInWidth, state.usesSystemCurrentDate {
            StackedClock(settings: state.settings, placement: .island, spacing: 6, showsSeconds: state.settings.showsSeconds)
        } else {
            LiveClockText(state: state, placement: .island)
        }
    }
}

/// Minimal: 시 / 분 두 줄 (iOS 18+). iOS 17은 시계 아이콘
struct IslandMinimalClock: View {
    let state: ClockActivityAttributes.ContentState

    var body: some View {
        if #available(iOS 18.0, *), state.usesSystemCurrentDate {
            StackedClock(settings: state.settings, placement: .minimal, spacing: 0, showsSeconds: false)
        } else {
            IslandClockIcon(settings: state.settings)
        }
    }
}

/// 시 · 분 · 초를 ":" 없이 세로로 쌓은 시계 (시 Bold 100%, 분 Medium 85%, 초 Medium 50%)
@available(iOS 18.0, *)
private struct StackedClock: View {
    let settings: ClockDisplaySettings
    let placement: FontStyle.ClockPlacement
    let spacing: CGFloat
    let showsSeconds: Bool

    var body: some View {
        VStack(spacing: spacing) {
            LiveClockComponentText(component: .hour, isTwentyFourHour: settings.isTwentyFourHour)
                .fontWeight(.bold)
            LiveClockComponentText(component: .minute, isTwentyFourHour: settings.isTwentyFourHour)
                .fontWeight(.medium)
                .opacity(0.85)
            if showsSeconds {
                LiveClockComponentText(component: .second, isTwentyFourHour: settings.isTwentyFourHour)
                    .fontWeight(.medium)
                    .opacity(0.5)
            }
        }
        .fontStyle(.clock(settings.design, placement: placement))
        .foregroundStyle(settings.color.color)
        .lineLimit(1)
    }
}
