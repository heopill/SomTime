//
//  MenuRow.swift
//  SomTime
//

import SwiftUI

/// 다른 화면으로 이동하는 행 (기능 카드와 같은 구조, 토글 대신 화살표)
struct MenuRow: View {
    let systemImage: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
            .padding(Spacing.cardPadding)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.card))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MenuRow(systemImage: "globe", title: "serverTime", subtitle: "serverTimeSubtitle") {}
        .padding(Spacing.screenHorizontal)
        .background(Color(.background))
}
