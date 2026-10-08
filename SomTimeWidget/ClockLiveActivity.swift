//
//  ClockLiveActivity.swift
//  SomTimeWidget
//

import ActivityKit
import SwiftUI
import WidgetKit

/// 다이나믹 아일랜드와 잠금 화면에 표시되는 시계 Live Activity
struct ClockLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ClockActivityAttributes.self) { context in
            LockScreenClockView(attributes: context.attributes, state: context.state)
                .activityBackgroundTint(Color(.background))
                .activitySystemActionForegroundColor(Color(.textPrimary))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        IslandClockIcon(settings: context.state.settings)
                        Text("liveActivityAppName")
                            .fontStyle(.detail)
                            .foregroundStyle(Color(.textSecondary))
                    }
                    .padding(.leading, 6)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedClockView(attributes: context.attributes, state: context.state)
                }
            } compactLeading: {
                IslandCompactLeading(state: context.state)
            } compactTrailing: {
                IslandCompactClock(state: context.state)
            } minimal: {
                IslandMinimalClock(state: context.state)
            }
            .keylineTint(context.state.settings.color.color)
        }
    }
}

/// Expanded 하단: 큰 시간 44pt + 날짜 · 자동 종료까지 남은 시간
private struct ExpandedClockView: View {
    let attributes: ClockActivityAttributes
    let state: ClockActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LiveClockText(state: state, placement: .expanded, alignment: .leading)
            HStack {
                LiveDateText()
                Spacer(minLength: 8)
                HStack(spacing: 4) {
                    Text("liveActivityAutoEnd")
                    Text(attributes.autoEndDate, style: .relative)
                }
            }
            .fontStyle(.detail)
            .foregroundStyle(Color(.textSecondary))
            .lineLimit(1)
        }
        .padding(.horizontal, 6)
    }
}

/// 잠금 화면 · StandBy: 앱 이름 + 시간 30pt / 오른쪽에 자동 종료까지 남은 시간
private struct LockScreenClockView: View {
    let attributes: ClockActivityAttributes
    let state: ClockActivityAttributes.ContentState

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("liveActivityAppName")
                    .fontStyle(.detail)
                    .foregroundStyle(Color(.textSecondary))
                LiveClockText(state: state, placement: .lockScreen, alignment: .leading)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 2) {
                Text("liveActivityAutoEnd")
                Text(attributes.autoEndDate, style: .relative)
                    .multilineTextAlignment(.trailing)
            }
            .fontStyle(.caption)
            .foregroundStyle(Color(.textSecondary))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

/// 오늘 날짜 (예: 10월 8일 목요일). 자정이 지나면 시스템이 갱신한다
private struct LiveDateText: View {
    var body: some View {
        Text(.currentDate, format: Self.style)
    }

    private static var style: Date.FormatStyle {
        return .dateTime.month(.wide).day().weekday(.wide)
    }
}

#Preview("Lock Screen", as: .content, using: ClockActivityAttributes.preview) {
    ClockLiveActivity()
} contentStates: {
    ClockActivityAttributes.ContentState.preview
}

#Preview("Compact", as: .dynamicIsland(.compact), using: ClockActivityAttributes.preview) {
    ClockLiveActivity()
} contentStates: {
    ClockActivityAttributes.ContentState.preview
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: ClockActivityAttributes.preview) {
    ClockLiveActivity()
} contentStates: {
    ClockActivityAttributes.ContentState.preview
}

#Preview("Minimal", as: .dynamicIsland(.minimal), using: ClockActivityAttributes.preview) {
    ClockLiveActivity()
} contentStates: {
    ClockActivityAttributes.ContentState.preview
}

private extension ClockActivityAttributes {
    static var preview: ClockActivityAttributes {
        return ClockActivityAttributes(startedAt: .now)
    }
}

private extension ClockActivityAttributes.ContentState {
    static var preview: Self {
        return Self(
            settings: ClockDisplaySettings(design: .classic, color: .amber, isTwentyFourHour: true, showsSeconds: true)
        )
    }
}
