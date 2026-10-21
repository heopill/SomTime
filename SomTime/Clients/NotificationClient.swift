//
//  NotificationClient.swift
//  SomTime
//

import ComposableArchitecture
import Foundation
import OSLog
import UserNotifications

/// 알림 권한을 확인하고, 서버 시간 목표 시각 알림을 예약 · 삭제한다 (로컬 알림)
@DependencyClient
nonisolated struct NotificationClient {
    /// 지금 알림 권한 상태
    var authorizationStatus: @Sendable () async -> NotificationAuthorizationStatus = { .notDetermined }
    /// 알림 권한을 요청하고 허용 여부를 돌려준다 (이미 정해져 있으면 묻지 않고 지금 상태를 돌려준다)
    var requestAuthorization: @Sendable () async -> Bool = { false }
    /// 목표 시각 알림을 예약한다 (이전에 예약한 목표 시각 알림은 지운다)
    var scheduleTargetAlerts: @Sendable (_ alert: ServerTimeTargetAlert) async -> Void
    /// 예약한 목표 시각 알림을 모두 지운다
    var removeTargetAlerts: @Sendable () async -> Void
}

/// 알림 권한 상태
nonisolated enum NotificationAuthorizationStatus: Equatable, Sendable {
    /// 아직 묻지 않음
    case notDetermined
    /// 사용자가 거부함 (설정 앱에서만 켤 수 있다)
    case denied
    /// 허용함 (임시 허용 포함)
    case authorized
}

/// 목표 시각 알림 내용
nonisolated struct ServerTimeTargetAlert: Equatable, Sendable {
    /// 서버 시계가 목표 시각이 되는 순간의 폰 시각
    var fireDate: Date
    /// 알림 문구에 넣을 목표 시각 (예: 오후 8:00)
    var targetText: String
    /// 측정한 사이트 호스트 (알림 제목. 측정 전이면 nil)
    var host: String?
}

extension NotificationClient: DependencyKey {
    nonisolated static let liveValue = NotificationClient(
        authorizationStatus: {
            switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
            case .notDetermined: return .notDetermined
            case .denied: return .denied
            default: return .authorized
            }
        },
        requestAuthorization: {
            do {
                return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            } catch {
                logger.error("authorization request failed \(String(describing: error), privacy: .public)")

                return false
            }
        },
        scheduleTargetAlerts: { alert in
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: targetAlertIdentifiers)

            for minutesBefore in targetAlertMinutesBefore {
                // 이미 지난 알림은 건너뛴다 (목표 시각이 2분 남았으면 1분 전만 예약)
                let interval = alert.fireDate.timeIntervalSinceNow - TimeInterval(minutesBefore * 60)
                guard interval > 0 else { continue }

                let content = UNMutableNotificationContent()
                if let host = alert.host {
                    content.title = host
                }
                content.body = String(localized: "targetAlertBefore \(alert.targetText) \(minutesBefore)")
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: targetAlertIdentifier(minutesBefore: minutesBefore),
                    content: content,
                    trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                )
                do {
                    try await center.add(request)
                } catch {
                    logger.error("schedule \(minutesBefore, privacy: .public)m before failed \(String(describing: error), privacy: .public)")
                }
            }
            logger.notice("scheduled target alerts for \(alert.fireDate, privacy: .public)")
        },
        removeTargetAlerts: {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: targetAlertIdentifiers)
            logger.notice("removed target alerts")
        }
    )

    nonisolated static let testValue = NotificationClient()

    private nonisolated static let logger = Logger(subsystem: "dev.seongpil.SomTime", category: "Notification")

    /// 목표 시각 몇 분 전에 알릴지 (정각에는 버튼을 누르는 순간이라 소리 · 배너로 방해하지 않도록 알리지 않는다)
    private nonisolated static let targetAlertMinutesBefore = [5, 3, 1]

    private nonisolated static var targetAlertIdentifiers: [String] {
        return targetAlertMinutesBefore.map { targetAlertIdentifier(minutesBefore: $0) }
    }

    /// 목표 시각 알림 식별자 (다시 예약할 때 같은 알림을 덮어쓰고 지우는 데 쓴다)
    private nonisolated static func targetAlertIdentifier(minutesBefore: Int) -> String {
        return "serverTimeTarget.\(minutesBefore)"
    }
}

extension DependencyValues {
    nonisolated var notificationClient: NotificationClient {
        get { self[NotificationClient.self] }
        set { self[NotificationClient.self] = newValue }
    }
}

/// 앱을 보고 있을 때도 목표 시각 알림을 배너로 보여 준다
final class NotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationPresenter()

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .list, .sound]
    }
}
