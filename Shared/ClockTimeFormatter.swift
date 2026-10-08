//
//  ClockTimeFormatter.swift
//  SomTime
//

import Foundation

/// 시계에 표시할 시각 문자열을 만든다
enum ClockTimeFormatter {
    private static let twentyFourHourStyle = Date.VerbatimFormatStyle(
        format: "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits)",
        timeZone: .current,
        calendar: .current
    )

    /// 24시간제 시:분:초 문자열을 만든다 (예: 14:05:32)
    static func string(from date: Date) -> String {
        return date.formatted(twentyFourHourStyle)
    }
}
