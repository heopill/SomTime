//
//  TimeBreakdownBar.swift
//  SomTime
//

import SwiftUI

/// 걸린 시간을 구간별로 나눠 보여 주는 막대 (높이 10) + 아래 범례 행
struct TimeBreakdownBar: View {
    struct Segment {
        let title: LocalizedStringKey
        /// 범례 오른쪽 값 (색을 바꾸려면 Text에 직접 지정한다)
        let value: Text
        let color: Color
        /// 막대에서 차지하는 비율 (0~1, 0이면 범례에만 표시)
        let fraction: Double
    }

    let segments: [Segment]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            bar
            VStack(spacing: 8) {
                ForEach(segments.indices, id: \.self) { index in
                    legendRow(segments[index])
                }
            }
        }
    }

    private var bar: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(segments.indices, id: \.self) { index in
                    Rectangle()
                        .fill(segments[index].color)
                        .frame(width: geometry.size.width * clampedFractions[index])
                }
            }
        }
        .frame(height: 10)
        .background(Color(.surfaceRaised))
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }

    /// 앞 구간부터 합이 1을 넘지 않도록 자른 비율
    private var clampedFractions: [Double] {
        var remaining = 1.0

        return segments.map { segment in
            let fraction = min(max(segment.fraction, 0), remaining)
            remaining -= fraction

            return fraction
        }
    }

    /// 색 점 + 구간 이름 + 값 한 행을 만든다
    private func legendRow(_ segment: Segment) -> some View {
        return HStack(spacing: 8) {
            Circle()
                .fill(segment.color)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
            Text(segment.title)
                .foregroundStyle(Color(.textSecondary))
            Spacer(minLength: 8)
            segment.value
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Color(.textPrimary))
        }
        .fontStyle(.summary)
        .lineLimit(1)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    TimeBreakdownBar(segments: [
        TimeBreakdownBar.Segment(title: "seatSelectionTime", value: Text("durationSeconds \("1.96")"), color: Color(.clockAmber), fraction: 0.327),
        TimeBreakdownBar.Segment(title: "bookingTime", value: Text("durationSeconds \("0.88")"), color: Color(.clockAmber).opacity(0.55), fraction: 0.147),
        TimeBreakdownBar.Segment(title: "remainingTime", value: Text("durationSeconds \("3.16")"), color: Color(.toggleOff), fraction: 0.526)
    ])
    .padding(Spacing.cardPadding)
    .background(Color(.surface))
}
