//
//  ClockTimeFormatter.swift
//  SomTime
//

import Foundation

/// 시계에 표시할 시각 문자열을 만든다.
/// 기기 설정(24시간제 스위치, 지역 형식)에 휘둘리지 않도록 형식을 직접 지정한다 (VerbatimFormatStyle)
nonisolated enum ClockTimeFormatter {
    /// 설정한 시간 형식과 초 표시 여부에 맞는 시각 문자열을 만든다 (예: 20:05:32, 오후 8:05:32, 8:05:32 PM)
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
    /// 한글 글자가 없는 디자인(모노, 도트)의 12시간제는 "오후" 대신 영문 AM/PM으로 표시한다 (예: 8:05:32 PM)
    static func formatStyle(
        isTwentyFourHour: Bool,
        showsSeconds: Bool,
        design: ClockDesign = .classic,
        locale: Locale = .autoupdatingCurrent
    ) -> Date.VerbatimFormatStyle {
        guard !isTwentyFourHour else {
            let format: Date.FormatString = showsSeconds
                ? "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits):\(second: .twoDigits)"
                : "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased)):\(minute: .twoDigits)"

            return verbatimStyle(format, locale: locale)
        }

        let dayPeriodLocale = design.supportsHangul ? locale : Locale(identifier: "en_US_POSIX")
        let format: Date.FormatString
        switch (showsSeconds, placesDayPeriodFirst(dayPeriodLocale)) {
        case (true, true):
            format = "\(dayPeriod: .standard(.abbreviated)) \(hour: .defaultDigits(clock: .twelveHour, hourCycle: .oneBased)):\(minute: .twoDigits):\(second: .twoDigits)"
        case (true, false):
            format = "\(hour: .defaultDigits(clock: .twelveHour, hourCycle: .oneBased)):\(minute: .twoDigits):\(second: .twoDigits) \(dayPeriod: .standard(.abbreviated))"
        case (false, true):
            format = "\(dayPeriod: .standard(.abbreviated)) \(hour: .defaultDigits(clock: .twelveHour, hourCycle: .oneBased)):\(minute: .twoDigits)"
        case (false, false):
            format = "\(hour: .defaultDigits(clock: .twelveHour, hourCycle: .oneBased)):\(minute: .twoDigits) \(dayPeriod: .standard(.abbreviated))"
        }

        return verbatimStyle(format, locale: dayPeriodLocale)
    }

    /// 시 · 분 · 초 중 하나만 숫자로 표시하는 FormatStyle을 만든다 (가로 모드, Minimal의 세로 쌓기용. "시" 같은 접미사 없음)
    static func componentStyle(_ component: Component, isTwentyFourHour: Bool, locale: Locale = .autoupdatingCurrent) -> Date.VerbatimFormatStyle {
        let format: Date.FormatString
        switch component {
        case .hour:
            format = isTwentyFourHour
                ? "\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased))"
                : "\(hour: .defaultDigits(clock: .twelveHour, hourCycle: .oneBased))"
        case .minute:
            format = "\(minute: .twoDigits)"
        case .second:
            format = "\(second: .twoDigits)"
        }

        return verbatimStyle(format, locale: locale)
    }

    enum Component {
        case hour
        case minute
        case second
    }

    /// 지정한 형식 그대로 그리는 FormatStyle을 만든다 (그레고리력, 기기 시간대)
    private static func verbatimStyle(_ format: Date.FormatString, locale: Locale) -> Date.VerbatimFormatStyle {
        return Date.VerbatimFormatStyle(
            format: format,
            locale: locale,
            timeZone: .autoupdatingCurrent,
            calendar: Calendar(identifier: .gregorian)
        )
    }

    /// 오전/오후를 시각 앞에 쓰는 언어인지 여부 (한국어 · 일본어 · 중국어: "오후 8:05", 그 외: "8:05 PM")
    private static func placesDayPeriodFirst(_ locale: Locale) -> Bool {
        guard let languageCode = locale.language.languageCode else { return false }

        return [.korean, .japanese, .chinese].contains(languageCode)
    }
}
