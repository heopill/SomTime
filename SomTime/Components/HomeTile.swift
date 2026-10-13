//
//  HomeTile.swift
//  SomTime
//

import SwiftUI

/// 홈의 2열 타일 (위 아이콘 칸 + 오른쪽 화살표 또는 NEW 배지, 아래 제목 · 부제)
struct HomeTile: View {
    let systemImage: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    var showsNewBadge = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    IconTile(systemImage: systemImage)
                    Spacer(minLength: 8)
                    if showsNewBadge {
                        NewBadge()
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color(.textSecondary))
                            .accessibilityHidden(true)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .fontStyle(.cardTitle)
                        .foregroundStyle(Color(.textPrimary))
                    Text(subtitle)
                        .fontStyle(.caption)
                        .foregroundStyle(Color(.textSecondary))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.card))
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

/// 새 기능 표시 배지 (강조색 배경)
private struct NewBadge: View {
    @Environment(\.clockAccent) private var accent

    var body: some View {
        Text("newBadge")
            .fontStyle(.badge)
            .foregroundStyle(Color(.background))
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
            .background(accent, in: RoundedRectangle(cornerRadius: 6))
    }
}

#Preview {
    HStack(spacing: Spacing.card) {
        HomeTile(systemImage: "globe", title: "serverTime", subtitle: "serverTimeSubtitle") {}
        HomeTile(systemImage: "ticket", title: "ticketingPractice", subtitle: "ticketingPracticeSubtitle", showsNewBadge: true) {}
    }
    .fixedSize(horizontal: false, vertical: true)
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
