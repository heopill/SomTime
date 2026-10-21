//
//  ReviewRequestSharedKeys.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

// 앱 평가 요청 기록 (위젯과 공유하지 않으므로 앱 전용 저장소에 저장)

extension SharedKey where Self == FileStorageKey<ReviewRequestRecord>.Default {
    /// 앱 평가 요청 기록 (성공 순간 수 · 마지막으로 요청한 앱 버전)
    static var reviewRequestRecord: Self {
        Self[.fileStorage(.applicationSupportDirectory.appending(component: "reviewRequestRecord.json")), default: ReviewRequestRecord()]
    }
}
