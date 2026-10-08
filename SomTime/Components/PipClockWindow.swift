//
//  PipClockWindow.swift
//  SomTime
//

import SwiftUI

/// PiP 시계 창 (island 배경). 홈 미리보기에서 쓰는 테두리 있는 창 모양
struct PipClockWindow: View {
    let time: String
    var milliseconds: String?
    let design: ClockDesign

    var body: some View {
        PipClockText(time: time, milliseconds: milliseconds, design: design)
            .padding(.horizontal, 12)
            .frame(width: PipClockFrame.size.width, height: PipClockFrame.size.height)
            .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.input))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.input)
                    .strokeBorder(Color(.borderStrong), lineWidth: 1)
            }
    }
}

/// 실제 PiP 창에 영상 프레임으로 그리는 시계 화면 (검정 배경 + 가운데 시간. 모서리는 시스템 PiP 창이 둥글게 자른다).
/// 시스템은 PiP 창 높이에 최소값을 두고 프레임 비율대로 폭을 정하므로, 2:1로 좁혀 가장 작게 줄였을 때 폭을 줄인다
struct PipClockFrame: View {
    static let size = CGSize(width: 120, height: 60)

    let time: String
    var milliseconds: String?
    let design: ClockDesign

    var body: some View {
        PipClockText(time: time, milliseconds: milliseconds, design: design)
            .padding(.horizontal, 12)
            .frame(width: Self.size.width, height: Self.size.height)
            .background(Color(.island))
    }
}

/// PiP 시계 시간 텍스트. 밀리초가 있으면 작게(약 2/3) + 투명도 75%로 붙인다
struct PipClockText: View {
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
        .minimumScaleFactor(0.5)
    }
}

#Preview {
    VStack(spacing: Spacing.card) {
        PipClockWindow(time: "14:05:32", design: .classic)
        PipClockWindow(time: "14:05:32", milliseconds: "418", design: .classic)
        PipClockWindow(time: "14:05:32", design: .dot)
            .environment(\.clockAccent, ClockColor.mint.color)
        PipClockFrame(time: "14:05:32", design: .bold)
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
