//
//  SettingsView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                ScreenHeader(title: "settings") {
                    store.send(.backButtonTapped)
                }
                preview
                designSection
                colorSection
                displayOptionsSection
                appSection
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, Spacing.section)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color(.background))
        .toolbar(.hidden, for: .navigationBar)
        .environment(\.clockAccent, store.clockColor.color)
        .navigationDestination(
            item: $store.scope(state: \.privacyPolicy, action: \.privacyPolicy)
        ) { privacyPolicyStore in
            PrivacyPolicyView(store: privacyPolicyStore)
        }
        // 문의하기: 기기/앱 정보가 자동 입력된 메일 작성 창
        .sheet(
            isPresented: Binding(
                get: { store.isMailComposePresented },
                set: { if !$0 { store.send(.mailComposeDismissed) } }
            )
        ) {
            MailComposeView(
                recipient: SupportInfo.recipient,
                subject: SupportInfo.subject,
                body: SupportInfo.body,
                onFinish: { store.send(.mailComposeDismissed) }
            )
            .ignoresSafeArea()
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        // 문의 정보 복사 완료 토스트 (하단, 잠시 후 자동으로 사라짐)
        .overlay(alignment: .bottom) {
            if store.isContactInfoCopiedToastPresented {
                ToastMessage(message: "contactInfoCopied")
                    .padding(.bottom, 24)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.isContactInfoCopiedToastPresented)
    }

    private var preview: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            IslandPill(
                time: ClockTimeFormatter.string(
                    from: context.date,
                    isTwentyFourHour: store.isTwentyFourHour,
                    showsSeconds: store.showsSeconds,
                    showsDayPeriod: store.showsDayPeriod,
                    design: store.clockDesign
                ),
                design: store.clockDesign
            )
            .padding(.top, 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .frame(height: 96)
        .background(Color(.island), in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(Color(.border), lineWidth: 1)
        }
        .animation(.easeInOut(duration: 0.2), value: store.clockDesign)
        .accessibilityHidden(true)
    }

    private var designSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle {
                Text("clockDesignSection")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ClockDesign.allCases, id: \.self) { design in
                        DesignCard(design: design, isSelected: design == store.clockDesign) {
                            store.send(.designSelected(design))
                        }
                    }
                }
                .padding(.vertical, 2)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, Spacing.screenHorizontal, for: .scrollContent)
            .padding(.horizontal, -Spacing.screenHorizontal)
        }
    }

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle {
                HStack(spacing: 4) {
                    Text("clockColorSection")
                    Text(verbatim: "·")
                    Text(store.clockColor.nameKey)
                }
            }
            HStack(spacing: 0) {
                ForEach(ClockColor.allCases, id: \.self) { clockColor in
                    ColorSwatch(clockColor: clockColor, isSelected: clockColor == store.clockColor) {
                        store.send(.colorSelected(clockColor))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var displayOptionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle {
                Text("displayOptionsSection")
            }
            VStack(spacing: 0) {
                HStack {
                    Text("timeFormat")
                        .fontStyle(.rowLabel)
                        .foregroundStyle(Color(.textPrimary))
                    Spacer(minLength: 12)
                    SegmentedPicker(
                        options: [true, false],
                        selection: Binding(
                            get: { store.isTwentyFourHour },
                            set: { store.send(.timeFormatChanged(isTwentyFourHour: $0)) }
                        )
                    ) { isTwentyFourHour in
                        isTwentyFourHour ? "timeFormat24Hour" : "timeFormat12Hour"
                    }
                }
                .padding(.vertical, 10)
                .frame(minHeight: 56)

                // 12시간제일 때만 오전/오후 표시 토글을 보여 준다
                if !store.isTwentyFourHour {
                    VStack(spacing: 0) {
                        divider

                        Toggle(
                            isOn: Binding(
                                get: { store.showsDayPeriod },
                                set: { store.send(.showsDayPeriodChanged($0)) }
                            )
                        ) {
                            Text("showDayPeriod")
                                .fontStyle(.rowLabel)
                                .foregroundStyle(Color(.textPrimary))
                        }
                        .toggleStyle(.accent)
                        .frame(minHeight: 56)
                    }
                    .transition(.opacity)
                }

                divider

                Toggle(
                    isOn: Binding(
                        get: { store.showsSeconds },
                        set: { store.send(.showsSecondsChanged($0)) }
                    )
                ) {
                    Text("showSeconds")
                        .fontStyle(.rowLabel)
                        .foregroundStyle(Color(.textPrimary))
                }
                .toggleStyle(.accent)
                .frame(minHeight: 56)

                divider

                HStack {
                    Text("pipAspectRatio")
                        .fontStyle(.rowLabel)
                        .foregroundStyle(Color(.textPrimary))
                    Spacer(minLength: 12)
                    SegmentedPicker(
                        options: PipAspectRatio.allCases,
                        selection: Binding(
                            get: { store.pipAspectRatio },
                            set: { store.send(.pipAspectRatioChanged($0)) }
                        )
                    ) { aspectRatio in
                        aspectRatio.nameKey
                    }
                }
                .padding(.vertical, 10)
                .frame(minHeight: 56)
            }
            .padding(.leading, Spacing.cardPadding)
            .padding(.trailing, 14)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
            .animation(.easeInOut(duration: 0.2), value: store.isTwentyFourHour)
        }
    }

    /// 표시 옵션 그룹의 행 구분선
    private var divider: some View {
        Rectangle()
            .fill(Color(.divider))
            .frame(height: 1)
            .padding(.trailing, -14)
    }

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle {
                Text("appSection")
            }
            VStack(spacing: 0) {
                navigationRow(title: "language", value: currentLanguageName) {
                    store.send(.languageRowTapped)
                }
                appRowDivider
                navigationRow(title: "privacyPolicy") {
                    store.send(.privacyPolicyRowTapped)
                }
                appRowDivider
                navigationRow(title: "contactUs") {
                    store.send(.contactRowTapped)
                }
            }
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
        }
    }

    /// 앱 그룹의 행 (제목, 현재 값, 화살표). 행 전체를 누를 수 있다
    private func navigationRow(
        title: LocalizedStringKey,
        value: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        return Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .fontStyle(.rowLabel)
                    .foregroundStyle(Color(.textPrimary))
                Spacer(minLength: 12)
                if let value {
                    Text(verbatim: value)
                        .fontStyle(.rowLabel)
                        .foregroundStyle(Color(.textSecondary))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(.textSecondary))
                    .accessibilityHidden(true)
            }
            .padding(.leading, Spacing.cardPadding)
            .padding(.trailing, 14)
            .frame(minHeight: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    /// 앱 그룹의 행 구분선 (행 제목 위치부터 카드 오른쪽 끝까지)
    private var appRowDivider: some View {
        Rectangle()
            .fill(Color(.divider))
            .frame(height: 1)
            .padding(.leading, Spacing.cardPadding)
    }

    // 앱에 지금 적용된 언어 이름을 그 언어로 표시한다 (예: 한국어, English)
    private var currentLanguageName: String {
        let languageCode = Bundle.main.preferredLocalizations.first ?? "en"
        let languageName = Locale(identifier: languageCode).localizedString(forLanguageCode: languageCode) ?? languageCode

        return languageName.localizedCapitalized
    }

    /// 섹션 제목 스타일(13pt SemiBold, textSecondary)을 적용한다
    private func sectionTitle<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        return content()
            .fontStyle(.sectionTitle)
            .foregroundStyle(Color(.textSecondary))
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        }
    )
}
