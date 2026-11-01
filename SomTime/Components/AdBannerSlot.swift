//
//  AdBannerSlot.swift
//  SomTime
//

import ComposableArchitecture
import GoogleMobileAds
import SwiftUI

/// 화면 하단 광고 배너 자리 (폭 = 화면 가로 전체(안전 영역), 높이 = 55pt 고정).
/// 동의를 확인하는 동안과 광고를 불러오는 동안에는 배너 높이만큼 비워 두고, 광고를 요청할 수 없거나 불러오지 못하면 접는다
struct AdBannerSlot: View {
    let placement: AdPlacement

    /// 배너 높이 (목업 높이에 맞춘 고정값)
    private static let bannerHeight: CGFloat = 55

    @SharedReader(.adConsent) private var adConsent
    @State private var width: CGFloat = 0
    @State private var hasFailed = false

    var body: some View {
        VStack(spacing: 0) {
            if let adSize, isShown {
                Group {
                    if adConsent?.canRequestAds == true {
                        BannerAdView(adUnitID: placement.adUnitID, adSize: adSize) {
                            hasFailed = true
                        }
                    } else {
                        // 동의 확인 중: 자리만 비워 둔다
                        Color.clear
                    }
                }
                .frame(width: adSize.size.width, height: adSize.size.height)
                // 광고 소재가 자리보다 크게 그려져도 위 카드 · 버튼을 덮지 않도록 자리 안으로 자른다
                .clipped()
                .background(Color(.surfaceSubtle))
                // 화면 하단 여백(12)과 합쳐 카드 · 버튼과 24pt 이상 떨어뜨린다 (실수 클릭 방지)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
        }
        // 배너가 넓어도 자리 폭은 화면이 준 폭을 따른다 (가로 → 세로 회전 뒤 넓은 배너 폭이 다시 측정되어 고정되지 않도록)
        .frame(minWidth: 0, maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            width = newWidth
        }
        // 스크롤 내용이 배너 뒤로 비치지 않도록 화면 배경으로 덮는다
        .background(Color(.background))
        // 다른 화면에 다녀오면 실패했던 광고를 다시 요청한다
        .onAppear {
            hasFailed = false
        }
    }

    /// 배너 크기 (폭을 재기 전에는 없음). 적응형 배너는 높이가 폭에 따라 바뀌므로, 자리 폭 × 고정 높이의 사용자 지정 크기를 쓴다.
    /// 이 크기 안에 들어가는 광고(320×50 배너 등)만 받으며, 광고 소재가 자리보다 좁으면 가운데에 그려진다
    private var adSize: AdSize? {
        guard width > 0 else { return nil }

        return adSizeFor(cgSize: CGSize(width: width, height: Self.bannerHeight))
    }

    /// 자리를 보여 줄지 여부 (동의 확인 중이거나 광고를 요청할 수 있고, 아직 실패하지 않았을 때)
    private var isShown: Bool {
        guard !hasFailed else { return false }

        return adConsent?.canRequestAds ?? true
    }
}
