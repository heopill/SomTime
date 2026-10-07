//
//  PipClockWindow.swift
//  SomTime
//

import SwiftUI

/// PiP 시계 창 (약 208×78, island 배경). 밀리초가 있으면 작게(약 2/3) + 투명도 75%로 붙인다
struct PipClockWindow: View {
    let time: String
    var milliseconds: String?
    let design: ClockDesign

    @Environment(\.clockAccent) private var accent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: time)
                .fontStyle(.clock(design, placement: .pip))
            if let milliseconds {
                Text(verbatim: ".\(milliseconds)")
                    .fontStyle(.clock(design, placement: .pipMilliseconds))
                    .opacity(0.75)
            }
        }
        .foregroundStyle(accent)
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 12)
        .frame(width: 208, height: 78)
        .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.input))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.input)
                .strokeBorder(Color(.borderStrong), lineWidth: 1)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.card) {
        PipClockWindow(time: "14:05:32", design: .classic)
        PipClockWindow(time: "14:05:32", milliseconds: "418", design: .classic)
        PipClockWindow(time: "14:05:32", design: .dot)
            .environment(\.clockAccent, ClockColor.mint.color)
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
