//
//  AdClient.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

/// 광고 동의 상태 (UMP 동의 결과)
nonisolated struct AdConsent: Equatable, Sendable {
    /// 광고를 요청해도 되는지 여부 (동의를 받았거나 동의가 필요 없는 지역)
    var canRequestAds = false
    /// 설정에 광고 개인정보 설정 항목을 보여 줘야 하는지 여부 (유럽 · 영국 등 동의가 필요한 지역)
    var isPrivacyOptionsRequired = false
}

/// 광고 동의를 받고 Google Mobile Ads SDK를 시작한다
@DependencyClient
nonisolated struct AdClient {
    /// 동의 정보를 갱신하고, 필요하면 동의 창을 띄운 뒤 SDK를 시작한다 (앱 실행마다 한 번만 실행된다)
    var start: @Sendable () async -> AdConsent = { AdConsent() }
    /// 광고 개인정보 설정 창을 띄우고, 사용자가 닫은 뒤의 동의 상태를 돌려준다
    var presentPrivacyOptions: @Sendable () async -> AdConsent = { AdConsent() }
}

extension AdClient: DependencyKey {
    nonisolated static let liveValue = AdClient(
        start: {
            return await AdController.shared.start()
        },
        presentPrivacyOptions: {
            return await AdController.shared.presentPrivacyOptions()
        }
    )

    nonisolated static let testValue = AdClient()
}

extension DependencyValues {
    nonisolated var adClient: AdClient {
        get { self[AdClient.self] }
        set { self[AdClient.self] = newValue }
    }
}
