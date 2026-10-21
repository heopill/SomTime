//
//  AppUpdateSharedKeys.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

// 업데이트 알림 기록 (위젯과 공유하지 않으므로 앱 전용 저장소에 저장)

extension SharedKey where Self == AppStorageKey<String?>.Default {
    /// 업데이트 알림에서 "나중에"를 누른 앱스토어 버전 (같은 버전은 다시 알리지 않는다)
    static var skippedUpdateVersion: Self {
        Self[.appStorage("skippedUpdateVersion"), default: nil]
    }
}
