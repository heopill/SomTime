//
//  AdPlacement.swift
//  SomTime
//

import Foundation

/// 배너 광고를 넣는 화면. 화면마다 AdMob 광고 단위를 따로 써서 화면별 성과를 본다
enum AdPlacement {
    case home
    case ticketingPractice
    case settings
    case serverTime

    /// 이 화면의 광고 단위 ID. 디버그 빌드는 Google 테스트 광고만 받는다 (개발 중 실제 광고 노출 · 클릭 방지)
    var adUnitID: String {
        #if DEBUG
        return "ca-app-pub-3940256099942544/2435281174"
        #else
        switch self {
        case .home:
            return "ca-app-pub-1475161326527575/3737276392"
        case .ticketingPractice:
            return "ca-app-pub-1475161326527575/4921620694"
        case .settings:
            return "ca-app-pub-1475161326527575/6234702361"
        case .serverTime:
            return "ca-app-pub-1475161326527575/2848147817"
        }
        #endif
    }
}
