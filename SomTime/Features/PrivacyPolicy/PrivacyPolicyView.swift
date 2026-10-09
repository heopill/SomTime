//
//  PrivacyPolicyView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

struct PrivacyPolicyView: View {
    let store: StoreOf<PrivacyPolicyFeature>

    /// 번들에 포함된 개인정보 처리방침 HTML (ko.lproj / en.lproj 중 앱 언어에 맞는 파일)
    private var htmlURL: URL? {
        return Bundle.main.url(forResource: "privacy_policy", withExtension: "html")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "privacyPolicy") {
                store.send(.backButtonTapped)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, 8)

            if let htmlURL {
                WebView(fileURL: htmlURL)
            } else {
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(.background))
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    PrivacyPolicyView(
        store: Store(initialState: PrivacyPolicyFeature.State()) {
            PrivacyPolicyFeature()
        }
    )
}
