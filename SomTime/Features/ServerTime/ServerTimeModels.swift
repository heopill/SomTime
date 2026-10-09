//
//  ServerTimeModels.swift
//  SomTime
//

import Foundation

/// 서버 시간 시계를 띄울 곳
nonisolated enum ServerTimeDisplayMode: String, CaseIterable, Codable, Sendable {
    case island
    case pip
}

/// 마지막으로 측정한 서버 시각 (사이트 주소 입력값별로 하나)
nonisolated struct ServerTimeMeasurement: Codable, Equatable, Sendable {
    /// 측정할 때 입력한 주소 (입력창 값이 이와 같을 때만 측정 결과로 보여 준다)
    var input: String
    var host: String
    /// 서버 시각 - 폰 시각 (초)
    var offset: TimeInterval
    /// 오차 범위 (± 초)
    var accuracy: TimeInterval
    var measuredAt: Date
}

/// 실행 중인 서버 시간 시계 (한 번에 하나만. 켜져 있는 동안 홈의 일반 시계 토글은 꺼진다)
nonisolated struct ServerClockSession: Equatable, Sendable {
    var mode: ServerTimeDisplayMode
    var clock: ServerTimeClock
}

/// 사이트 주소 입력값을 측정할 URL로 바꾼다 (scheme이 없으면 https://를 붙인다)
nonisolated enum ServerTimeURL {
    static func url(from input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard let components = URLComponents(string: withScheme),
              let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme),
              let host = components.host, host.contains(".") else { return nil }

        return components.url
    }
}
