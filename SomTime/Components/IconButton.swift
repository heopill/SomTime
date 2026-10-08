//
//  IconButton.swift
//  SomTime
//

import SwiftUI

/// 상단 내비게이션용 44pt 원형 버튼 (설정 톱니, 뒤로)
struct IconButton: View {
    let systemImage: String
    let accessibilityLabel: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.textPrimary))
                .frame(width: Spacing.minTouchTarget, height: Spacing.minTouchTarget)
                .background(Color(.surface), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(accessibilityLabel))
    }
}

#Preview {
    HStack(spacing: 28) {
        IconButton(systemImage: "gearshape", accessibilityLabel: "settings") {}
        IconButton(systemImage: "chevron.left", accessibilityLabel: "back") {}
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
