//
//  Chip.swift
//  SomTime
//

import SwiftUI

/// 작은 캡슐 라벨 (연습 중, 판정, 난이도, 최고 기록)
struct Chip: View {
    enum Style {
        /// surface 배경 (진행 중 화면)
        case surface
        /// surfaceRaised 배경 (결과 화면)
        case raised
        /// 강조색 배경 (최고 기록)
        case accent
    }

    let text: Text
    var style: Style = .raised
    /// 앞에 강조색 점을 붙일지 여부 (연습 중)
    var showsDot = false

    @Environment(\.clockAccent) private var accent

    init(_ title: LocalizedStringKey, style: Style = .raised, showsDot: Bool = false) {
        self.init(text: Text(title), style: style, showsDot: showsDot)
    }

    init(text: Text, style: Style = .raised, showsDot: Bool = false) {
        self.text = text
        self.style = style
        self.showsDot = showsDot
    }

    var body: some View {
        HStack(spacing: 6) {
            if showsDot {
                Circle()
                    .fill(accent)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
            }
            text
                .fontStyle(.sectionTitle)
                .foregroundStyle(style == .accent ? Color(.background) : Color(.textPrimary))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(background, in: Capsule())
    }

    private var background: Color {
        switch style {
        case .surface: return Color(.surface)
        case .raised: return Color(.surfaceRaised)
        case .accent: return accent
        }
    }
}

#Preview {
    VStack(spacing: Spacing.card) {
        Chip("practicing", style: .surface, showsDot: true)
        Chip("timingVerdictGreat")
        Chip("newBestRecord", style: .accent)
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
