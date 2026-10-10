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
}
