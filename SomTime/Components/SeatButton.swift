//
//  SeatButton.swift
//  SomTime
//

import SwiftUI

/// 좌석 배치도의 좌석 하나 (16pt). 선택 가능은 포도알 보라색, 선택됨은 흰색 + 체크, 판매 완료는 누를 수 없다.
/// 실전처럼 작게 그리는 연습이라 최소 터치 영역(44pt)보다 작다
struct SeatButton: View {
    enum Status {
        case available
        case selected
        case sold
    }

    static let defaultSize: CGFloat = 16
    static let spacing: CGFloat = 3

    let status: Status
    /// 좌석 크기. 좁은 기기에서는 배치도가 화면에 들어가도록 줄인다
    var size: CGFloat = SeatButton.defaultSize
    let accessibilityLabel: Text
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 4)
                .fill(fill)
                .frame(width: size, height: size)
                // 다른 사람이 잡아가 판매 완료로 바뀔 때 살짝 흐려지며 바뀐다
                .animation(.easeOut(duration: 0.2), value: status)
                .overlay {
                    if status == .selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .heavy))
                            .foregroundStyle(Color(.background))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(status == .sold)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(status == .selected ? .isSelected : [])
    }

    private var fill: Color {
        switch status {
        case .available: return Color(.seatAvailable)
        case .selected: return Color(.textPrimary)
        case .sold: return Color(.seatSold)
        }
    }
}

#Preview {
    HStack(spacing: SeatButton.spacing) {
        SeatButton(status: .available, accessibilityLabel: Text(verbatim: "A")) {}
        SeatButton(status: .selected, accessibilityLabel: Text(verbatim: "B")) {}
        SeatButton(status: .sold, accessibilityLabel: Text(verbatim: "C")) {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.island))
}
