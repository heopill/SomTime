//
//  RecordList.swift
//  SomTime
//

import SwiftUI

/// 연습 기록 리스트 그룹 (왼쪽 레이블, 오른쪽 값). 값이 없으면 "기록 없음"을 보여 준다
struct RecordList: View {
    struct Row {
        let title: Text
        let value: Text?

        init(_ title: LocalizedStringKey, value: Text?) {
            self.init(title: Text(title), value: value)
        }

        init(title: Text, value: Text?) {
            self.title = title
            self.value = value
        }
    }

    let rows: [Row]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { index in
                if index > 0 {
                    Rectangle()
                        .fill(Color(.divider))
                        .frame(height: 1)
                }
                row(rows[index])
            }
        }
        .padding(.horizontal, Spacing.cardPadding)
        .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
    }

    /// 레이블과 값을 양쪽 끝에 둔 한 행을 만든다
    private func row(_ row: Row) -> some View {
        return HStack(spacing: 12) {
            row.title
                .foregroundStyle(Color(.textSecondary))
            Spacer(minLength: 0)
            if let value = row.value {
                value
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundStyle(Color(.textPrimary))
            } else {
                Text("noRecord")
                    .foregroundStyle(Color(.textSecondary))
            }
        }
        .fontStyle(.rowLabel)
        .lineLimit(1)
        .frame(minHeight: 52)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    RecordList(rows: [
        RecordList.Row("bestRecord", value: Text("durationSeconds \("0.012")")),
        RecordList.Row("recentAverage", value: nil),
        RecordList.Row("practiceCount", value: Text("practiceCountValue \(24)"))
    ])
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
