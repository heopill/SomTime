//
//  ReviewClient.swift
//  SomTime
//

import ComposableArchitecture
import Foundation
import StoreKit
import UIKit

/// 앱 평가 요청 기준
nonisolated enum ReviewRequest {
    /// 평가를 요청하기 전에 쌓여야 하는 성공 순간 수
    static let minimumSuccessCount = 3
    /// 성공 순간의 결과를 먼저 볼 수 있도록 평가 요청 창을 띄우기 전에 기다리는 시간
    static let delay: Duration = .seconds(1)
    /// App Store의 섬타임 리뷰 작성 화면
    static let writeReviewURL = URL(string: "https://apps.apple.com/app/id6820983446?action=write-review")
}

/// 앱 평가 요청 기록. 성공 순간(서버 시간 측정 성공 · 연습 성공)을 세고, 같은 앱 버전에서는 한 번만 요청한다
nonisolated struct ReviewRequestRecord: Codable, Equatable, Sendable {
    /// 지금까지 쌓인 성공 순간 수
    var successCount = 0
    /// 마지막으로 평가를 요청한 앱 버전
    var lastRequestedVersion: String?

    /// 성공 순간을 하나 기록하고, 이번에 평가를 요청해야 하면 true를 돌려준다
    mutating func recordSuccess(appVersion: String) -> Bool {
        successCount += 1
        guard successCount >= ReviewRequest.minimumSuccessCount, lastRequestedVersion != appVersion else { return false }

        lastRequestedVersion = appVersion

        return true
    }
}

/// 시스템 앱 평가 요청 창을 띄운다
@DependencyClient
nonisolated struct ReviewClient {
    /// 지금 설치된 앱 버전 (예: 26.3.0)
    var appVersion: @Sendable () -> String = { "" }
    /// 잠시 기다린 뒤 앱 평가 요청 창을 띄운다 (실제로 띄울지는 시스템이 1년에 3번 이내로 정한다)
    var requestReview: @Sendable () async -> Void
}

extension ReviewClient: DependencyKey {
    nonisolated static let liveValue = ReviewClient(
        appVersion: {
            return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
        },
        requestReview: {
            try? await Task.sleep(for: ReviewRequest.delay)
            await MainActor.run {
                guard let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }) else { return }

                AppStore.requestReview(in: scene)
            }
        }
    )

    nonisolated static let testValue = ReviewClient()
}

extension ReviewClient {
    /// 성공 순간을 기록하고, 평가를 요청할 때가 되면 평가 요청 창을 띄우는 이펙트를 돌려준다
    nonisolated func recordSuccess<Action>(in record: Shared<ReviewRequestRecord>) -> Effect<Action> {
        let requestsReview = record.withLock { $0.recordSuccess(appVersion: appVersion()) }
        guard requestsReview else { return .none }

        return .run { _ in await requestReview() }
    }
}

extension DependencyValues {
    nonisolated var reviewClient: ReviewClient {
        get { self[ReviewClient.self] }
        set { self[ReviewClient.self] = newValue }
    }
}
