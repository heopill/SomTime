//
//  ServerTimeView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

// TODO: 서버 시간 화면 이슈에서 구현 (지금은 헤더만 있는 빈 화면)
struct ServerTimeView: View {
    let store: StoreOf<ServerTimeFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.section) {
            ScreenHeader(title: "serverTime") {
                store.send(.backButtonTapped)
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
    ServerTimeView(
        store: Store(initialState: ServerTimeFeature.State()) {
            ServerTimeFeature()
        }
    )
}
