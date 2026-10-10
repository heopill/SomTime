//
//  URLInputField.swift
//  SomTime
//

import SwiftUI

/// 사이트 주소 입력창 + 보조 버튼 (높이 52, URL 키보드, 자동완성 끔). 엔터나 버튼을 누르면 키보드를 내린다
struct URLInputField: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let placeholder: LocalizedStringKey
    let buttonTitle: LocalizedStringKey
    var isButtonEnabled = true
    let action: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            TextField(text: $text, prompt: Text(placeholder).foregroundStyle(Color(.placeholder))) {
                Text(placeholder)
            }
            .fontStyle(.rowLabel)
            .foregroundStyle(Color(.textPrimary))
            .keyboardType(.URL)
            .textContentType(.URL)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.go)
            .focused(isFocused)
            .onSubmit {
                isFocused.wrappedValue = false
                guard isButtonEnabled else { return }

                action()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.input))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.input)
                    .strokeBorder(Color(.borderStrong), lineWidth: 1)
            }

            Button {
                isFocused.wrappedValue = false
                action()
            } label: {
                Text(buttonTitle)
                    .fontStyle(.secondaryButton)
                    .foregroundStyle(Color(.textPrimary))
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(Color(.surfaceRaised), in: RoundedRectangle(cornerRadius: CornerRadius.input))
                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.input))
            }
            .buttonStyle(.plain)
            .disabled(!isButtonEnabled)
            .opacity(isButtonEnabled ? 1 : 0.5)
        }
    }
}

#Preview {
    @Previewable @State var url = ""
    @Previewable @FocusState var isFocused: Bool

    URLInputField(text: $url, isFocused: $isFocused, placeholder: "serverURLPlaceholder", buttonTitle: "measure") {}
        .padding(Spacing.screenHorizontal)
        .background(Color(.background))
}
