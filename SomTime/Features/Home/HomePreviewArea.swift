//
//  HomePreviewArea.swift
//  SomTime
//

import SwiftUI

/// 홈 상단 미리보기 영역 (아일랜드 모양 미리보기 + PiP 창 미리보기 + 상태 문구)
struct HomePreviewArea: View {
    let time: String
    let design: ClockDesign
    let isIslandOn: Bool
    let isPipOn: Bool

    @Environment(\.clockAccent) private var accent

    var body: some View {
        VStack(spacing: 0) {
            islandPill
                .padding(.top, 14)
            Text(caption)
                .fontStyle(.detail)
                .foregroundStyle(Color(.textSecondary))
                .padding(.top, 52)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 210)
        .overlay(alignment: .bottomTrailing) {
            if isPipOn {
                PipClockWindow(time: time, design: design)
                    .scaleEffect(0.72, anchor: .bottomTrailing)
                    .padding(14)
                    .transition(.opacity)
            }
        }
        .background(Color(.island), in: RoundedRectangle(cornerRadius: 28))
        .overlay {
            RoundedRectangle(cornerRadius: 28)
                .strokeBorder(Color(.border), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .animation(.easeInOut(duration: 0.35), value: isIslandOn)
        .animation(.easeInOut(duration: 0.25), value: isPipOn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(caption))
    }

    private var islandPill: some View {
        HStack {
            if isIslandOn {
                Image(systemName: "clock")
                    .font(.system(size: 14, weight: .semibold))
                Spacer(minLength: 8)
                Text(verbatim: time)
                    .fontStyle(.clock(design, placement: .island))
            }
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 14)
        .frame(width: isIslandOn ? 220 : 126, height: 37)
        .background(Color(.island), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(Color(.border), lineWidth: 1)
        }
    }

    private var caption: LocalizedStringKey {
        switch (isIslandOn, isPipOn) {
        case (true, true): return "homePreviewIslandAndPip"
        case (true, false): return "homePreviewIsland"
        case (false, true): return "homePreviewPip"
        case (false, false): return "homePreviewOff"
        }
    }
}

#Preview {
    VStack(spacing: Spacing.section) {
        HomePreviewArea(time: "14:05:32", design: .classic, isIslandOn: true, isPipOn: true)
        HomePreviewArea(time: "14:05:32", design: .classic, isIslandOn: false, isPipOn: false)
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
