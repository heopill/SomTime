//
//  SelectionButton.swift
//  SomTime
//

import SwiftUI

/// 서버 시간의 표시 방식 선택 버튼 (높이 96, 2열). 선택 시 강조색 2pt 테두리
struct SelectionButton: View {
    let systemImage: String
    let title: LocalizedStringKey
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .regular))
                    .accessibilityHidden(true)
                Text(title)
                    .fontStyle(.secondaryButton)
            }
            .foregroundStyle(Color(.textPrimary))
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.control)
                    .strokeBorder(isSelected ? accent : Color(.surface), lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.control))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack(spacing: 10) {
        SelectionButton(systemImage: "capsule", title: "dynamicIsland", isSelected: true) {}
        SelectionButton(systemImage: "pip", title: "pipClock", isSelected: false) {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
