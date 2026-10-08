//
//  SegmentedPicker.swift
//  SomTime
//

import SwiftUI

/// 둘 이상 중 하나를 고르는 세그먼트 컨트롤 (칸 높이 38, 선택 칸 segmentSelected)
struct SegmentedPicker<Option: Hashable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> LocalizedStringKey

    var body: some View {
        HStack(spacing: 2) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection

                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .fontStyle(.sectionTitle)
                        .foregroundStyle(Color(.textPrimary))
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .background(
                            isSelected ? Color(.segmentSelected) : Color.clear,
                            in: RoundedRectangle(cornerRadius: CornerRadius.segmentInner)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: CornerRadius.segmentInner))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(3)
        .background(Color(.background), in: RoundedRectangle(cornerRadius: CornerRadius.segmentOuter))
        .animation(.easeInOut(duration: 0.15), value: selection)
    }
}

#Preview {
    @Previewable @State var is24Hour = true

    SegmentedPicker(options: [true, false], selection: $is24Hour) { option in
        option ? "timeFormat24Hour" : "timeFormat12Hour"
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.surface))
}
