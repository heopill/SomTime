//
//  IconTile.swift
//  SomTime
//

import SwiftUI

/// 기능 카드, 메뉴 행 왼쪽의 44pt 아이콘 칸
struct IconTile: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 20, weight: .regular))
            .foregroundStyle(Color(.textPrimary))
            .frame(width: 44, height: 44)
            .background(Color(.surfaceRaised), in: RoundedRectangle(cornerRadius: CornerRadius.input))
            .accessibilityHidden(true)
    }
}
