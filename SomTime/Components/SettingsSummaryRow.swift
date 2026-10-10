//
//  SettingsSummaryRow.swift
//  SomTime
//

import SwiftUI

/// 홈 하단의 설정 요약 행 ("디자인 ○○ · 색상 ○○ ›")
struct SettingsSummaryRow: View {
    let design: ClockDesign
    let color: ClockColor
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text("settingsSummaryDesign")
                    .foregroundStyle(Color(.textSecondary))
                Text(design.nameKey)
                    .foregroundStyle(Color(.textPrimary))
                Text(verbatim: "·")
                    .foregroundStyle(Color(.textSecondary))
                Text("settingsSummaryColor")
                    .foregroundStyle(Color(.textSecondary))
                Text(color.nameKey)
                    .foregroundStyle(Color(.textPrimary))
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.textSecondary))
                    .accessibilityHidden(true)
            }
            .fontStyle(.summary)
            .padding(.horizontal, Spacing.cardPadding)
            .frame(minHeight: 52)
            .background(Color(.surfaceSubtle), in: RoundedRectangle(cornerRadius: CornerRadius.summaryRow))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.summaryRow))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    SettingsSummaryRow(design: .classic, color: .amber) {}
        .padding(Spacing.screenHorizontal)
        .background(Color(.background))
}
