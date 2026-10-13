//
//  ScreenHeader.swift
//  SomTime
//

import SwiftUI

/// 하위 화면 상단 헤더 (뒤로 버튼 + 화면 타이틀). 연습 진행 중처럼 뒤로 대신 그만하기(×)를 쓸 때는 아이콘을 바꾼다
struct ScreenHeader: View {
    let title: LocalizedStringKey
    var systemImage = "chevron.left"
    var accessibilityLabel: LocalizedStringKey = "back"
    let backAction: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            IconButton(systemImage: systemImage, accessibilityLabel: accessibilityLabel, action: backAction)
            Text(title)
                .fontStyle(.screenTitle)
                .foregroundStyle(Color(.textPrimary))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.card) {
        ScreenHeader(title: "settings") {}
        ScreenHeader(title: "timingPractice", systemImage: "xmark", accessibilityLabel: "stopPractice") {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
