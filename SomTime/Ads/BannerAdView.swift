//
//  BannerAdView.swift
//  SomTime
//

import GoogleMobileAds
import SwiftUI

/// AdMob 배너 뷰. 만들 때 한 번 광고를 요청하고, 이후 갱신은 SDK가 알아서 한다
struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    /// 광고를 한 번도 받지 못한 채 요청이 실패했을 때 (자리를 접는다)
    let onFirstLoadFailed: () -> Void

    func makeCoordinator() -> Coordinator {
        return Coordinator(onFirstLoadFailed: onFirstLoadFailed)
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
        // 화면 폭이 바뀌면(회전 등) 새 크기를 넣는다. SDK가 그 크기로 다시 요청한다
        if !isAdSizeEqualToSize(size1: bannerView.adSize, size2: adSize) {
            bannerView.adSize = adSize
        }
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        var onFirstLoadFailed: () -> Void
        /// 광고를 한 번이라도 받았는지 여부. 받은 뒤의 갱신 실패는 이전 광고가 그대로 남으므로 무시한다
        private var hasReceivedAd = false

        init(onFirstLoadFailed: @escaping () -> Void) {
            self.onFirstLoadFailed = onFirstLoadFailed
        }

        /// 광고를 받았다
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            hasReceivedAd = true
        }

        /// 광고 요청이 실패했다 (광고 없음 · 네트워크 오류 등)
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: any Error) {
            guard !hasReceivedAd else { return }

            onFirstLoadFailed()
        }
    }
}
