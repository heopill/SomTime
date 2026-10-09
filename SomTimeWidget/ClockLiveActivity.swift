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
                    ExpandedLeadingLabel(settings: context.state.settings)
                        .fontStyle(.detail)
                        .foregroundStyle(Color(.textSecondary))
                        .lineLimit(1)
                        .padding(.leading, 6)
                    // 카메라 옆 칸보다 넓으면 카메라 아래로 내려 넓은 자리에 그린다
                    .dynamicIsland(verticalPlacement: .belowIfTooWide)
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

/// Expanded 위쪽 leading 칸: 일반 시계는 날짜, 서버 시간 시계는 "서버 시간"
private struct ExpandedLeadingLabel: View {
    let settings: ClockDisplaySettings

    var body: some View {
        if settings.serverTime != nil {
            Text("liveActivityServerTime")
        } else {
            LiveDateText()
        }
    }
}

/// Expanded 하단: 큰 시간 44pt + 맨 아래 줄.
/// 맨 아래 줄은 일반 시계면 자동 종료까지 남은 시간, 서버 시간이면 왼쪽 날짜 · 오른쪽 사이트 호스트 (위쪽 leading 칸은 좁아서 폭 전체를 쓰는 하단에 둔다)
private struct ExpandedClockView: View {
    let attributes: ClockActivityAttributes
    let state: ClockActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LiveClockText(state: state, placement: .expanded, alignment: .leading)
            Group {
                if let serverTime = state.settings.serverTime {
                    // 시스템이 갱신하는 날짜 Text는 실제보다 넓은 폭을 차지하므로, 주소가 먼저 자기 폭을 갖고 날짜는 남은 폭에 왼쪽 정렬한다
                    HStack(spacing: 8) {
                        LiveDateText()
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        ServerHostLabel(host: serverTime.host)
                            .layoutPriority(1)
                    }
                } else {
                    HStack(spacing: 4) {
                        Spacer(minLength: 0)
                        Text("liveActivityAutoEnd")
                        Text(attributes.autoEndDate, style: .relative)
                    }
                    .lineLimit(1)
                }
            }
            .fontStyle(.detail)
            .foregroundStyle(Color(.textSecondary))
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
                ClockSourceLabel(settings: state.settings)
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

/// 시계 이름: 일반 시계는 앱 이름, 서버 시간 시계는 측정한 사이트 호스트
/// (호스트는 영문이라 위젯의 폰트 서브셋에 한글을 더하지 않아도 된다)
private struct ClockSourceLabel: View {
    let settings: ClockDisplaySettings

    var body: some View {
        if let serverTime = settings.serverTime {
            ServerHostLabel(host: serverTime.host)
        } else {
            Text("liveActivityAppName")
        }
    }
}

/// 사이트 호스트 한 줄. 길면 글자를 줄여 전체를 보여 주고, 그래도 넘치면 가운데를 줄인다 (오른쪽 정렬)
private struct ServerHostLabel: View {
    let host: String

    var body: some View {
        Text(verbatim: host)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .truncationMode(.middle)
            .multilineTextAlignment(.trailing)
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
