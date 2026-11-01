//
//  PacerRow.swift
//  SomTime
//

import SwiftUI

/// 페이서 목록의 행 (왼쪽 달리는 페이서, 가운데 이름, 오른쪽 사용 중 · 보유 · 잠금 가격). 행 전체를 누를 수 있다
struct PacerRow: View {
    let pacer: PipPacer
    let isSelected: Bool
    let isUnlocked: Bool
    /// 잠긴 페이서를 지금 포인트로 해제할 수 있는지 여부 (가격을 흐리게 보일지)
    let canAfford: Bool
    let action: () -> Void

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.iconText) {
                thumbnail
                    .frame(width: 48, height: 32)
                VStack(alignment: .leading, spacing: 0) {
                    Text(pacer.nameKey)
                        .fontStyle(.rowLabel)
                        .foregroundStyle(Color(.textPrimary))
                    if let subtitle {
                        Text(subtitle)
                            .fontStyle(.caption)
                            .foregroundStyle(Color(.textSecondary))
                    }
                }
                Spacer(minLength: 12)
                status
            }
            .padding(.leading, Spacing.cardPadding)
            .padding(.trailing, 14)
            .frame(minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 왼쪽 미리보기 (해제한 페이서는 흰색, 잠긴 페이서는 흐린 색으로 달린다)
    @ViewBuilder
    private var thumbnail: some View {
        if pacer == .off {
            Image(systemName: "nosign")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(.placeholder))
        } else {
            PipPacerView(pacer: pacer, color: isUnlocked ? Color(.textPrimary) : Color(.placeholder))
        }
    }

    private var subtitle: LocalizedStringKey? {
        if pacer == .off {
            return "pacerOffSubtitle"
        }
        if pacer == PipPacer.defaultPacer {
            return "pacerDefaultSubtitle"
        }

        return nil
    }

    /// 오른쪽 상태 (사용 중 > 잠금 가격 > 보유. 무료 페이서는 보유 표시를 하지 않는다)
    @ViewBuilder
    private var status: some View {
        if isSelected {
            HStack(spacing: 4) {
                Image(systemName: "checkmark")
                    .font(.system(size: 13, weight: .bold))
                Text("pacerInUse")
                    .fontStyle(.secondaryButton)
            }
            .foregroundStyle(accent)
        } else if !isUnlocked {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(.textSecondary))
                Text("pacerPointsValue \(pacer.price)")
                    .fontStyle(.secondaryButton)
                    .foregroundStyle(canAfford ? Color(.textPrimary) : Color(.placeholder))
            }
        } else if !pacer.isFree {
            Text("pacerOwned")
                .fontStyle(.detail)
                .foregroundStyle(Color(.textSecondary))
        }
    }
}

#Preview {
    VStack(spacing: 0) {
        PacerRow(pacer: .off, isSelected: false, isUnlocked: true, canAfford: true) {}
        PacerRow(pacer: .jogger, isSelected: true, isUnlocked: true, canAfford: true) {}
        PacerRow(pacer: .fox, isSelected: false, isUnlocked: true, canAfford: true) {}
        PacerRow(pacer: .rocket, isSelected: false, isUnlocked: false, canAfford: true) {}
        PacerRow(pacer: .camperVan, isSelected: false, isUnlocked: false, canAfford: false) {}
    }
    .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
