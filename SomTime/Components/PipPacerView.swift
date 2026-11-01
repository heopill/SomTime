//
//  PipPacerView.swift
//  SomTime
//

import SwiftUI

/// 화면 안에서 페이서가 달리는 모습 (홈 · 상점 미리보기, 상점 목록). 실제 PiP 창은 PipClockFrameRenderer가 따로 그린다
struct PipPacerView: View {
    let pacer: PipPacer
    /// 칠할 색 (nil이면 시계 색)
    var color: Color?
    var framesPerSecond: Double = PipPacerSpeed.calmFramesPerSecond

    @Environment(\.clockAccent) private var accent

    var body: some View {
        let names = pacer.frameNames
        TimelineView(.animation(minimumInterval: 1 / framesPerSecond)) { context in
            let index = Int(context.date.timeIntervalSinceReferenceDate * framesPerSecond) % PipPacer.frameCount
            if names.indices.contains(index) {
                Image(names[index])
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(color ?? accent)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: Spacing.card) {
        ForEach(PipPacer.allCases.filter { $0 != .off }, id: \.self) { pacer in
            PipPacerView(pacer: pacer)
                .frame(width: 54, height: 36)
        }
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
