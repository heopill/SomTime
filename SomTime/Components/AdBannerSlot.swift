//
//  AdBannerSlot.swift
//  SomTime
//

import ComposableArchitecture
import GoogleMobileAds
import SwiftUI

/// 화면 하단 광고 배너 자리 (폭 = 화면 폭 − 40, 높이는 SDK가 정한다).
/// 동의를 확인하는 동안과 광고를 불러오는 동안에는 배너 높이만큼 비워 두고, 광고를 요청할 수 없거나 불러오지 못하면 접는다
struct AdBannerSlot: View {
    let placement: AdPlacement

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
                .background(Color(.surfaceSubtle), in: RoundedRectangle(cornerRadius: CornerRadius.adBanner))
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
        .padding(.horizontal, Spacing.screenHorizontal)
        // 스크롤 내용이 배너 뒤로 비치지 않도록 화면 배경으로 덮는다
        .background(Color(.background))
        // 다른 화면에 다녀오면 실패했던 광고를 다시 요청한다
        .onAppear {
            hasFailed = false
        }
    }

    /// 배너 크기 (폭을 재기 전에는 없음). 목업과 같은 높이(350pt 폭에서 약 55pt)가 나오는 표준 적응형 앵커 배너를 쓴다.
    /// SDK 13은 더 높은(최대 150pt) large 배너를 권장하며 이 함수를 deprecated로 표시했지만, 13.x에서는 그대로 동작한다
    private var adSize: AdSize? {
        guard width > 0 else { return nil }

        return currentOrientationAnchoredAdaptiveBanner(width: width)
    }

    /// 자리를 보여 줄지 여부 (동의 확인 중이거나 광고를 요청할 수 있고, 아직 실패하지 않았을 때)
    private var isShown: Bool {
        guard !hasFailed else { return false }

        return adConsent?.canRequestAds ?? true
    }
}
