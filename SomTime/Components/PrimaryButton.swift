//
//  PrimaryButton.swift
//  SomTime
//

import SwiftUI

/// 화면 하단의 기본 버튼 (높이 56). 시작은 강조색 배경, 실행 중은 surfaceRaised 배경
struct PrimaryButton: View {
    let title: LocalizedStringKey
    var isRunning: Bool = false
    let action: () -> Void

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontStyle(.primaryButton)
                .foregroundStyle(isRunning ? Color(.textPrimary) : Color(.background))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    isRunning ? Color(.surfaceRaised) : accent,
                    in: RoundedRectangle(cornerRadius: CornerRadius.control)
                )
                .contentShape(RoundedRectangle(cornerRadius: CornerRadius.control))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Spacing.card) {
        PrimaryButton(title: "startServerTimePip") {}
        PrimaryButton(title: "turnOffClock", isRunning: true) {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
