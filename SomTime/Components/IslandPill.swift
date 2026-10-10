//
//  IslandPill.swift
//  SomTime
//

import SwiftUI

/// 다이나믹 아일랜드 모양 미리보기 (높이 37). 꺼지면 폭 126, 켜지면 최소 폭 220에 시계 아이콘과 시간을 보여준다
struct IslandPill: View {
    let time: String
    let design: ClockDesign
    var isOn: Bool = true

    @Environment(\.clockAccent) private var accent

    var body: some View {
        HStack {
            if isOn {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .semibold))
                    .accessibilityHidden(true)
                Spacer(minLength: 12)
                Text(verbatim: time)
                    .fontStyle(.clock(design, placement: .island))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 14)
        .frame(minWidth: isOn ? 220 : 126, maxWidth: isOn ? nil : 126)
        .frame(height: 37)
        .fixedSize(horizontal: true, vertical: false)
        .background(Color(.island), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color(.border), lineWidth: 1)
        }
    }
}

#Preview {
    VStack(spacing: Spacing.card) {
        IslandPill(time: "14:05:32", design: .classic)
        IslandPill(time: "2:05:32 PM", design: .dot)
        IslandPill(time: "14:05:32", design: .classic, isOn: false)
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
