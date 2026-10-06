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
        ActivityConfiguration(for: ClockActivityAttributes.self) { _ in
            // TODO: 잠금 화면 시계 UI
            Image(systemName: "clock")
        } dynamicIsland: { _ in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    // TODO: Expanded 시계 UI
                    Image(systemName: "clock")
                }
            } compactLeading: {
                Image(systemName: "clock")
            } compactTrailing: {
                // TODO: Compact 시계 텍스트
                EmptyView()
            } minimal: {
                Image(systemName: "clock")
            }
        }
    }
}
