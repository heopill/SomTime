//
//  RewardedAdController.swift
//  SomTime
//

import GoogleMobileAds

/// 보상형 광고를 불러오지 못했거나 띄우지 못함
nonisolated enum RewardedAdError: Error {
    case unavailable
}

/// 페이서 상점의 "광고 보고 +10P"에 쓰는 보상형 광고를 불러오고 띄운다 (광고 SDK 호출은 모두 메인 스레드에서 한다)
final class RewardedAdController: NSObject {
    static let shared = RewardedAdController()

    /// 보상형 광고 단위 ID. 디버그 빌드는 Google 테스트 광고만 받는다 (개발 중 실제 광고 노출 · 클릭 방지)
    private static var adUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/1712485313"
        #else
        return "ca-app-pub-1475161326527575/6933923985"
        #endif
    }

    private var rewardedAd: RewardedAd?
    /// 진행 중인 불러오기 (여러 번 눌러도 한 번만 불러온다)
    private var loadTask: Task<Void, Never>?
    /// 광고 화면이 닫힐 때까지 기다리는 중인 표시 요청
    private var dismissContinuation: CheckedContinuation<Void, Never>?

    private override init() {
        super.init()
    }

    /// 다음에 바로 띄울 수 있도록 광고를 미리 불러온다 (광고 동의가 없으면 불러오지 않는다)
    func load() async {
        if let loadTask {
            await loadTask.value

            return
        }
        guard rewardedAd == nil else { return }

        let task = Task {
            let consent = await AdController.shared.start()
            guard consent.canRequestAds else { return }

            rewardedAd = try? await RewardedAd.load(with: Self.adUnitID, request: Request())
        }
        loadTask = task
        await task.value
        loadTask = nil
    }

    /// 광고를 띄우고 닫힐 때까지 기다린다. 끝까지 봐서 보상을 받았으면 true (불러올 수 없으면 오류)
    func show() async throws -> Bool {
        if rewardedAd == nil {
            await load()
        }
        guard let ad = rewardedAd else { throw RewardedAdError.unavailable }

        // 한 번 띄운 광고는 다시 쓸 수 없으므로 바로 비우고, 닫힌 뒤 다음 광고를 미리 불러온다
        rewardedAd = nil
        ad.fullScreenContentDelegate = self
        var didEarnReward = false
        await withCheckedContinuation { continuation in
            dismissContinuation = continuation
            ad.present(from: nil) {
                didEarnReward = true
            }
        }
        Task { await load() }

        return didEarnReward
    }

    /// 기다리고 있는 표시 요청을 끝낸다 (이미 끝났으면 무시)
    private func resumeDismiss() {
        guard let dismissContinuation else { return }

        self.dismissContinuation = nil
        dismissContinuation.resume()
    }
}

// MARK: - FullScreenContentDelegate

extension RewardedAdController: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        resumeDismiss()
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        resumeDismiss()
    }
}
