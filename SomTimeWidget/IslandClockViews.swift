//
//  IslandClockViews.swift
//  SomTimeWidget
//

import SwiftUI
import WidgetKit

/// 시계 아이콘 (Compact leading, Expanded 앱 이름 옆)
struct IslandClockIcon: View {
    let settings: ClockDisplaySettings

    var body: some View {
        Image(systemName: "clock")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(settings.color.color)
    }
}

/// Compact leading: 세로는 시계 아이콘, iOS 27 가로(폭 제한)는 카메라 위쪽 칸에 "시"
struct IslandCompactLeading: View {
    let state: ClockActivityAttributes.ContentState

    var body: some View {
        if #available(iOS 27.0, *) {
            LandscapeAwareCompactLeading(state: state)
        } else {
            IslandClockIcon(settings: state.settings)
        }
    }
}

/// Compact trailing: 세로는 HH:mm:ss 한 줄, iOS 27 가로(폭 제한)는 카메라 아래쪽 칸에 "분 / 초"
struct IslandCompactClock: View {
    let state: ClockActivityAttributes.ContentState

    var body: some View {
        if #available(iOS 27.0, *) {
            LandscapeAwareCompactTrailing(state: state)
        } else {
            LiveClockText(state: state, placement: .island)
        }
    }
}

// 가로 모드의 위 · 아래 칸은 크기가 정해져 있어 기기마다 들어가는 줄 수가 다르다.
// 두 줄이 들어가면 위 칸에 "시 / 분", 아래 칸에 "초"(초 표시를 끄면 시계 아이콘)를 12 → 11 → 10pt 순서로 맞춰 보고,
// 그래도 안 들어가면 위 칸에 "시", 아래 칸에 "분"을 15pt로 그린다.
// 두 칸이 같은 판단을 하도록 아래 칸도 위 칸과 같은 두 줄 높이로 크기를 잰다 (ViewThatFits)

@available(iOS 27.0, *)
private struct LandscapeAwareCompactLeading: View {
    let state: ClockActivityAttributes.ContentState

    @Environment(\.isDynamicIslandLimitedInWidth) private var isLimitedInWidth

    var body: some View {
        if isLimitedInWidth, state.usesSystemCurrentDate {
            ViewThatFits(in: .vertical) {
                hourAndMinute(size: 12)
                hourAndMinute(size: 11)
                hourAndMinute(size: 10)
                ClockComponentLabel(component: .hour, settings: state.settings, size: FontStyle.ClockPlacement.island.fontSize)
            }
        } else {
            IslandClockIcon(settings: state.settings)
        }
    }

    /// 위 칸의 "시 / 분" 두 줄을 만든다
    private func hourAndMinute(size: CGFloat) -> some View {
        return TwoLineSlot(settings: state.settings, size: size) {
            VStack(spacing: TwoLineSlot<EmptyView>.lineSpacing(for: size)) {
                ClockComponentLabel(component: .hour, settings: state.settings, size: size)
                ClockComponentLabel(component: .minute, settings: state.settings, size: size)
            }
        }
    }
}

@available(iOS 27.0, *)
private struct LandscapeAwareCompactTrailing: View {
    let state: ClockActivityAttributes.ContentState

    @Environment(\.isDynamicIslandLimitedInWidth) private var isLimitedInWidth

    var body: some View {
        if isLimitedInWidth, state.usesSystemCurrentDate {
            ViewThatFits(in: .vertical) {
                secondSlot(size: 12)
                secondSlot(size: 11)
                secondSlot(size: 10)
                ClockComponentLabel(component: .minute, settings: state.settings, size: FontStyle.ClockPlacement.island.fontSize)
            }
        } else {
            LiveClockText(state: state, placement: .island)
        }
    }

    /// 아래 칸의 "초"(초 표시를 끄면 시계 아이콘)를 위 칸 두 줄과 같은 크기의 칸에 만든다
    private func secondSlot(size: CGFloat) -> some View {
        return TwoLineSlot(settings: state.settings, size: size) {
            if state.settings.showsSeconds {
                ClockComponentLabel(component: .second, settings: state.settings, size: size)
            } else {
                IslandClockIcon(settings: state.settings)
            }
        }
    }
}

/// 위 칸의 "시 / 분" 두 줄과 같은 크기를 차지하고, 그 가운데에 내용을 그린다 (위 · 아래 칸이 같은 레이아웃을 고르게 하기 위함)
@available(iOS 18.0, *)
private struct TwoLineSlot<Content: View>: View {
    let settings: ClockDisplaySettings
    let size: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        // overlay는 내용을 기준 크기 안에 가둬 Bold인 "시"가 잘리므로("…"), ZStack으로 겹쳐 높이만 맞춘다
        ZStack {
            VStack(spacing: Self.lineSpacing(for: size)) {
                Text(verbatim: "00")
                Text(verbatim: "00")
            }
            .fontStyle(.clock(settings.design, size: size))
            .hidden()
            content
        }
        .frame(maxWidth: .infinity)
    }

    /// 두 줄 사이 간격. 숫자에는 아래로 내려가는 부분이 없어 줄 높이의 여백을 조금 겹쳐도 된다
    static func lineSpacing(for size: CGFloat) -> CGFloat {
        return -size * 0.2
    }
}

/// Minimal: 시 / 분 두 줄 (iOS 18+). iOS 17은 시계 아이콘
struct IslandMinimalClock: View {
    let state: ClockActivityAttributes.ContentState

    var body: some View {
        if #available(iOS 18.0, *), state.usesSystemCurrentDate {
            VStack(spacing: 0) {
                ClockComponentLabel(component: .hour, settings: state.settings, size: FontStyle.ClockPlacement.minimal.fontSize)
                ClockComponentLabel(component: .minute, settings: state.settings, size: FontStyle.ClockPlacement.minimal.fontSize)
            }
        } else {
            IslandClockIcon(settings: state.settings)
        }
    }
}

/// 시 · 분 · 초 중 하나를 ":" 없이 그린 라벨 (시 Bold 100%, 분 Medium 85%, 초 Medium 50%)
@available(iOS 18.0, *)
private struct ClockComponentLabel: View {
    let component: ClockTimeFormatter.Component
    let settings: ClockDisplaySettings
    let size: CGFloat

    var body: some View {
        LiveClockComponentText(component: component, isTwentyFourHour: settings.isTwentyFourHour)
            .fontStyle(.clock(settings.design, size: size))
            .fontWeight(component == .hour ? .bold : .medium)
            .opacity(opacity)
            .foregroundStyle(settings.color.color)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.center)
            // 칸 안에서 왼쪽으로 치우치지 않도록 칸 폭 전체를 쓰고 가운데 정렬한다
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var opacity: Double {
        switch component {
        case .hour: return 1
        case .minute: return 0.85
        case .second: return 0.5
        }
    }
}
