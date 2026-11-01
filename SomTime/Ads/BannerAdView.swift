//
//  BannerAdView.swift
//  SomTime
//

import GoogleMobileAds
import SwiftUI

/// AdMob 배너 뷰. 만들 때 한 번 광고를 요청하고, 광고를 받은 뒤의 갱신은 SDK가 알아서 한다.
/// 첫 광고를 받기 전에 요청이 실패하면 SDK가 다시 요청하지 않으므로, 광고를 받을 때까지 잠시 뒤 다시 요청한다
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    /// 광고를 한 번도 받지 못한 채 요청이 실패했을 때 (자리를 접는다)
    let onFirstLoadFailed: () -> Void
    /// 처음으로 광고를 받았을 때 (접어 둔 자리를 다시 편다)
    let onFirstAdReceived: () -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(onFirstLoadFailed: onFirstLoadFailed, onFirstAdReceived: onFirstAdReceived)
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        // 광고 소재가 배너 크기보다 크게 그려져도 배너 밖으로 넘치지 않게 한다
        bannerView.clipsToBounds = true
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        bannerView.load(GoogleMobileAds.Request())

        return bannerView
    }

    func updateUIView(_ bannerView: BannerView, context: Context) {
        context.coordinator.onFirstLoadFailed = onFirstLoadFailed
        context.coordinator.onFirstAdReceived = onFirstAdReceived
        // 화면 폭이 바뀌면(회전 등) 새 크기를 넣는다. SDK가 그 크기로 다시 요청한다
        if !isAdSizeEqualToSize(size1: bannerView.adSize, size2: adSize) {
            bannerView.adSize = adSize
        }
    }

    /// 배너가 화면 구성에서 빠질 때 예약해 둔 재요청을 취소한다
    static func dismantleUIView(_ bannerView: BannerView, coordinator: Coordinator) {
        coordinator.cancelRetry()
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        /// 첫 광고를 받기 전에 실패했을 때 다시 요청하기까지 기다리는 시간 (AdMob 배너 갱신 주기와 비슷하게 둔다)
        private static let retryInterval: Duration = .seconds(60)

        var onFirstLoadFailed: () -> Void
        var onFirstAdReceived: () -> Void
        /// 광고를 한 번이라도 받았는지 여부. 받은 뒤의 갱신 실패는 이전 광고가 그대로 남으므로 무시한다
        private var hasReceivedAd = false
        /// 예약해 둔 재요청
        private var retryTask: Task<Void, Never>?

        init(onFirstLoadFailed: @escaping () -> Void, onFirstAdReceived: @escaping () -> Void) {
            self.onFirstLoadFailed = onFirstLoadFailed
            self.onFirstAdReceived = onFirstAdReceived
        }

        /// 광고를 받았다
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            guard !hasReceivedAd else { return }

            hasReceivedAd = true
            onFirstAdReceived()
        }

        /// 광고 요청이 실패했다 (광고 없음 · 네트워크 오류 등)
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            guard !hasReceivedAd else { return }

            onFirstLoadFailed()
            scheduleRetry(for: bannerView)
        }

        /// 예약해 둔 재요청을 취소한다
        func cancelRetry() {
            retryTask?.cancel()
            retryTask = nil
        }

        /// 잠시 뒤 광고를 다시 요청한다. 그때 배너가 화면에 없으면(다른 화면을 보는 중) 다음 차례로 미룬다
        private func scheduleRetry(for bannerView: BannerView) {
            retryTask?.cancel()
            retryTask = Task { [weak self, weak bannerView] in
                try? await Task.sleep(for: Self.retryInterval)
                guard !Task.isCancelled, let self, let bannerView else { return }

                if bannerView.window == nil {
                    scheduleRetry(for: bannerView)
                } else {
                    bannerView.load(GoogleMobileAds.Request())
                }
            }
        }
    }
}
