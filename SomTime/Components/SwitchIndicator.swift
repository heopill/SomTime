//
//  SwitchIndicator.swift
//  SomTime
//

import SwiftUI

/// 토글 스위치 모양 (51×31 트랙, 27 노브). 켜지면 강조색, 꺼지면 toggleOff
struct SwitchIndicator: View {
    let isOn: Bool

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Capsule()
            .fill(isOn ? accent : Color(.toggleOff))
            .frame(width: 51, height: 31)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(.white)
                    .frame(width: 27, height: 27)
                    .padding(2)
            }
            .animation(.easeInOut(duration: 0.2), value: isOn)
            .accessibilityHidden(true)
    }
}

/// 레이블 오른쪽에 SwitchIndicator를 붙이는 토글 스타일 (설정의 초 표시, 서버 시간의 밀리초 표시 등)
struct AccentToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 12) {
                configuration.label
                    .frame(maxWidth: .infinity, alignment: .leading)
                SwitchIndicator(isOn: configuration.isOn)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

extension ToggleStyle where Self == AccentToggleStyle {
    static var accent: AccentToggleStyle { AccentToggleStyle() }
}

#Preview {
    @Previewable @State var isOn = true

    VStack(spacing: 20) {
        HStack(spacing: 28) {
            SwitchIndicator(isOn: true)
            SwitchIndicator(isOn: false)
        }
        Toggle(isOn: $isOn) {
            Text("showSeconds")
                .fontStyle(.rowLabel)
                .foregroundStyle(Color(.textPrimary))
        }
        .toggleStyle(.accent)
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
