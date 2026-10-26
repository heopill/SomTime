//
//  DifficultyButton.swift
//  SomTime
//

import SwiftUI

/// 연습 난이도 버튼 (높이 112, 3열). 이름 · 큰 값(포도알은 제한 시간) · 설명(포도알은 빈 좌석 수), 선택 시 강조색 2pt 테두리
struct DifficultyButton: View {
    let name: LocalizedStringKey
    let value: Text
    let detail: Text
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(name)
                    .fontStyle(.secondaryButton)
                    .foregroundStyle(Color(.textSecondary))
                value
                    .fontStyle(.practiceTimeLimit)
                    .foregroundStyle(Color(.textPrimary))
                detail
                    .fontStyle(.caption)
                    .foregroundStyle(Color(.textSecondary))
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .frame(height: 112)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.control)
                    .strokeBorder(isSelected ? accent : Color(.surface), lineWidth: 2)
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.control))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    HStack(spacing: 10) {
        DifficultyButton(name: "seatDifficultyEasy", value: Text("secondsLimit \(10)"), detail: Text("availableSeatRange \(10) \(15)"), isSelected: false) {}
        DifficultyButton(name: "seatDifficultyNormal", value: Text("secondsLimit \(6)"), detail: Text("availableSeatRange \(4) \(8)"), isSelected: true) {}
        DifficultyButton(name: "seatDifficultyHard", value: Text("secondsLimit \(4)"), detail: Text("availableSeatRange \(1) \(3)"), isSelected: false) {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
