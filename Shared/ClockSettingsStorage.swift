//
//  ClockSettingsStorage.swift
//  SomTime
//

import Foundation

/// 시계 설정을 저장하는 App Group UserDefaults와 키 (앱과 위젯 확장이 함께 사용)
nonisolated enum ClockSettingsStorage {
    static let appGroupIdentifier = "group.dev.seongpil.SomTime"
    static let userDefaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard

    enum Key {
        static let clockDesign = "clockDesign"
        static let clockColor = "clockColor"
        static let isTwentyFourHour = "isTwentyFourHour"
        static let showsSeconds = "showsSeconds"
        static let pipAspectRatio = "pipAspectRatio"
    }

    enum DefaultValue {
        static let clockDesign: ClockDesign = .classic
        static let clockColor: ClockColor = .amber
        static let isTwentyFourHour = true
        static let showsSeconds = true
        static let pipAspectRatio: PipAspectRatio = .bar
    }
}
