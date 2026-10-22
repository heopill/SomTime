//
//  SomTimeApp.swift
//  SomTime
//
//  Created by 허성필 on 10/5/26.
//

import ComposableArchitecture
import SwiftUI
import UserNotifications

@main
struct SomTimeApp: App {
    static let store = Store(initialState: HomeFeature.State()) {
        HomeFeature()
    }

    /// 앱을 보고 있을 때도 알림이 뜨도록 알림 표시 담당을 연결한다
    init() {
        UNUserNotificationCenter.current().delegate = NotificationPresenter.shared
    }

    var body: some Scene {
        WindowGroup {
            HomeView(store: Self.store)
        }
    }
}
