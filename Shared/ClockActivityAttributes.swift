//
//  ClockActivityAttributes.swift
//  SomTime
//

import ActivityKit
import Foundation

/// 다이나믹 아일랜드 시계 Live Activity의 속성 (앱과 위젯 확장에서 공유)
nonisolated struct ClockActivityAttributes: ActivityAttributes {
    /// 시스템이 Live Activity를 자동 종료하기까지의 시간 (약 8시간)
    static let autoEndInterval: TimeInterval = 8 * 60 * 60

    struct ContentState: Codable, Hashable {
        var settings: ClockDisplaySettings
        // iOS 17의 Text(timerInterval:)이 경과 시간을 셀 기준 자정 (앱이 업데이트할 때마다 갱신)
        var referenceMidnight: Date
        // 폰 시각 대비 서버 시각 차이 (초). 서버 시간 이슈에서 사용
        var serverTimeOffset: TimeInterval = 0
    }

    var startedAt: Date

    var autoEndDate: Date {
        return startedAt.addingTimeInterval(Self.autoEndInterval)
    }
}

nonisolated extension ClockActivityAttributes.ContentState {
    /// 시스템이 갱신하는 현재 시각 Text(iOS 18+)를 쓸 수 있는지 여부 (서버 시간 오프셋이 있으면 타이머 방식 사용)
    var usesSystemCurrentDate: Bool {
        guard #available(iOS 18.0, *) else { return false }

        return serverTimeOffset == 0
    }

    /// iOS 17 타이머 방식에서 경과 시간을 셀 범위 (기준 자정 - 서버 오프셋부터 이틀)
    var timerRange: ClosedRange<Date> {
        let start = referenceMidnight.addingTimeInterval(-serverTimeOffset)

        return start...start.addingTimeInterval(2 * 24 * 60 * 60)
    }

    /// 기준 자정의 다음 자정
    var nextMidnight: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: referenceMidnight)
            ?? referenceMidnight.addingTimeInterval(24 * 60 * 60)
    }

    /// Live Activity의 staleDate. 앱이 백그라운드에 있어도 이 시각(다음 자정)에 시스템이 stale 상태로 바꾸고 화면을 다시 그린다
    var staleDate: Date {
        return nextMidnight.addingTimeInterval(-serverTimeOffset)
    }

    /// 화면에 그릴 상태를 만든다. stale이면(자정이 지났으면) 기준 자정을 다음 날로 옮겨 iOS 17 타이머가 00:00부터 다시 세게 한다
    /// (Live Activity는 최대 12시간이라 자정은 한 번만 넘는다)
    func resolved(isStale: Bool) -> Self {
        guard isStale else { return self }

        var state = self
        state.referenceMidnight = nextMidnight

        return state
    }
}
