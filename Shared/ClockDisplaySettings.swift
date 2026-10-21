//
//  ClockDisplaySettings.swift
//  SomTime
//

import Foundation

/// 시계를 그릴 때 필요한 설정 묶음 (설정 화면 값 → Live Activity, PiP에 전달)
nonisolated struct ClockDisplaySettings: Codable, Hashable {
    var design: ClockDesign
    var color: ClockColor
    var isTwentyFourHour: Bool
    var showsSeconds: Bool
    /// 12시간제에서 오전/오후(AM/PM) 표시 여부
    var showsDayPeriod: Bool
    /// 서버 시간 시계면 측정한 오프셋 (일반 시계는 nil)
    var serverTime: ServerTimeClock?

    private enum CodingKeys: String, CodingKey {
        case design
        case color
        case isTwentyFourHour
        case showsSeconds
        case showsDayPeriod
        case serverTime
    }
}

nonisolated extension ClockDisplaySettings {
    /// 저장된 상태를 읽는다. 이전 버전에서 시작한 Live Activity 상태에는 showsDayPeriod가 없으므로 기본값으로 채운다
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        design = try container.decode(ClockDesign.self, forKey: .design)
        color = try container.decode(ClockColor.self, forKey: .color)
        isTwentyFourHour = try container.decode(Bool.self, forKey: .isTwentyFourHour)
        showsSeconds = try container.decode(Bool.self, forKey: .showsSeconds)
        showsDayPeriod = try container.decodeIfPresent(Bool.self, forKey: .showsDayPeriod)
            ?? ClockSettingsStorage.DefaultValue.showsDayPeriod
        serverTime = try container.decodeIfPresent(ServerTimeClock.self, forKey: .serverTime)
    }
}

nonisolated extension ClockDisplaySettings {
    /// 시스템이 갱신하는 현재 시각 Text에 쓸 시간대.
    /// 서버 시간이면 기기 시간대를 오프셋만큼 옮긴 고정 시간대를 쓴다 (시간대는 초 단위라 오프셋을 반올림한다)
    var timeZone: TimeZone {
        guard let serverTime else { return .autoupdatingCurrent }

        let secondsFromGMT = TimeZone.autoupdatingCurrent.secondsFromGMT() + Int(serverTime.offset.rounded())

        return TimeZone(secondsFromGMT: secondsFromGMT) ?? .autoupdatingCurrent
    }

    /// 지금 시계에 표시할 시각 (서버 시간이면 오프셋을 밀리초까지 정확히 더한다)
    func clockDate(from date: Date = Date()) -> Date {
        return date.addingTimeInterval(serverTime?.offset ?? 0)
    }

    /// 서버 시계가 목표 시각이 되는 순간의 폰 시각 (시스템이 갱신하는 타이머 Text에 쓴다. 목표 시각이 없으면 nil)
    var targetPhoneDate: Date? {
        guard let serverTime, let targetDate = serverTime.targetDate else { return nil }

        return targetDate.addingTimeInterval(-serverTime.offset)
    }

    /// 아일랜드 시계를 24시간제로 그릴지 여부.
    /// 서버 시간은 오프셋의 소수까지 맞추는 스톱워치 방식이 24시간 형식만 돼서, 설정과 상관없이 항상 24시간제로 맞춘다
    var islandIsTwentyFourHour: Bool {
        return serverTime != nil || isTwentyFourHour
    }

    /// 아일랜드에서 서버 시간을 스톱워치(서버 자정부터 흐른 시간)로 그릴 때 기준이 되는 폰 시각.
    /// 시간대 방식은 오프셋을 초 단위로 반올림해 최대 0.5초 어긋나지만, 스톱워치는 기준 시각의 소수까지 따라가 서버의 초와 정확히 맞는다.
    /// 스톱워치는 자정을 넘기면 24:00:05처럼 이어서 세므로, 아래 경우에는 nil을 돌려 시간대 방식으로 그리게 한다
    /// - 초를 숨길 때 (스톱워치는 시:분:초 형식만 된다)
    /// - 서버 자정까지 1시간이 안 남았거나, 목표 시각이 서버 자정 뒤일 때
    /// - 서머타임이 바뀌는 날 (자정부터 흐른 시간이 시각과 달라진다)
    func serverStopwatchStart(at date: Date = Date(), calendar: Calendar = .current) -> Date? {
        guard let serverTime, showsSeconds else { return nil }

        let serverNow = date.addingTimeInterval(serverTime.offset)
        let serverMidnight = calendar.startOfDay(for: serverNow)
        guard let nextMidnight = calendar.date(byAdding: .day, value: 1, to: serverMidnight),
              nextMidnight.timeIntervalSince(serverNow) > Self.stopwatchMidnightMargin else { return nil }
        if let targetDate = serverTime.targetDate, targetDate >= nextMidnight {
            return nil
        }
        if let transition = calendar.timeZone.nextDaylightSavingTimeTransition(after: serverMidnight), transition < nextMidnight {
            return nil
        }

        return serverMidnight.addingTimeInterval(-serverTime.offset)
    }

    /// 서버 자정 몇 초 전부터는 스톱워치 대신 시간대 방식으로 그릴지 (00시 티켓팅에 24:00이 보이지 않도록)
    private static let stopwatchMidnightMargin: TimeInterval = 60 * 60
}
