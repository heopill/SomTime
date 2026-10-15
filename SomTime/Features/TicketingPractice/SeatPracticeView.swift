//
//  SeatPracticeView.swift
//  SomTime
//

import ComposableArchitecture
import SwiftUI

struct SeatPracticeView: View {
    @Bindable var store: StoreOf<SeatPracticeFeature>

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
            ScreenHeader(title: "seatPractice") {
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

    /// 선택한 난이도만큼 포도알이 보이는 작은 배치도 + 안내
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 14) {
                StageLabel(width: 160, height: 22)
                MiniSeatGrid(columns: 16, rows: 6, availableIndices: previewSeatIndices(for: store.difficulty))
            }
            .padding(.top, 18)
            .padding(.bottom, 20)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.card))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.card)
                    .strokeBorder(Color(.border), lineWidth: 1)
            }
            .accessibilityHidden(true)
            .animation(.easeInOut(duration: 0.2), value: store.difficulty)

            let purpleSeat = Text("purpleSeat")
                .fontWeight(.semibold)
                .foregroundStyle(Color(.seatAvailable))
            let timeLimit = Text("secondsLimit \(Int(store.difficulty.timeLimit))")
                .fontWeight(.semibold)
                .foregroundStyle(Color(.textPrimary))

            Text("seatPracticeGuide \(purpleSeat) \(timeLimit)")
                .fontStyle(.detail)
                .foregroundStyle(Color(.textSecondary))
                .padding(.horizontal, 4)
        }
    }

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("seatDifficultySection")
            HStack(spacing: 10) {
                ForEach(SeatDifficulty.allCases, id: \.self) { difficulty in
                    let range = difficulty.availableSeatRange

                    DifficultyButton(
                        name: difficulty.nameKey,
                        timeLimit: Text("secondsLimit \(Int(difficulty.timeLimit))"),
                        seatRange: Text("availableSeatRange \(range.lowerBound) \(range.upperBound)"),
                        isSelected: difficulty == store.difficulty
                    ) {
                        store.send(.difficultySelected(difficulty))
                    }
                }
            }
            Toggle(
                isOn: Binding(
                    get: { store.seatsVanish },
                    set: { store.send(.seatsVanishChanged($0)) }
                )
            ) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("seatVanishOption")
                        .fontStyle(.rowLabel)
                        .foregroundStyle(Color(.textPrimary))
                    Text("seatVanishDescription")
                        .fontStyle(.caption)
                        .foregroundStyle(Color(.textSecondary))
                }
            }
            .toggleStyle(.accent)
            .padding(.leading, Spacing.cardPadding)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 60)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.control))
        }
    }

    private var recordsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("myBestRecords")
            RecordList(rows: SeatDifficulty.allCases.map { difficulty in
                RecordList.Row(difficulty.nameKey, value: store.records.bestTime(for: difficulty).map(durationText))
            })
        }
    }

    /// 난이도 선택 화면 미리보기에서 보라색으로 칠할 칸 (장식용 고정 위치)
    private func previewSeatIndices(for difficulty: SeatDifficulty) -> Set<Int> {
        switch difficulty {
        case .easy: return [3, 9, 14, 20, 27, 33, 41, 46, 52, 60, 66, 75, 83, 90]
        case .normal: return [9, 27, 46, 66, 83, 90]
        case .hard: return [46, 83]
        }
    }

    // MARK: - 진행 중

    /// 진행 중 화면 (남은 시간, 좌석 배치도, 선택한 좌석, 예매하기)
    private func playingContent(_ round: SeatPracticeRound) -> some View {
        return VStack(spacing: 14) {
            TimelineView(.animation) { context in
                let remaining = max(0, round.difficulty.timeLimit - context.date.timeIntervalSince(round.startedAt))

                VStack(spacing: 14) {
                    playingTopBar(difficulty: round.difficulty, remaining: remaining)
                    RemainingTimeBar(
                        fraction: remaining / round.difficulty.timeLimit,
                        color: remaining <= 1 ? Color(.clockCoral) : accent
                    )
                }
            }
            SeatMapCard(availableSeats: round.availableSeats, selectedSeat: round.selectedSeat) { seat in
                store.send(.seatTapped(seat))
            }
            .padding(.top, 6)
            SeatLegend()
            Spacer(minLength: 0)
            SelectedSeatCard(seat: round.selectedSeat, isTaken: round.isSelectedSeatTaken)
            PrimaryButton(title: "book") {
                store.send(.bookButtonTapped)
            }
            .disabled(round.selectedSeat == nil)
            .opacity(round.selectedSeat == nil ? 0.4 : 1)
        }
    }

    /// 그만하기 · 난이도 칩 · 남은 시간
    private func playingTopBar(difficulty: SeatDifficulty, remaining: TimeInterval) -> some View {
        return HStack(spacing: 10) {
            IconButton(systemImage: "xmark", accessibilityLabel: "stopPractice") {
                store.send(.stopButtonTapped)
            }
            Chip(text: difficultyChipText(difficulty), style: .surface)
            Spacer(minLength: 8)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: PracticeNumberFormat.seconds(remaining, fractionLength: 2))
                    .fontStyle(.practiceTimer)
                Text("secondsUnit")
                    .fontStyle(.practiceTimerUnit)
            }
            .foregroundStyle(remaining <= 1 ? Color(.clockCoral) : accent)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text("remainingTime"))
        }
    }

    // MARK: - 결과

    /// 성공 · 시간 초과 화면
    private func resultContent(_ result: SeatPracticeResult) -> some View {
        return VStack(alignment: .leading, spacing: 22) {
            ScreenHeader(title: "seatPractice") {
                store.send(.backButtonTapped)
            }
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    resultHero(result)
                    breakdownCard(result)
                    if result.isSuccess {
                        RecordList(rows: [
                            RecordList.Row("selectedSeat", value: result.seat.map(seatPositionText)),
                            RecordList.Row(
                                title: Text("bestRecordFor \(Text(result.difficulty.nameKey))"),
                                value: store.records.bestTime(for: result.difficulty).map(durationText)
                            )
                        ])
                    } else {
                        TipCard()
                    }
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

    /// 결과 아이콘 + 제목 + 설명 + 난이도 · 최고 기록 칩
    private func resultHero(_ result: SeatPracticeResult) -> some View {
        return VStack(spacing: 10) {
            ResultIcon(isSuccess: result.isSuccess)
            Text(result.isSuccess ? "bookingSuccess" : "timeOver")
                .fontStyle(.screenTitle)
                .foregroundStyle(Color(.textPrimary))
                .padding(.top, 6)
            Group {
                if let totalTime = result.totalTime {
                    Text("bookedIn \(emphasized(durationText(totalTime)))")
                } else {
                    Text("timeOverDescription \(emphasized(Text("secondsLimit \(Int(result.difficulty.timeLimit))")))")
                }
            }
            .fontStyle(.rowLabel)
            .foregroundStyle(Color(.textSecondary))
            .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Chip(text: difficultyChipText(result.difficulty))
                if result.isNewBest {
                    Chip("newBestRecord", style: .accent)
                }
            }
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity)
    }

    /// 걸린 시간 카드 (머리 + 구간 막대)
    private func breakdownCard(_ result: SeatPracticeResult) -> some View {
        let limit = result.difficulty.timeLimit

        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("elapsedTime")
                    .foregroundStyle(Color(.textSecondary))
                Spacer(minLength: 8)
                if let totalTime = result.totalTime {
                    let total = Text(verbatim: PracticeNumberFormat.seconds(totalTime, fractionLength: 2))
                        .foregroundStyle(Color(.textPrimary))

                    Text("elapsedOfLimit \(total) \(Int(limit))")
                        .monospacedDigit()
                        .foregroundStyle(Color(.textSecondary))
                } else {
                    Text("timeOver")
                        .foregroundStyle(Color(.clockCoral))
                }
            }
            .fontStyle(.sectionTitle)
            TimeBreakdownBar(segments: breakdownSegments(result))
        }
        .padding(Spacing.cardPadding)
        .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.card))
    }

    /// 걸린 시간 구간 (성공: 좌석 선택 · 예매하기까지 · 남은 시간 / 시간 초과: 좌석 선택 · 누르지 못함)
    private func breakdownSegments(_ result: SeatPracticeResult) -> [TimeBreakdownBar.Segment] {
        let limit = result.difficulty.timeLimit

        guard let selectionTime = result.seatSelectionTime,
              let bookingTime = result.bookingTime,
              let totalTime = result.totalTime else {
            let selectionFraction = (result.seatSelectionTime ?? 0) / limit

            return [
                TimeBreakdownBar.Segment(
                    title: "seatSelectionTime",
                    value: result.seatSelectionTime.map(durationText) ?? Text("seatNotSelected"),
                    color: accent,
                    fraction: selectionFraction
                ),
                TimeBreakdownBar.Segment(
                    title: "bookingTime",
                    value: Text("bookNotPressed").foregroundStyle(Color(.clockCoral)),
                    color: Color(.clockCoral).opacity(0.35),
                    fraction: 1 - selectionFraction
                )
            ]
        }

        return [
            TimeBreakdownBar.Segment(title: "seatSelectionTime", value: durationText(selectionTime), color: accent, fraction: selectionTime / limit),
            TimeBreakdownBar.Segment(title: "bookingTime", value: durationText(bookingTime), color: accent.opacity(0.55), fraction: bookingTime / limit),
            TimeBreakdownBar.Segment(
                title: "remainingTime",
                value: durationText(max(0, limit - totalTime)),
                color: Color(.toggleOff),
                fraction: max(0, limit - totalTime) / limit
            )
        ]
    }

    // MARK: - 공통

    /// "보통 · 6초"
    private func difficultyChipText(_ difficulty: SeatDifficulty) -> Text {
        return Text("difficultyWithLimit \(Text(difficulty.nameKey)) \(Int(difficulty.timeLimit))")
    }

    /// 걸린 시간 (예: 2.84초)
    private func durationText(_ seconds: TimeInterval) -> Text {
        return Text("durationSeconds \(PracticeNumberFormat.seconds(seconds, fractionLength: 2))")
    }

    /// "B구역 5열 6번"
    private func seatPositionText(_ seat: SeatID) -> Text {
        return Text("seatPosition \(seat.section.rawValue) \(seat.row) \(seat.number)")
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

/// 좌석 배치도 위쪽의 무대 표시
private struct StageLabel: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Text("stage")
            .fontStyle(.stageLabel)
            .foregroundStyle(Color(.textSecondary))
            .frame(width: width, height: height)
            .background(Color(.surface), in: RoundedRectangle(cornerRadius: 6))
    }
}

/// 남은 시간 비율만큼 채운 진행 막대 (높이 6)
private struct RemainingTimeBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            Capsule()
                .fill(color)
                .frame(width: geometry.size.width * min(max(fraction, 0), 1))
        }
        .frame(height: 6)
        .background(Color(.surfaceRaised), in: Capsule())
        .accessibilityHidden(true)
    }
}

/// 좌석 배치도 카드 (STAGE + A · B · C구역). 좁은 기기에서는 좌석 크기를 줄여 카드 폭에 맞춘다
private struct SeatMapCard: View {
    let availableSeats: Set<SeatID>
    let selectedSeat: SeatID?
    let onSeatTapped: (SeatID) -> Void

    @State private var seatSize = SeatButton.defaultSize

    private static let horizontalPadding: CGFloat = 15
    private static let aisleWidth: CGFloat = 12

    var body: some View {
        VStack(spacing: 14) {
            StageLabel(width: 200, height: 26)
            HStack(alignment: .top, spacing: Self.aisleWidth) {
                ForEach(SeatSection.allCases, id: \.self) { section in
                    VStack(spacing: 6) {
                        Text("seatSection \(section.rawValue)")
                            .fontStyle(.caption)
                            .foregroundStyle(Color(.textSecondary))
                        seats(in: section)
                    }
                }
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 18)
        .padding(.horizontal, Self.horizontalPadding)
        .frame(maxWidth: .infinity)
        .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.card))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.card)
                .strokeBorder(Color(.border), lineWidth: 1)
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            seatSize = Self.seatSize(fitting: width)
        }
    }

    /// 한 구역의 좌석 격자를 만든다
    private func seats(in section: SeatSection) -> some View {
        return VStack(spacing: SeatButton.spacing) {
            ForEach(1...SeatSection.rowCount, id: \.self) { row in
                HStack(spacing: SeatButton.spacing) {
                    ForEach(1...section.columnCount, id: \.self) { number in
                        let seat = SeatID(section: section, row: row, number: number)

                        SeatButton(
                            status: status(of: seat),
                            size: seatSize,
                            accessibilityLabel: Text("seatPosition \(section.rawValue) \(row) \(number)")
                        ) {
                            onSeatTapped(seat)
                        }
                    }
                }
            }
        }
    }

    /// 좌석의 표시 상태 (선택됨 / 선택 가능 / 판매 완료)
    private func status(of seat: SeatID) -> SeatButton.Status {
        if seat == selectedSeat {
            return .selected
        }

        return availableSeats.contains(seat) ? .available : .sold
    }

    /// 카드 폭에 들어가는 좌석 크기 (기본 16pt를 넘지 않는다)
    private static func seatSize(fitting cardWidth: CGFloat) -> CGFloat {
        let sections = SeatSection.allCases
        let columnCount = CGFloat(sections.reduce(0) { $0 + $1.columnCount })
        let gaps = CGFloat(sections.reduce(0) { $0 + $1.columnCount - 1 }) * SeatButton.spacing
        let aisles = CGFloat(sections.count - 1) * aisleWidth
        let available = cardWidth - horizontalPadding * 2 - gaps - aisles

        return min(SeatButton.defaultSize, (available / columnCount).rounded(.down))
    }
}

/// 좌석 색 범례 (선택 가능 / 선택됨 / 판매 완료)
private struct SeatLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            item(color: Color(.seatAvailable), title: "seatAvailableLegend")
            item(color: Color(.textPrimary), title: "seatSelectedLegend")
            item(color: Color(.seatSold), title: "seatSoldLegend", isOutlined: true)
        }
        .fontStyle(.caption)
        .foregroundStyle(Color(.textSecondary))
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    /// 색 칸 + 이름 한 쌍을 만든다
    private func item(color: Color, title: LocalizedStringKey, isOutlined: Bool = false) -> some View {
        return HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay {
                    if isOutlined {
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(Color(.toggleOff), lineWidth: 1)
                    }
                }
                .accessibilityHidden(true)
            Text(title)
        }
    }
}

/// 선택한 좌석 카드 (선택 전에는 안내 문구, 고른 좌석을 뺏기면 다시 고르라는 안내)
private struct SelectedSeatCard: View {
    let seat: SeatID?
    let isTaken: Bool

    var body: some View {
        HStack(spacing: 12) {
            if let seat {
                VStack(alignment: .leading, spacing: 1) {
                    Text("selectedSeat")
                        .fontStyle(.caption)
                        .foregroundStyle(Color(.textSecondary))
                    Text("seatPosition \(seat.section.rawValue) \(seat.row) \(seat.number)")
                        .fontStyle(.rowLabel)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.textPrimary))
                }
                Spacer(minLength: 0)
                Text("seatCount \(1)")
                    .fontStyle(.detail)
                    .foregroundStyle(Color(.textSecondary))
            } else if isTaken {
                VStack(alignment: .leading, spacing: 1) {
                    Text("seatTakenTitle")
                        .fontStyle(.rowLabel)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.clockCoral))
                    Text("seatTakenGuide")
                        .fontStyle(.caption)
                        .foregroundStyle(Color(.textSecondary))
                }
                Spacer(minLength: 0)
            } else {
                Text("selectSeatGuide")
                    .fontStyle(.rowLabel)
                    .foregroundStyle(Color(.textSecondary))
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, Spacing.cardPadding)
        .frame(minHeight: 60)
        .background(Color(.surface), in: RoundedRectangle(cornerRadius: CornerRadius.summaryRow))
        .accessibilityElement(children: .combine)
    }
}

/// 시간 초과 화면의 팁 카드
private struct TipCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color(.textSecondary))
                .accessibilityHidden(true)
            Text("seatPracticeTip \(Text("seatPracticeTipEmphasis").foregroundStyle(Color(.textPrimary)))")
                .fontStyle(.summary)
                .foregroundStyle(Color(.textSecondary))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, Spacing.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.surfaceSubtle), in: RoundedRectangle(cornerRadius: CornerRadius.summaryRow))
    }
}

#Preview {
    NavigationStack {
        SeatPracticeView(
            store: Store(initialState: SeatPracticeFeature.State()) {
                SeatPracticeFeature()
            }
        )
    }
    .preferredColorScheme(.dark)
}
