//
//  ToastMessage.swift
//  SomTime
//

import SwiftUI

/// 화면 하단에 잠시 떠 있다 사라지는 안내 메시지
struct ToastMessage: View {
    let message: LocalizedStringKey

    var body: some View {
        Text(message)
            .fontStyle(.summary)
            .foregroundStyle(Color(.textPrimary))
            .padding(.horizontal, Spacing.cardPadding)
            .padding(.vertical, 12)
            .background(Color(.surfaceRaised), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(Color(.borderStrong), lineWidth: 1)
            }
    }
}

#Preview {
    ToastMessage(message: "contactInfoCopied")
        .padding(Spacing.screenHorizontal)
        .background(Color(.background))
}
