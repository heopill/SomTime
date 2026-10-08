//
//  LiveActivityClient.swift
//  SomTime
//

import ActivityKit
import ComposableArchitecture
import Foundation
import OSLog

/// 다이나믹 아일랜드 시계 Live Activity를 시작 · 업데이트 · 종료한다
@DependencyClient
nonisolated struct LiveActivityClient {
    /// 실행 중인 시계 Live Activity의 시작 시각 (없으면 nil)
    var runningStartDate: @Sendable () async -> Date? = { nil }
    /// 새 Live Activity를 시작하고 시작 시각을 돌려준다 (이미 있으면 정리 후 새로 시작)
    var start: @Sendable (_ state: ClockActivityAttributes.ContentState) async throws -> Date
    /// 실행 중인 Live Activity의 표시 상태를 바꾼다
    var update: @Sendable (_ state: ClockActivityAttributes.ContentState) async -> Void
    /// 실행 중인 Live Activity를 바로 종료한다
    var end: @Sendable () async -> Void
    /// 실행 중인 Live Activity가 시스템(8시간 경과)이나 사용자에 의해 끝나면 한 번 알린다
    var ended: @Sendable () async -> Void
}

nonisolated enum LiveActivityError: Error {
    /// 설정에서 섬타임의 실시간 현황(Live Activities)이 꺼져 있음
    case disabled
}

extension LiveActivityClient: DependencyKey {
    nonisolated static let liveValue = LiveActivityClient(
        runningStartDate: {
            return runningActivities().first?.attributes.startedAt
        },
        start: { state in
            guard ActivityAuthorizationInfo().areActivitiesEnabled else {
                logger.error("start: Live Activities are disabled in Settings")
                throw LiveActivityError.disabled
            }

            for activity in Activity<ClockActivityAttributes>.activities {
                logger.notice("start: ending previous activity \(activity.id, privacy: .public)")
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            do {
                let activity = try Activity.request(
                    attributes: ClockActivityAttributes(startedAt: Date()),
                    content: ActivityContent(state: state, staleDate: state.staleDate),
                    pushType: nil
                )
                logger.notice("start: requested \(activity.id, privacy: .public), state \(String(describing: activity.activityState), privacy: .public)")

                return activity.attributes.startedAt
            } catch {
                logger.error("start: request failed \(String(describing: error), privacy: .public)")
                throw error
            }
        },
        update: { state in
            for activity in runningActivities() {
                await activity.update(ActivityContent(state: state, staleDate: state.staleDate))
            }
        },
        end: {
            for activity in Activity<ClockActivityAttributes>.activities {
                logger.notice("end: ending \(activity.id, privacy: .public)")
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        },
        ended: {
            guard let activity = runningActivities().first else {
                logger.notice("ended: no running activity")
                return
            }

            for await activityState in activity.activityStateUpdates {
                logger.notice("ended: \(activity.id, privacy: .public) changed to \(String(describing: activityState), privacy: .public)")
                if isFinished(activityState) {
                    return
                }
            }

            // 상태 스트림이 끝 상태 없이 닫힌 경우: 실제로 끝났을 때만 알리고, 아니면 취소될 때까지 기다린다
            while !Task.isCancelled {
                if isFinished(activity.activityState) {
                    logger.notice("ended: \(activity.id, privacy: .public) finished after stream closed")
                    return
                }
                try? await Task.sleep(for: .seconds(30))
            }
        }
    )

    nonisolated static let testValue = LiveActivityClient()

    private nonisolated static let logger = Logger(subsystem: "dev.seongpil.SomTime", category: "LiveActivity")

    /// 아직 끝나지 않은 시계 Live Activity 목록 (iOS 26+의 pending 포함)
    private nonisolated static func runningActivities() -> [Activity<ClockActivityAttributes>] {
        return Activity<ClockActivityAttributes>.activities.filter { !isFinished($0.activityState) }
    }

    /// 종료(ended) 또는 화면에서 사라진(dismissed) 상태인지 여부
    private nonisolated static func isFinished(_ state: ActivityState) -> Bool {
        return state == .ended || state == .dismissed
    }
}

extension DependencyValues {
    nonisolated var liveActivityClient: LiveActivityClient {
        get { self[LiveActivityClient.self] }
        set { self[LiveActivityClient.self] = newValue }
    }
}
