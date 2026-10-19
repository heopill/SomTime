//
//  AdController.swift
//  SomTime
//

import GoogleMobileAds
import UserMessagingPlatform

/// UMP 동의 처리와 Google Mobile Ads SDK 시작을 맡는다 (UMP · SDK 호출은 모두 메인 스레드에서 한다)
final class AdController {
    static let shared = AdController()

    /// 앱 실행 중 한 번만 도는 동의 · SDK 시작 작업 (여러 곳에서 불러도 같은 결과를 기다린다)
    private var startTask: Task<AdConsent, Never>?
    private var hasStartedSDK = false

    private init() {}

    /// 동의 정보를 갱신하고, 필요하면 동의 창을 띄운 뒤 SDK를 시작한다
    func start() async -> AdConsent {
        if let startTask {
            return await startTask.value
        }

        let task = Task { await gatherConsentAndStartSDK() }
        startTask = task

        return await task.value
    }

    /// 광고 개인정보 설정 창을 띄우고, 사용자가 닫은 뒤의 동의 상태를 돌려준다
    func presentPrivacyOptions() async -> AdConsent {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
        } catch {
            // 띄울 설정 창이 없으면 지금 동의 상태를 그대로 돌려준다
        }
        await startSDKIfAllowed()

        return currentConsent
    }

    /// 동의 정보 갱신 → 동의 창(필요할 때만) → SDK 시작
    private func gatherConsentAndStartSDK() async -> AdConsent {
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            // 네트워크 오류 등으로 갱신하지 못해도 이전 실행에서 받은 동의 상태로 판단한다
        }
        await startSDKIfAllowed()

        return currentConsent
    }

    /// 광고를 요청해도 되면 SDK를 시작한다 (이미 시작했으면 바로 끝난다)
    private func startSDKIfAllowed() async {
        guard ConsentInformation.shared.canRequestAds, !hasStartedSDK else { return }

        hasStartedSDK = true
        _ = await MobileAds.shared.start()
    }

    private var currentConsent: AdConsent {
        return AdConsent(
            canRequestAds: ConsentInformation.shared.canRequestAds,
            isPrivacyOptionsRequired: ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        )
    }
}
