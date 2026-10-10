//
//  ScreenHeader.swift
//  SomTime
//

import SwiftUI

/// 하위 화면 상단 헤더 (뒤로 버튼 + 화면 타이틀)
struct ScreenHeader: View {
    let title: LocalizedStringKey
    let backAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            IconButton(systemImage: "chevron.left", accessibilityLabel: "back", action: backAction)
            Text(title)
                .fontStyle(.screenTitle)
                .foregroundStyle(Color(.textPrimary))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ScreenHeader(title: "settings") {}
        .padding(Spacing.screenHorizontal)
        .background(Color(.background))
}
