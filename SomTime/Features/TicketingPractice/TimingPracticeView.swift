//
//  TimingPracticeView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

struct TimingPracticeView: View {
    @Bindable var store: StoreOf<TimingPracticeFeature>

    @Environment(\.clockAccent) private var accent

    var body: some View {
        content
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(.background))
            .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private var content: some View {
        switch store.phase {
        case .ready:
            readyContent
        case let .playing(startedAt):
            playingContent(startedAt: startedAt)
        case let .result(outcome):
            resultContent(outcome)
        }
    }

    // MARK: - 시작 전

    private var readyContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            ScreenHeader(title: "timingPractice") {
                store.send(.backButtonTapped)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    readyClockCard
                    methodSection
                    clockDisplaySection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            PrimaryButton(title: "startTest") {
                store.send(.startButtonTapped)
            }
        }
    }

    /// 연습 시계가 시작할 시각(09:59:50)과 목표 안내를 보여 주는 검정 카드
    private var readyClockCard: some View {
        VStack(spacing: 8) {
            Text("practiceServerTime")
                .fontStyle(.detail)
                .foregroundStyle(Color(.textSecondary))
            PracticeClockText(
                date: TimingPractice.startDate(),
                settings: store.clockSettings,
                showsMilliseconds: store.showsMilliseconds,
                size: .ready
            )
            Text("timingTargetGuide \(emphasized(timeText(TimingPractice.targetDate())))")
                .fontStyle(.detail)
                .foregroundStyle(Color(.textSecondary))
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color(.border), lineWidth: 1)
        }
    }

    private var methodSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("practiceMethod")
            PracticeStepList(steps: [
                Text("timingStepStart \(timeText(TimingPractice.startDate()))"),
                Text("timingStepPress \(timeText(TimingPractice.targetDate()))"),
                Text("timingStepResult")
            ])
        }
    }

    /// 시계 표시 옵션 (밀리초까지 / 초까지만)
    private var clockDisplaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("clockDisplay")
                    .fontStyle(.rowLabel)
                    .foregroundStyle(Color(.textPrimary))
                Spacer(minLength: 12)
                SegmentedPicker(
                    options: [true, false],
                    selection: Binding(
                        get: { store.showsMilliseconds },
                        set: { store.send(.showsMillisecondsChanged($0)) }
                    )
                ) { showsMilliseconds in
                    showsMilliseconds ? "clockDisplayMilliseconds" : "clockDisplaySecondsOnly"
                }
            }
            .padding(.leading, Spacing.cardPadding)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 56)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
            Text(store.showsMilliseconds ? "clockDisplayMillisecondsCaption" : "clockDisplaySecondsOnlyCaption")
                .fontStyle(.caption)
                .foregroundStyle(Color(.textSecondary))
                .padding(.horizontal, 4)
        }
    }

    // MARK: - 진행 중

    /// 진행 중 화면 (흐르는 연습 시계 + 예매하기 버튼)
    private func playingContent(startedAt: Date) -> some View {
        let practiceStart = TimingPractice.startDate(now: startedAt)

        return VStack(spacing: 22) {
            ScreenHeader(title: "timingPractice", systemImage: "xmark", accessibilityLabel: "stopPractice") {
                store.send(.stopButtonTapped)
            }
            TimelineView(.animation) { context in
                playingClockCard(date: practiceStart.addingTimeInterval(context.date.timeIntervalSince(startedAt)))
            }
            VStack(spacing: 12) {
                Text("timingPressGuide")
                    .fontStyle(.detail)
                    .foregroundStyle(Color(.textSecondary))
                BookButton {
                    store.send(.bookButtonTapped)
                }
            }
        }
    }

    /// 화면을 채우는 검정 카드에 흐르는 연습 시계를 그린다
    private func playingClockCard(date: Date) -> some View {
        return VStack(spacing: 0) {
            HStack {
                Text("practiceServerTime")
                    .fontStyle(.detail)
                    .foregroundStyle(Color(.textSecondary))
                Spacer(minLength: 8)
                Chip("practicing", style: .surface, showsDot: true)
            }
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                PracticeClockText(
                    date: date,
                    settings: store.clockSettings,
                    showsMilliseconds: store.showsMilliseconds,
                    size: .playing
                )
                HStack(spacing: 4) {
                    Text("practiceTarget")
                    Text(verbatim: timeText(TimingPractice.targetDate(now: date)))
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundStyle(Color(.textPrimary))
                }
                .fontStyle(.summary)
                .foregroundStyle(Color(.textSecondary))
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color(.border), lineWidth: 1)
        }
    }

    // MARK: - 결과

    /// 결과 화면 (차이 · 판정, 누른 순간, 기록)
    private func resultContent(_ outcome: TimingPracticeOutcome) -> some View {
        return VStack(alignment: .leading, spacing: 22) {
            ScreenHeader(title: "timingPractice") {
                store.send(.backButtonTapped)
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    switch outcome {
                    case let .pressed(difference):
                        pressedHero(difference: difference)
                        PressTimelineCard(
                            difference: difference,
                            pressedTime: pressedTimeText(difference: difference)
                        )
                    case .missed:
                        missedHero
                    }
                    RecordList(rows: recordRows)
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            HStack(spacing: 10) {
                PrimaryButton(title: "quitPractice", style: .neutral) {
                    store.send(.quitButtonTapped)
                }
                .frame(width: 112)
                PrimaryButton(title: "tryAgain") {
                    store.send(.startButtonTapped)
                }
            }
        }
    }

    /// 판정 칩 + 정각과의 차이 + 설명
    private func pressedHero(difference: TimeInterval) -> some View {
        return VStack(spacing: 10) {
            Chip(TimingVerdict(difference: difference).titleKey)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: PracticeNumberFormat.signedSeconds(difference))
                    .fontStyle(.practiceResult)
                Text("secondsUnit")
                    .fontStyle(.practiceResultUnit)
            }
            .foregroundStyle(accent)
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            resultDescription(difference: difference)
                .fontStyle(.rowLabel)
                .foregroundStyle(Color(.textSecondary))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 12)
        .frame(maxWidth: .infinity)
    }

    /// 자동 종료 시각까지 누르지 않았을 때의 안내
    private var missedHero: some View {
        VStack(spacing: 10) {
            ResultIcon(isSuccess: false)
            Text("timingMissedTitle")
                .fontStyle(.screenTitle)
                .foregroundStyle(Color(.textPrimary))
                .padding(.top, 6)
            Text("timingMissedDescription \(emphasized(timeText(TimingPractice.targetDate().addingTimeInterval(TimingPractice.missTimeout))))")
                .fontStyle(.rowLabel)
                .foregroundStyle(Color(.textSecondary))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
    }

    /// "정각보다 0.087초 늦게 눌렀어요" (차이 부분은 textPrimary로 강조)
    private func resultDescription(difference: TimeInterval) -> Text {
        let magnitude = PracticeNumberFormat.seconds(abs(difference))
        guard magnitude != PracticeNumberFormat.seconds(0) else { return Text("timingResultExact") }

        let emphasis = Text(difference > 0 ? "timingLateBy \(magnitude)" : "timingEarlyBy \(magnitude)")
            .foregroundStyle(Color(.textPrimary))

        return Text("timingResultDescription \(emphasis)")
    }

    private var recordRows: [RecordList.Row] {
        let records = store.records

        return [
            RecordList.Row("bestRecord", value: records.bestMagnitude.map {
                Text("durationSeconds \(PracticeNumberFormat.seconds($0))")
            }),
            RecordList.Row("recentAverage", value: records.recentAverageMagnitude.map {
                Text("durationSeconds \(PracticeNumberFormat.seconds($0))")
            }),
            RecordList.Row("practiceCount", value: Text("practiceCountValue \(records.practiceCount)"))
        ]
    }

    // MARK: - 공통

    /// 사용자의 시간 형식으로 시각 문자열을 만든다 (초는 항상 표시)
    private func timeText(_ date: Date) -> String {
        return ClockTimeFormatter.string(
            from: date,
            isTwentyFourHour: store.isTwentyFourHour,
            showsSeconds: true,
            showsDayPeriod: store.showsDayPeriod,
            design: store.clockDesign
        )
    }

    /// 누른 순간의 연습 시계 시각 (예: 10:00:00.087)
    private func pressedTimeText(difference: TimeInterval) -> String {
        let pressedDate = TimingPractice.targetDate().addingTimeInterval(difference)

        return "\(timeText(pressedDate)).\(PracticeNumberFormat.milliseconds(of: pressedDate))"
    }

    /// 문장 속 강조 부분 (textPrimary, SemiBold)
    private func emphasized(_ string: String) -> Text {
        return Text(verbatim: string)
            .fontWeight(.semibold)
            .foregroundStyle(Color(.textPrimary))
    }

    /// 섹션 제목 스타일(13pt SemiBold, textSecondary)을 적용한다
    private func sectionTitle(_ title: LocalizedStringKey) -> some View {
        return Text(title)
            .fontStyle(.sectionTitle)
            .foregroundStyle(Color(.textSecondary))
            .accessibilityAddTraits(.isHeader)
    }
}

/// 번호를 붙인 연습 방법 리스트 (리스트 그룹, 행 최소 52)
private struct PracticeStepList: View {
    let steps: [Text]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(steps.indices, id: \.self) { index in
                if index > 0 {
                    Rectangle()
                        .fill(Color(.divider))
                        .frame(height: 1)
                }
                HStack(spacing: 12) {
                    Text(verbatim: "\(index + 1)")
                        .fontStyle(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.textPrimary))
                        .frame(width: 24, height: 24)
                        .background(Color(.surfaceRaised), in: Circle())
                        .accessibilityHidden(true)
                    steps[index]
                        .fontStyle(.summary)
                        .foregroundStyle(Color(.textPrimary))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            }
        }
        .padding(.horizontal, Spacing.cardPadding)
        .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
    }
}

/// 정각 클릭 연습의 큰 예매하기 버튼 (높이 64)
private struct BookButton: View {
    let action: () -> Void

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Button(action: action) {
            Text("book")
                .fontStyle(.largeButton)
                .foregroundStyle(Color(.background))
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(accent, in: RoundedRectangle(cornerRadius: CornerRadius.control))
                .contentShape(RoundedRectangle(cornerRadius: CornerRadius.control))
        }
        .buttonStyle(.plain)
    }
}

/// 누른 순간을 −0.5초 ~ +0.5초 트랙 위에 점으로 보여 주는 카드 (±0.05초 구간은 강조색으로 칠함)
private struct PressTimelineCard: View {
    let difference: TimeInterval
    let pressedTime: String

    @Environment(\.clockAccent) private var accent

    /// 완벽 판정 구간이 트랙에서 차지하는 비율
    private let perfectZoneFraction = 0.05 / TimingPractice.timelineRange

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("pressedMoment")
                    .foregroundStyle(Color(.textSecondary))
                Spacer(minLength: 8)
                Text(verbatim: pressedTime)
                    .monospacedDigit()
                    .foregroundStyle(Color(.textPrimary))
            }
            .fontStyle(.sectionTitle)
            track
            HStack(spacing: 0) {
                Text("timelineEarly \(rangeText)")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("onTheHour")
                    .fontWeight(.semibold)
                    .foregroundStyle(Color(.textPrimary))
                    .frame(maxWidth: .infinity)
                Text("timelineLate \(rangeText)")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .fontStyle(.caption)
            .foregroundStyle(Color(.textSecondary))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(Spacing.cardPadding)
        .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    private var track: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.surfaceRaised))
                    .frame(height: 6)
                Rectangle()
                    .fill(accent.opacity(0.35))
                    .frame(width: width * perfectZoneFraction, height: 6)
                    .offset(x: width * (0.5 - perfectZoneFraction / 2))
                Capsule()
                    .fill(Color(.textPrimary))
                    .frame(width: 2, height: 24)
                    .offset(x: width / 2 - 1)
                Circle()
                    .fill(accent)
                    .frame(width: 16, height: 16)
                    .padding(3)
                    .background(Color(.surface), in: Circle())
                    .offset(x: width * markerPosition - 11)
            }
            .frame(width: width, height: geometry.size.height)
        }
        .frame(height: 40)
        .accessibilityHidden(true)
    }

    /// 트랙 위 점의 위치 (0 = −0.5초, 0.5 = 정각, 1 = +0.5초. 범위를 벗어나면 끝에 붙인다)
    private var markerPosition: Double {
        let ratio = min(max(difference / TimingPractice.timelineRange, -1), 1)

        return 0.5 + ratio * 0.5
    }

    private var rangeText: String {
        return PracticeNumberFormat.seconds(TimingPractice.timelineRange, fractionLength: 1)
    }
}

#Preview {
    NavigationStack {
        TimingPracticeView(
            store: Store(initialState: TimingPracticeFeature.State()) {
                TimingPracticeFeature()
            }
        )
    }
    .preferredColorScheme(.dark)
}
