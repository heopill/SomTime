//
//  SomTimeApp.swift
//  SomTime
//
//  Created by 허성필 on 10/5/26.
//

import ComposableArchitecture
import SwiftUI

@main
struct SomTimeApp: App {
    static let store = Store(initialState: HomeFeature.State()) {
        HomeFeature()
    }

    var body: some Scene {
        WindowGroup {
            HomeView(store: Self.store)
        }
    }
}
