//
//  ClockActivityAttributes.swift
//  SomTime
//

import ActivityKit
import Foundation

/// 다이나믹 아일랜드 시계 Live Activity의 속성 (앱과 위젯 확장에서 공유)
nonisolated struct ClockActivityAttributes: ActivityAttributes {
    /// 시스템이 Live Activity를 자동 종료하기까지의 시간 (약 8시간)
    static let autoEndInterval: TimeInterval = 8 * 60 * 60

    struct ContentState: Codable, Hashable {
        var settings: ClockDisplaySettings
    }

    var startedAt: Date

    var autoEndDate: Date {
        return startedAt.addingTimeInterval(Self.autoEndInterval)
    }
}
