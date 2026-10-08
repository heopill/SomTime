//
//  SettingsView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

// TODO: 설정 화면 이슈에서 구현 (지금은 헤더만 있는 빈 화면)
struct SettingsView: View {
    let store: StoreOf<SettingsFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            HStack(spacing: 8) {
                IconButton(systemImage: "chevron.left", accessibilityLabel: "back") {
                    store.send(.backButtonTapped)
                }
                Text("settings")
                    .fontStyle(.screenTitle)
                    .foregroundStyle(Color(.textPrimary))
                    .accessibilityAddTraits(.isHeader)
            }
            Spacer()
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.background))
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}
