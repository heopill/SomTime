//
//  SomTimeApp.swift
//  SomTime
//
//  Created by 허성필 on 10/5/26.
//

import ComposableArchitecture
import SwiftUI
import TipKit
import UserNotifications

@main
struct SomTimeApp: App {
    static let store = Store(initialState: HomeFeature.State()) {
        HomeFeature()
    }

    /// 앱을 보고 있을 때도 알림이 뜨도록 알림 표시 담당을 연결하고, 페이서 지갑의 iCloud 동기화와 안내 말풍선을 준비한다
    init() {
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
        NSUbiquitousKeyValueStore.default.synchronize()
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            HomeView(store: Self.store)
        }
    }
}
