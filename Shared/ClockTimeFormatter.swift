//
//  ClockTimeFormatter.swift
//  SomTime
//

import Foundation

/// 시계에 표시할 시각 문자열을 만든다
nonisolated enum ClockTimeFormatter {
    /// 설정한 시간 형식과 초 표시 여부에 맞는 시각 문자열을 만든다 (예: 14:05:32, 오후 2:05:32, 2:05:32 PM)
    static func string(
        from date: Date,
        isTwentyFourHour: Bool = true,
        showsSeconds: Bool = true,
        design: ClockDesign = .classic,
        locale: Locale = .autoupdatingCurrent
    ) -> String {
        return date.formatted(formatStyle(isTwentyFourHour: isTwentyFourHour, showsSeconds: showsSeconds, design: design, locale: locale))
    }

    /// 시간 형식과 초 표시 여부에 맞는 FormatStyle을 만든다 (Live Activity의 시스템 갱신 Text에도 사용).
    /// 한글 글자가 없는 디자인(모노, 도트)의 12시간제는 "오후" 대신 영문 AM/PM으로 표시한다 (예: 2:05:32 PM)
    static func formatStyle(
        isTwentyFourHour: Bool,
        showsSeconds: Bool,
        design: ClockDesign = .classic,
        locale: Locale = .autoupdatingCurrent
    ) -> Date.FormatStyle {
        let usesLatinDayPeriod = !isTwentyFourHour && !design.supportsHangul
        let baseLocale = usesLatinDayPeriod ? Locale(identifier: "en_US_POSIX") : locale
        var style = Date.FormatStyle(locale: hourCycleLocale(isTwentyFourHour: isTwentyFourHour, locale: baseLocale), timeZone: .autoupdatingCurrent)
            .hour(isTwentyFourHour ? .twoDigits(amPM: .omitted) : .defaultDigits(amPM: .abbreviated))
            .minute(.twoDigits)
        if showsSeconds {
            style = style.second(.twoDigits)
        }

        return style
    }

    /// 시 · 분 · 초 중 하나만 표시하는 FormatStyle을 만든다 (가로 모드, Minimal의 세로 쌓기용)
    static func componentStyle(_ component: Component, isTwentyFourHour: Bool, locale: Locale = .autoupdatingCurrent) -> Date.FormatStyle {
        let base = Date.FormatStyle(locale: hourCycleLocale(isTwentyFourHour: isTwentyFourHour, locale: locale), timeZone: .autoupdatingCurrent)

        switch component {
        case .hour: return base.hour(isTwentyFourHour ? .twoDigits(amPM: .omitted) : .defaultDigits(amPM: .omitted))
        case .minute: return base.minute(.twoDigits)
        case .second: return base.second(.twoDigits)
        }
    }

    enum Component {
        case hour
        case minute
        case second
    }

    /// 기기 언어는 유지하고 12 / 24시간제만 바꾼 Locale을 만든다
    private static func hourCycleLocale(isTwentyFourHour: Bool, locale: Locale) -> Locale {
        var components = Locale.Components(locale: locale)
        components.hourCycle = isTwentyFourHour ? .zeroToTwentyThree : .oneToTwelve

        return Locale(components: components)
    }
}
