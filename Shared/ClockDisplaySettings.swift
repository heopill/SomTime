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
}
