//
//  AdSharedKeys.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

// 광고 동의 상태 (저장하지 않는다. 앱을 실행할 때마다 UMP에서 다시 받는다)

extension SharedKey where Self == InMemoryKey<AdConsent?>.Default {
    /// 광고 동의 상태. 확인하기 전에는 nil (배너는 자리만 비워 두고 기다린다)
    static var adConsent: Self {
        Self[.inMemory("adConsent"), default: nil]
    }
}
