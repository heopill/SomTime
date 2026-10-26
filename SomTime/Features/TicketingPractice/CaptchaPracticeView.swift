//
//  CaptchaPracticeView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

struct CaptchaPracticeView: View {
    @Bindable var store: StoreOf<CaptchaPracticeFeature>

    @FocusState private var isInputFocused: Bool
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
        case let .playing(round):
            playingContent(round)
        case let .result(result):
            resultContent(result)
        }
    }

    // MARK: - 난이도 선택

    private var readyContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            ScreenHeader(title: "captchaPractice") {
                store.send(.backButtonTapped)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    previewSection
                    difficultySection
                    recordsSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            PrimaryButton(title: "startPractice") {
                store.send(.startButtonTapped)
            }
        }
    }

    /// 선택한 난이도의 보안 문자 예시 + 안내
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            CaptchaImage(challenge: Self.sample(for: store.difficulty))
                .frame(maxWidth: 280)
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.card))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.card)
                        .strokeBorder(Color(.border), lineWidth: 1)
                }
                .accessibilityHidden(true)

            let letters = Text("captchaSixLetters")
                .fontWeight(.semibold)
                .foregroundStyle(Color(.textPrimary))

            Text("captchaPracticeGuide \(letters)")
                .fontStyle(.detail)
                .foregroundStyle(Color(.textSecondary))
                .padding(.horizontal, 4)
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("seatDifficultySection")
            HStack(spacing: 10) {
                ForEach(CaptchaDifficulty.allCases, id: \.self) { difficulty in
                    DifficultyButton(
                        name: difficulty.nameKey,
                        value: Text(difficulty.styleKey),
                        detail: Text(difficulty.focusKey),
                        isSelected: difficulty == store.difficulty
                    ) {
                        store.send(.difficultySelected(difficulty))
                    }
                }
            }
        }
    }

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("myBestRecords")
            RecordList(rows: CaptchaDifficulty.allCases.map { difficulty in
                RecordList.Row(difficulty.nameKey, value: store.records.bestTime(for: difficulty).map(durationText))
            })
        }
    }

    // MARK: - 진행 중

    /// 진행 중 화면 (걸린 시간, 보안 문자 카드, 입력 완료). 키보드에 가리지 않도록 위에 모은다
    private func playingContent(_ round: CaptchaPracticeRound) -> some View {
        return VStack(spacing: 16) {
            TimelineView(.animation) { context in
                playingTopBar(difficulty: round.difficulty, elapsed: context.date.timeIntervalSince(round.startedAt))
            }
            captchaCard(round)
                .modifier(ShakeEffect(animatableData: CGFloat(round.wrongCount)))
                .animation(.linear(duration: 0.4), value: round.wrongCount)
                .sensoryFeedback(.error, trigger: round.wrongCount)
            PrimaryButton(title: "captchaSubmit") {
                store.send(.submitButtonTapped)
            }
            .disabled(round.input.count < CaptchaPractice.length)
            .opacity(round.input.count < CaptchaPractice.length ? 0.4 : 1)
            Spacer(minLength: 0)
        }
        .onAppear {
            isInputFocused = true
        }
    }

    /// 그만하기 · 난이도 칩 · 걸린 시간
    private func playingTopBar(difficulty: CaptchaDifficulty, elapsed: TimeInterval) -> some View {
        return HStack(spacing: 10) {
            IconButton(systemImage: "xmark", accessibilityLabel: "stopPractice") {
                store.send(.stopButtonTapped)
            }
            Chip(text: Text(difficulty.nameKey), style: .surface)
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: PracticeNumberFormat.seconds(max(0, elapsed), fractionLength: 2))
                    .fontStyle(.practiceTimer)
                Text("secondsUnit")
                    .fontStyle(.practiceTimerUnit)
            }
            .foregroundStyle(accent)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("elapsedTime"))
        }
    }

    /// 보안 문자 그림 + 새로고침 + 입력창 + 틀렸을 때 안내
    private func captchaCard(_ round: CaptchaPracticeRound) -> some View {
        return VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("captchaInputTitle")
                    .fontStyle(.cardTitle)
                    .foregroundStyle(Color(.textPrimary))
                Text("captchaInputDescription")
                    .fontStyle(.detail)
                    .foregroundStyle(Color(.textSecondary))
            }
            HStack(spacing: 10) {
                CaptchaImage(challenge: round.challenge)
                Button {
                    store.send(.refreshButtonTapped)
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(.textPrimary))
                        .frame(width: Spacing.minTouchTarget, height: Spacing.minTouchTarget)
                        .background(Color(.surfaceRaised), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("captchaRefresh"))
            }
            TextField(
                text: Binding(
                    get: { round.input },
                    set: { store.send(.inputChanged($0)) }
                ),
                prompt: Text("captchaInputPlaceholder").foregroundStyle(Color(.placeholder))
            ) {
                Text("captchaInputTitle")
            }
            .font(FontStyle.cardTitle.font)
            .tracking(round.input.isEmpty ? 0 : 4)
            .foregroundStyle(Color(.textPrimary))
            .keyboardType(.asciiCapable)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .focused($isInputFocused)
            .onSubmit {
                store.send(.submitButtonTapped)
                // 틀려서 새 문자가 나오면 바로 이어서 입력할 수 있게 키보드를 유지한다
                isInputFocused = true
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(Color(.background), in: RoundedRectangle(cornerRadius: CornerRadius.input))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.input)
                    .strokeBorder(Color(.borderStrong), lineWidth: 1)
            }
            if round.showsWrongAnswer {
                Text("captchaWrongAnswer")
                    .fontStyle(.caption)
                    .foregroundStyle(Color(.clockCoral))
            }
        }
        .padding(Spacing.cardPadding)
        .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    // MARK: - 결과

    /// 통과 화면
    private func resultContent(_ result: CaptchaPracticeResult) -> some View {
        return VStack(alignment: .leading, spacing: 22) {
            ScreenHeader(title: "captchaPractice") {
                store.send(.backButtonTapped)
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    resultHero(result)
                    RecordList(rows: [
                        RecordList.Row("elapsedTime", value: durationText(result.totalTime)),
                        RecordList.Row("captchaWrongCount", value: Text("practiceCountValue \(result.wrongCount)")),
                        RecordList.Row("captchaRefreshCount", value: Text("practiceCountValue \(result.refreshCount)")),
                        RecordList.Row(
                            title: Text("bestRecordFor \(Text(result.difficulty.nameKey))"),
                            value: store.records.bestTime(for: result.difficulty).map(durationText)
                        )
                    ])
                }
            }
            .scrollBounceBehavior(.basedOnSize)
            HStack(spacing: 10) {
                PrimaryButton(title: "changeDifficulty", style: .neutral) {
                    store.send(.changeDifficultyButtonTapped)
                }
                .frame(width: 128)
                PrimaryButton(title: "tryAgain") {
                    store.send(.startButtonTapped)
                }
            }
        }
    }

    /// 결과 아이콘 + 제목 + 걸린 시간 + 난이도 · 최고 기록 칩
    private func resultHero(_ result: CaptchaPracticeResult) -> some View {
        return VStack(spacing: 10) {
            ResultIcon(isSuccess: true)
            Text("captchaPassed")
                .fontStyle(.screenTitle)
                .foregroundStyle(Color(.textPrimary))
                .padding(.top, 6)
            Text("captchaPassedIn \(emphasized(durationText(result.totalTime)))")
                .fontStyle(.rowLabel)
                .foregroundStyle(Color(.textSecondary))
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Chip(text: Text(result.difficulty.nameKey))
                if result.isNewBest {
                    Chip("newBestRecord", style: .accent)
                }
            }
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
    }

    // MARK: - 공통

    /// 난이도 선택 화면에 보여 줄 보안 문자 예시 (고정)
    private static func sample(for difficulty: CaptchaDifficulty) -> CaptchaChallenge {
        switch difficulty {
        case .easy: return CaptchaChallenge(text: "KTRMBA", seed: 11, difficulty: .easy)
        case .normal: return CaptchaChallenge(text: "XQHFNW", seed: 23, difficulty: .normal)
        case .hard: return CaptchaChallenge(text: "QOVYJW", seed: 37, difficulty: .hard)
        }
    }

    /// 걸린 시간 (예: 2.84초)
    private func durationText(_ seconds: TimeInterval) -> Text {
        return Text("durationSeconds \(PracticeNumberFormat.seconds(seconds, fractionLength: 2))")
    }

    /// 문장 속 강조 부분 (textPrimary, SemiBold)
    private func emphasized(_ text: Text) -> Text {
        return text
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

/// 틀렸을 때 카드를 좌우로 두 번 흔든다 (틀린 횟수가 바뀔 때마다 0 → 1로 움직인다)
private struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    /// 흔들림 위치를 계산한다
    func effectValue(size: CGSize) -> ProjectionTransform {
        return ProjectionTransform(CGAffineTransform(translationX: 8 * sin(animatableData * .pi * 4), y: 0))
    }
}

#Preview {
    NavigationStack {
        CaptchaPracticeView(
            store: Store(initialState: CaptchaPracticeFeature.State()) {
                CaptchaPracticeFeature()
            }
        )
    }
    .preferredColorScheme(.dark)
}
