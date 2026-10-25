//
//  ServerTimeClock.swift
//  SomTime
//

import Foundation

/// 서버 시간 시계 정보 (측정한 사이트와 폰 시각 대비 오프셋). 앱과 위젯 확장이 함께 사용
nonisolated struct ServerTimeClock: Codable, Hashable {
    /// 측정한 사이트 호스트 (예: ticket.example.com)
    var host: String
    /// 서버 시각 - 폰 시각 (초). 양수면 서버가 폰보다 빠르다
    var offset: TimeInterval
    /// 밀리초까지 표시할지 여부 (PiP 전용)
    var showsMilliseconds = false
    /// 목표 시각 (서버 시계 기준. 있으면 남은 시간을 함께 표시한다)
    var targetDate: Date?
    /// 목표 시각 5초 전부터 1초마다 진동할지 여부 (PiP 전용)
    var vibratesBeforeTarget = false

    private enum CodingKeys: String, CodingKey {
        case host
        case offset
        case showsMilliseconds
        case targetDate
        case vibratesBeforeTarget
    }
}

nonisolated extension ServerTimeClock {
    /// 저장된 상태를 읽는다. 이전 버전에서 시작한 Live Activity 상태에는 vibratesBeforeTarget이 없으므로 끈 상태로 채운다
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        host = try container.decode(String.self, forKey: .host)
        offset = try container.decode(TimeInterval.self, forKey: .offset)
        showsMilliseconds = try container.decode(Bool.self, forKey: .showsMilliseconds)
        targetDate = try container.decodeIfPresent(Date.self, forKey: .targetDate)
        vibratesBeforeTarget = try container.decodeIfPresent(Bool.self, forKey: .vibratesBeforeTarget) ?? false
    }
}
