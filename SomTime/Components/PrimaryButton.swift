//
//  PrimaryButton.swift
//  SomTime
//

import SwiftUI

/// 화면 하단의 기본 버튼 (높이 56). 강조 스타일은 강조색 배경, 보조 스타일은 surfaceRaised 배경 (실행 중인 시계 끄기, 그만하기 등)
struct PrimaryButton: View {
    enum Style {
        case accent
        case neutral
    }

    let title: LocalizedStringKey
    var style: Style = .accent
    let action: () -> Void

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontStyle(.primaryButton)
                .foregroundStyle(style == .neutral ? Color(.textPrimary) : Color(.background))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    style == .neutral ? Color(.surfaceRaised) : accent,
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
        PrimaryButton(title: "turnOffClock", style: .neutral) {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
