//
//  TicketingPracticeView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

struct TicketingPracticeView: View {
    @Bindable var store: StoreOf<TicketingPracticeFeature>

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ScreenHeader(title: "ticketingPractice") {
                store.send(.backButtonTapped)
            }
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Text("ticketingPracticeGuide")
                        .fontStyle(.summary)
                        .foregroundStyle(Color(.textSecondary))
                    timingCard
                    seatCard
                    captchaCard
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
            Text("practiceRecordsNotice")
                .fontStyle(.caption)
                .foregroundStyle(Color(.textSecondary))
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AdBannerSlot(placement: .ticketingPractice)
        }
        .background(Color(.background))
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(
            item: $store.scope(state: \.destination?.timing, action: \.destination.timing)
        ) { timingStore in
            TimingPracticeView(store: timingStore)
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.seat, action: \.destination.seat)
        ) { seatStore in
            SeatPracticeView(store: seatStore)
        }
        .navigationDestination(
            item: $store.scope(state: \.destination?.captcha, action: \.destination.captcha)
        ) { captchaStore in
            CaptchaPracticeView(store: captchaStore)
        }
    }

    /// 정각 클릭 연습 카드 (미리보기 시계 + 최고 · 최근 기록)
    private var timingCard: some View {
        PracticeModeCard(
            systemImage: "stopwatch",
            title: "timingPractice",
            subtitle: "timingPracticeSubtitle"
        ) {
            store.send(.timingPracticeTapped)
        } preview: {
            HStack(spacing: 12) {
                PracticeClockText(
                    date: TimingPractice.targetDate().addingTimeInterval(-1.584),
                    settings: store.clockSettings,
                    size: .card
                )
                Spacer(minLength: 0)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("practiceTarget")
                        .fontStyle(.caption)
                        .foregroundStyle(Color(.textSecondary))
                    Text(verbatim: targetTimeText)
                        .fontStyle(.secondaryButton)
                        .monospacedDigit()
                        .foregroundStyle(Color(.textPrimary))
                }
            }
            .padding(.horizontal, 18)
        } records: {
            HStack(spacing: 8) {
                recordItem("bestRecord", value: store.timingRecords.bestMagnitude.map {
                    Text("durationSeconds \(PracticeNumberFormat.seconds($0))")
                })
                RecordSeparator()
                recordItem("latestRecord", value: store.timingRecords.latestDifference.map {
                    Text("durationSeconds \(PracticeNumberFormat.signedSeconds($0))")
                })
            }
        }
    }

    /// 포도알 클릭 연습 카드 (작은 좌석 격자 + 난이도별 최고 기록)
    private var seatCard: some View {
        PracticeModeCard(
            systemImage: "square.grid.2x2",
            title: "seatPractice",
            subtitle: "seatPracticeSubtitle"
        ) {
            store.send(.seatPracticeTapped)
        } preview: {
            MiniSeatGrid(
                columns: 20,
                rows: 3,
                availableIndices: [6, 23, 31, 48, 57],
                cellSize: 10.5,
                spacing: 3,
                cornerRadius: 2.5
            )
        } records: {
            HStack(spacing: 8) {
                ForEach(Array(SeatDifficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                    if index > 0 {
                        RecordSeparator()
                    }
                    recordItem(difficulty.nameKey, value: store.seatRecords.bestTime(for: difficulty).map {
                        Text("durationSeconds \(PracticeNumberFormat.seconds($0, fractionLength: 2))")
                    })
                }
            }
        }
    }

    /// 보안 문자 입력 연습 카드 (보안 문자 예시 + 난이도별 최고 기록)
    private var captchaCard: some View {
        PracticeModeCard(
            systemImage: "character.textbox",
            title: "captchaPractice",
            subtitle: "captchaPracticeSubtitle"
        ) {
            store.send(.captchaPracticeTapped)
        } preview: {
            CaptchaImage(challenge: CaptchaChallenge(text: "XQHFNW", seed: 23, difficulty: .normal))
                .frame(height: 52)
        } records: {
            HStack(spacing: 8) {
                ForEach(Array(CaptchaDifficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                    if index > 0 {
                        RecordSeparator()
                    }
                    recordItem(difficulty.nameKey, value: store.captchaRecords.bestTime(for: difficulty).map {
                        Text("durationSeconds \(PracticeNumberFormat.seconds($0, fractionLength: 2))")
                    })
                }
            }
        }
    }

    /// 연습 시계의 목표 시각 (사용자의 시간 형식)
    private var targetTimeText: String {
        return ClockTimeFormatter.string(
            from: TimingPractice.targetDate(),
            isTwentyFourHour: store.isTwentyFourHour,
            showsSeconds: true,
            showsDayPeriod: store.showsDayPeriod,
            design: store.clockDesign
        )
    }

    /// 기록 줄의 "이름 값" 한 칸을 만든다 (기록이 없으면 "기록 없음")
    private func recordItem(_ title: LocalizedStringKey, value: Text?) -> some View {
        return HStack(spacing: 4) {
            Text(title)
            (value ?? Text("noRecord"))
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(Color(.textPrimary))
        }
    }
}

/// 기록 줄의 칸 사이 구분선
private struct RecordSeparator: View {
    var body: some View {
        Rectangle()
            .fill(Color(.toggleOff))
            .frame(width: 1, height: 12)
    }
}

#Preview {
    NavigationStack {
        TicketingPracticeView(
            store: Store(initialState: TicketingPracticeFeature.State()) {
                TicketingPracticeFeature()
            }
        )
    }
    .preferredColorScheme(.dark)
}
