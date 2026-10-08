//
//  FeatureCard.swift
//  SomTime
//

import SwiftUI

/// 홈의 기능 카드 (아이콘 + 제목/상태 + 토글). 켜지면 테두리가 toggleOff 색으로 보인다
struct FeatureCard: View {
    let systemImage: String
    let title: LocalizedStringKey
    let status: LocalizedStringKey
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: Spacing.iconText) {
                IconTile(systemImage: systemImage)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .fontStyle(.cardTitle)
                        .foregroundStyle(Color(.textPrimary))
                    Text(status)
                        .fontStyle(.detail)
                        .foregroundStyle(Color(.textSecondary))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                SwitchIndicator(isOn: isOn)
            }
            .padding(Spacing.cardPadding)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(isOn ? Color(.toggleOff) : Color(.surface), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(Text(isOn ? "accessibilityOn" : "accessibilityOff"))
    }
}

#Preview {
    @Previewable @State var islandOn = true
    @Previewable @State var pipOn = false

    VStack(spacing: Spacing.card) {
        FeatureCard(
            systemImage: "capsule",
            title: "dynamicIslandClock",
            status: "dynamicIslandClockOffStatus",
            isOn: $islandOn
        )
        FeatureCard(
            systemImage: "pip",
            title: "pipClock",
            status: "pipClockOffStatus",
            isOn: $pipOn
        )
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
