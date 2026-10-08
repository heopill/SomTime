//
//  ClockTimeFormatter.swift
//  SomTime
//

import Foundation

/// 시계에 표시할 시각 문자열을 만든다
enum ClockTimeFormatter {
    /// 설정한 시간 형식과 초 표시 여부에 맞는 시각 문자열을 만든다 (예: 14:05:32, 오후 2:05:32, 2:05:32 PM)
    static func string(
        from date: Date,
        isTwentyFourHour: Bool = true,
        showsSeconds: Bool = true,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        var components = Locale.Components(locale: locale)
        components.hourCycle = isTwentyFourHour ? .zeroToTwentyThree : .oneToTwelve

        var style = Date.FormatStyle(locale: Locale(components: components), timeZone: .autoupdatingCurrent)
            .hour(isTwentyFourHour ? .twoDigits(amPM: .omitted) : .defaultDigits(amPM: .abbreviated))
            .minute(.twoDigits)
        if showsSeconds {
            style = style.second(.twoDigits)
        }

        return date.formatted(style)
    }
}
