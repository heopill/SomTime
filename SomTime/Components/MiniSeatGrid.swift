//
//  MiniSeatGrid.swift
//  SomTime
//

import SwiftUI

/// 작은 좌석 격자 미리보기 (장식용). availableIndices 위치의 칸만 포도알 보라색으로 칠한다
struct MiniSeatGrid: View {
    let columns: Int
    let rows: Int
    /// 보라색으로 칠할 칸 (왼쪽 위부터 줄 단위로 센 위치)
    let availableIndices: Set<Int>
    var cellSize: CGFloat = 12
    var spacing: CGFloat = 3
    var cornerRadius: CGFloat = 3

    var body: some View {
        VStack(spacing: spacing) {
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: spacing) {
                    ForEach(0..<columns, id: \.self) { column in
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(availableIndices.contains(row * columns + column) ? Color(.seatAvailable) : Color(.seatSold))
                            .frame(width: cellSize, height: cellSize)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    MiniSeatGrid(columns: 16, rows: 6, availableIndices: [9, 27, 46, 66, 83, 90])
        .padding(Spacing.screenHorizontal)
        .background(Color(.island))
}
