//
//  PracticeModeCard.swift
//  SomTime
//

import SwiftUI

/// 티켓팅 연습 선택 카드 (메뉴 행 머리 + 검정 미리보기 띠 + 기록 줄)
struct PracticeModeCard<Preview: View, Records: View>: View {
    let systemImage: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let action: () -> Void
    @ViewBuilder let preview: Preview
    @ViewBuilder let records: Records

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: Spacing.iconText) {
                    IconTile(systemImage: systemImage)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .fontStyle(.cardTitle)
                            .foregroundStyle(Color(.textPrimary))
                        Text(subtitle)
                            .fontStyle(.detail)
                            .foregroundStyle(Color(.textSecondary))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(.textSecondary))
                        .accessibilityHidden(true)
                }
                preview
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.input))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.input)
                            .strokeBorder(Color(.border), lineWidth: 1)
                    }
                    .accessibilityHidden(true)
                records
                    .fontStyle(.detail)
                    .foregroundStyle(Color(.textSecondary))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(Spacing.cardPadding)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.card))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    PracticeModeCard(systemImage: "stopwatch", title: "timingPractice", subtitle: "timingPracticeSubtitle", action: {}) {
        Text(verbatim: "09:59:58.416")
            .foregroundStyle(Color(.clockAmber))
    } records: {
        Text("noRecord")
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
