//
//  DesignCard.swift
//  SomTime
//

import SwiftUI

/// 설정의 시계 디자인 카드 (136×104, "14:05" 미리보기). 선택 시 강조색 2pt 테두리
struct DesignCard: View {
    let design: ClockDesign
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(verbatim: "14:05")
                    .fontStyle(.clock(design, placement: .designCard))
                    .foregroundStyle(Color(.textPrimary))
                    .accessibilityHidden(true)
                Text(design.nameKey)
                    .fontStyle(.caption)
                    .foregroundStyle(Color(.textSecondary))
            }
            .frame(width: 136, height: 104)
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
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
            ForEach(ClockDesign.allCases, id: \.self) { design in
                DesignCard(design: design, isSelected: design == .classic) {}
            }
        }
        .padding(.horizontal, Spacing.screenHorizontal)
    }
    .padding(.vertical, Spacing.screenHorizontal)
    .background(Color(.background))
}
