//
//  ColorSwatch.swift
//  SomTime
//

import SwiftUI

/// 시계 색상 선택 원 (48 터치 영역, 32 색 원, 선택 시 textPrimary 2pt 링)
struct ColorSwatch: View {
    let clockColor: ClockColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(clockColor.color)
                .frame(width: 32, height: 32)
                .frame(width: 48, height: 48)
                .overlay {
                    Circle()
                        .strokeBorder(isSelected ? Color(.textPrimary) : Color.clear, lineWidth: 2)
                }
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(clockColor.nameKey))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack(spacing: 6) {
        ForEach(ClockColor.allCases, id: \.self) { clockColor in
            ColorSwatch(clockColor: clockColor, isSelected: clockColor == .amber) {}
        }
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
