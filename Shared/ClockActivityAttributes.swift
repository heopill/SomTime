//
//  ClockActivityAttributes.swift
//  SomTime
//

import ActivityKit

/// 다이나믹 아일랜드 시계 Live Activity의 속성 (앱과 위젯 확장에서 공유)
struct ClockActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {}
}
