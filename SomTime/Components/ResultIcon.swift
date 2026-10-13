//
//  ResultIcon.swift
//  SomTime
//

import SwiftUI

/// 연습 결과 아이콘 (72pt 원). 성공은 강조색 배경 + 체크, 실패는 surfaceRaised 배경 + 코랄 ×
struct ResultIcon: View {
    let isSuccess: Bool

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Image(systemName: isSuccess ? "checkmark" : "xmark")
            .font(.system(size: isSuccess ? 30 : 26, weight: .bold))
            .foregroundStyle(isSuccess ? Color(.background) : Color(.clockCoral))
            .frame(width: 72, height: 72)
            .background(isSuccess ? accent : Color(.surfaceRaised), in: Circle())
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 28) {
        ResultIcon(isSuccess: true)
        ResultIcon(isSuccess: false)
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
