//
//  ServerTimeView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

struct ServerTimeView: View {
    @Bindable var store: StoreOf<ServerTimeFeature>

    @FocusState private var isURLFieldFocused: Bool
    @Environment(\.clockAccent) private var accent

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ScreenHeader(title: "serverTime") {
                store.send(.backButtonTapped)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    urlSection
                    resultSection
                    displayModeSection
                    targetSection
                    // 하단에 고정하면 목표 시각을 못 보고 시작하기 쉬워서 옵션 맨 아래에 붙인다
                    startButton
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .background { keyboardDismissArea }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // 주소를 입력하는 동안에는 키보드 바로 위에 광고가 붙지 않도록 뺀다 (실수 클릭 방지)
            if !isURLFieldFocused {
                AdBannerSlot(placement: .serverTime)
            }
        }
        .background { keyboardDismissArea }
        .background(Color(.background))
        .toolbar(.hidden, for: .navigationBar)
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            store.send(.onAppear)
        }
    }

    private var urlSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("serverURLSection")
            URLInputField(
                text: Binding(
                    get: { store.urlText },
                    set: { store.send(.urlTextChanged($0)) }
                ),
                isFocused: $isURLFieldFocused,
                placeholder: "serverURLPlaceholder",
                buttonTitle: measureButtonTitle,
                isButtonEnabled: !store.isMeasuring
            ) {
                store.send(.measureButtonTapped)
            }
        }
    }

    /// 버튼 · 입력창이 아닌 빈 곳을 누르면 키보드를 내리는 배경 (뒤에 깔려 있어 다른 컨트롤의 터치를 가로채지 않는다)
    private var keyboardDismissArea: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
                isURLFieldFocused = false
            }
    }

    private var measureButtonTitle: LocalizedStringKey {
        if store.isMeasuring {
            return "measuring"
        }

        return store.measurement == nil ? "measure" : "remeasure"
    }

    /// 결과 카드 (검정) + 측정 후 CDN 안내
    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            ServerTimeResultCard(
                measurement: store.measurement,
                isMeasuring: store.isMeasuring,
                showsMilliseconds: store.showsMillisecondsInResult,
                settings: ClockDisplaySettings(
                    design: store.clockDesign,
                    color: store.clockColor,
                    isTwentyFourHour: store.isTwentyFourHour,
                    showsSeconds: store.showsSeconds,
                    showsDayPeriod: store.showsDayPeriod
                )
            )
            if store.measurement != nil {
                Text("serverTimeCDNNotice")
                    .fontStyle(.caption)
                    .foregroundStyle(Color(.textSecondary))
                    .padding(.horizontal, 4)
            }
        }
    }

    private var displayModeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("displayModeSection")
            HStack(spacing: 10) {
                SelectionButton(systemImage: "capsule", title: "dynamicIsland", isSelected: store.displayMode == .island) {
                    store.send(.displayModeSelected(.island))
                }
                SelectionButton(systemImage: "pip", title: "pipClock", isSelected: store.displayMode == .pip) {
                    store.send(.displayModeSelected(.pip))
                }
            }
            .disabled(store.isRunning)
            .opacity(store.isRunning ? 0.5 : 1)

            if store.displayMode == .pip {
                Toggle(
                    isOn: Binding(
                        get: { store.showsMilliseconds },
                        set: { store.send(.showsMillisecondsChanged($0)) }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("showMilliseconds")
                            .fontStyle(.rowLabel)
                            .foregroundStyle(Color(.textPrimary))
                        Text("showMillisecondsDescription")
                            .fontStyle(.caption)
                            .foregroundStyle(Color(.textSecondary))
                    }
                }
                .toggleStyle(.accent)
                .padding(.leading, Spacing.cardPadding)
                .padding(.trailing, 14)
                .frame(minHeight: 60)
                .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.summaryRow))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.displayMode)
    }

    /// 목표 시각: 카운트다운 · 알림 토글 + 켜면 시각 선택 행 · 5초 전부터 진동 토글 · 카드 아래 자동 종료 안내
    private var targetSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("targetTimeSection")
            VStack(spacing: 0) {
                Toggle(
                    isOn: Binding(
                        get: { store.isTargetOn },
                        set: { store.send(.targetToggled($0)) }
                    )
                ) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("targetCountdown")
                            .fontStyle(.rowLabel)
                            .foregroundStyle(Color(.textPrimary))
                        // 두 줄로 넘어가는 설명이라 caption 기본 행간(6pt)보다 좁혀 한 덩어리로 읽히게 한다
                        Text("targetCountdownDescription")
                            .font(FontStyle.caption.font)
                            .lineSpacing(2)
                            .foregroundStyle(Color(.textSecondary))
                    }
                }
                .toggleStyle(.accent)
                .padding(.vertical, 10)
                .frame(minHeight: 60)

                if store.isTargetOn {
                    VStack(spacing: 0) {
                        targetDivider
                        HStack(spacing: 8) {
                            Text("targetTime")
                                .fontStyle(.rowLabel)
                                .foregroundStyle(Color(.textPrimary))
                            Spacer(minLength: 12)
                            if let targetDayKey {
                                Text(targetDayKey)
                                    .fontStyle(.rowLabel)
                                    .foregroundStyle(Color(.textSecondary))
                            }
                            DatePicker(
                                "targetTime",
                                selection: Binding(
                                    get: { store.targetDate },
                                    set: { store.send(.targetTimeChanged($0)) }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .tint(accent)
                        }
                        .frame(minHeight: 56)

                        targetDivider
                        Toggle(
                            isOn: Binding(
                                get: { store.vibratesBeforeTarget },
                                set: { store.send(.targetVibrationToggled($0)) }
                            )
                        ) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("targetVibration")
                                    .fontStyle(.rowLabel)
                                    .foregroundStyle(Color(.textPrimary))
                                Text("targetVibrationDescription")
                                    .font(FontStyle.caption.font)
                                    .lineSpacing(2)
                                    .foregroundStyle(Color(.textSecondary))
                            }
                        }
                        .toggleStyle(.accent)
                        .padding(.vertical, 10)
                        .frame(minHeight: 60)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.leading, Spacing.cardPadding)
            .padding(.trailing, 14)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))

            if store.isTargetOn {
                Text("targetAutoStopNotice")
                    .fontStyle(.caption)
                    .foregroundStyle(Color(.textSecondary))
                    .padding(.horizontal, 4)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.isTargetOn)
    }

    /// 목표 시각이 오늘인지 내일인지 (그 밖이면 표시하지 않는다)
    private var targetDayKey: LocalizedStringKey? {
        if Calendar.current.isDateInToday(store.targetDate) {
            return "today"
        }
        if Calendar.current.isDateInTomorrow(store.targetDate) {
            return "tomorrow"
        }

        return nil
    }

    /// 목표 시각 그룹의 행 구분선
    private var targetDivider: some View {
        Rectangle()
            .fill(Color(.divider))
            .frame(height: 1)
            .padding(.trailing, -14)
    }

    private var startButton: some View {
        PrimaryButton(title: startButtonTitle, style: store.isRunning ? .neutral : .accent) {
            store.send(.startButtonTapped)
        }
        .disabled(!store.isRunning && store.measurement == nil)
        .opacity(!store.isRunning && store.measurement == nil ? 0.4 : 1)
    }

    private var startButtonTitle: LocalizedStringKey {
        guard !store.isRunning else { return "turnOffClock" }

        return store.displayMode == .pip ? "startServerTimePip" : "startServerTimeIsland"
    }

    /// 섹션 제목 스타일(13pt SemiBold, textSecondary)을 적용한다
    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        return Text(title)
            .fontStyle(.sectionTitle)
            .foregroundStyle(Color(.textSecondary))
            .accessibilityAddTraits(.isHeader)
    }
}

/// 서버 시간 결과 카드 (호스트 · 서버 시각 38pt · 폰과의 차이와 오차). 측정 전에는 안내 문구
private struct ServerTimeResultCard: View {
    let measurement: ServerTimeMeasurement?
    let isMeasuring: Bool
    let showsMilliseconds: Bool
    let settings: ClockDisplaySettings

    @Environment(\.clockAccent) private var accent

    var body: some View {
        VStack(spacing: 8) {
            if let measurement, !isMeasuring {
                Text("serverTimeResultTitle \(measurement.host)")
                    .fontStyle(.detail)
                    .foregroundStyle(Color(.textSecondary))
                    .lineLimit(1)
                    .truncationMode(.middle)
                ServerTimeClockText(offset: measurement.offset, showsMilliseconds: showsMilliseconds, settings: settings)
                    .foregroundStyle(accent)
                comparison(measurement)
                    .fontStyle(.detail)
                    .foregroundStyle(Color(.textSecondary))
            } else {
                Text(isMeasuring ? "serverTimeMeasuringGuide" : "serverTimeGuide")
                    .fontStyle(.summary)
                    .foregroundStyle(Color(.textSecondary))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 132)
        .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color(.border), lineWidth: 1)
        }
    }

    /// "내 폰보다 0.42초 빠름 · 오차 ±0.03초" (차이 부분은 textPrimary로 강조)
    private func comparison(_ measurement: ServerTimeMeasurement) -> Text {
        let difference = measurement.offset.magnitude.formatted(.number.precision(.fractionLength(2)))
        let accuracy = measurement.accuracy.formatted(.number.precision(.fractionLength(2)))
        let differenceText = Text(measurement.offset >= 0 ? "serverTimeFaster \(difference)" : "serverTimeSlower \(difference)")
            .foregroundStyle(Color(.textPrimary))

        return Text("serverTimeComparison \(differenceText) \(accuracy)")
    }
}

/// 서버 시각을 그리는 시계 텍스트. 서버 시각의 초가 바뀌는 순간에 맞춰 갱신한다 (밀리초를 표시하면 초당 30번)
private struct ServerTimeClockText: View {
    let offset: TimeInterval
    let showsMilliseconds: Bool
    let settings: ClockDisplaySettings

    var body: some View {
        Group {
            if showsMilliseconds {
                TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                    clock(at: context.date)
                }
            } else {
                TimelineView(.periodic(from: nextServerSecond, by: 1)) { context in
                    clock(at: context.date)
                }
            }
        }
        // 오프셋이 바뀌면 갱신 시점도 다시 계산한다
        .id(offset)
    }

    /// 폰 시각 기준으로 다음 서버 초가 시작되는 순간
    private var nextServerSecond: Date {
        let serverNow = Date().timeIntervalSince1970 + offset

        return Date(timeIntervalSince1970: serverNow.rounded(.up) - offset + 0.005)
    }

    /// 폰 시각에 오프셋을 더한 서버 시각을 그린다
    private func clock(at date: Date) -> some View {
        let serverDate = date.addingTimeInterval(offset)

        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: ClockTimeFormatter.string(
                from: serverDate,
                isTwentyFourHour: settings.isTwentyFourHour,
                showsSeconds: settings.showsSeconds,
                showsDayPeriod: settings.showsDayPeriod,
                design: settings.design
            ))
            .fontStyle(.clock(settings.design, placement: .serverTime))
            if showsMilliseconds {
                Text(verbatim: ".\(String(format: "%03d", Int((serverDate.timeIntervalSince1970 * 1000).rounded(.down)) % 1000))")
                    .fontStyle(.clock(settings.design, placement: .serverTimeMilliseconds))
                    .opacity(0.75)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
}

#Preview {
    ServerTimeView(
        store: Store(initialState: ServerTimeFeature.State()) {
            ServerTimeFeature()
        }
    )
}
