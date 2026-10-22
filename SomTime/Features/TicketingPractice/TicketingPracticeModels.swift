//
//  TicketingPracticeModels.swift
//  SomTime
//

import Foundation

// MARK: - 정각 클릭 연습

/// 정각 클릭 연습의 시각 기준 (연습 시계는 09:59:50부터 흐르고 10:00:00 정각에 누른다)
nonisolated enum TimingPractice {
    /// 연습 시계가 시작하는 시각부터 정각까지의 시간 (초)
    static let leadTime: TimeInterval = 10
    /// 정각이 지나도 누르지 않으면 자동으로 끝내기까지의 시간 (초)
    static let missTimeout: TimeInterval = 5
    /// 결과 타임라인이 보여 주는 한쪽 범위 (±초)
    static let timelineRange: TimeInterval = 0.5
    /// 최근 평균에 쓰는 기록 수
    static let recentCount = 10

    /// 오늘 10:00:00 (연습 시계의 목표 시각)
    static func targetDate(now: Date = Date(), calendar: Calendar = .current) -> Date {
        return calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now
    }

    /// 연습 시계가 시작하는 시각 (오늘 09:59:50)
    static func startDate(now: Date = Date(), calendar: Calendar = .current) -> Date {
        return targetDate(now: now, calendar: calendar).addingTimeInterval(-leadTime)
    }
}

/// 정각 클릭 연습 한 번의 결과
nonisolated enum TimingPracticeOutcome: Equatable, Sendable {
    /// 예매하기를 누름 (정각과의 차이: 늦으면 +, 빠르면 −)
    case pressed(difference: TimeInterval)
    /// 자동 종료 시각까지 누르지 않음
    case missed
}

/// 정각과의 차이에 따른 판정
nonisolated enum TimingVerdict: Equatable, Sendable {
    /// ±0.05초 이내
    case perfect
    /// ±0.15초 이내
    case great
    /// +0.5초 이내로 늦음
    case slightlyLate
    /// −0.5초 이내로 빠름
    case slightlyEarly
    /// 그 이상
    case retry

    /// 정각과의 차이(늦으면 +, 빠르면 −)로 판정한다
    init(difference: TimeInterval) {
        let magnitude = abs(difference)
        if magnitude <= 0.05 {
            self = .perfect
        } else if magnitude <= 0.15 {
            self = .great
        } else if magnitude <= TimingPractice.timelineRange {
            self = difference > 0 ? .slightlyLate : .slightlyEarly
        } else {
            self = .retry
        }
    }
}

/// 정각 클릭 연습 기록
nonisolated struct TimingPracticeRecords: Codable, Equatable, Sendable {
    /// 최근 기록의 정각과의 차이 (오래된 순, 최대 10개)
    var recentDifferences: [TimeInterval] = []
    /// 정각과 가장 가까웠던 차이의 크기
    var bestMagnitude: TimeInterval?
    var practiceCount = 0

    /// 가장 최근 기록
    var latestDifference: TimeInterval? {
        return recentDifferences.last
    }

    /// 최근 기록들의 차이 크기 평균
    var recentAverageMagnitude: TimeInterval? {
        guard !recentDifferences.isEmpty else { return nil }

        let total = recentDifferences.reduce(0) { $0 + abs($1) }

        return total / Double(recentDifferences.count)
    }

    /// 새 기록을 더한다
    mutating func add(_ difference: TimeInterval) {
        recentDifferences.append(difference)
        if recentDifferences.count > TimingPractice.recentCount {
            recentDifferences.removeFirst(recentDifferences.count - TimingPractice.recentCount)
        }
        bestMagnitude = min(bestMagnitude ?? .infinity, abs(difference))
        practiceCount += 1
    }
}

// MARK: - 포도알 클릭 연습

/// 포도알 클릭 연습 난이도
nonisolated enum SeatDifficulty: String, CaseIterable, Codable, Sendable {
    case easy
    case normal
    case hard

    /// 제한 시간 (초)
    var timeLimit: TimeInterval {
        switch self {
        case .easy: return 5
        case .normal: return 3
        case .hard: return 2
        }
    }

    /// 한 판에 뜨는 빈 좌석 수
    var availableSeatRange: ClosedRange<Int> {
        switch self {
        case .easy: return 10...15
        case .normal: return 4...8
        case .hard: return 1...3
        }
    }
}

/// 좌석 배치도의 구역 (A · B · C, 각 14줄)
nonisolated enum SeatSection: String, CaseIterable, Sendable {
    case a = "A"
    case b = "B"
    case c = "C"

    static let rowCount = 14

    /// 한 줄의 좌석 수
    var columnCount: Int {
        switch self {
        case .a, .c: return 4
        case .b: return 8
        }
    }
}

/// 좌석 하나의 위치
nonisolated struct SeatID: Hashable, Sendable {
    var section: SeatSection
    /// 열 (1부터)
    var row: Int
    /// 번호 (1부터)
    var number: Int

    /// 배치도의 모든 좌석
    static let all: [SeatID] = SeatSection.allCases.flatMap { section in
        (1...SeatSection.rowCount).flatMap { row in
            (1...section.columnCount).map { number in
                SeatID(section: section, row: row, number: number)
            }
        }
    }
}

/// 진행 중인 포도알 연습 한 판
nonisolated struct SeatPracticeRound: Equatable, Sendable {
    var difficulty: SeatDifficulty
    var availableSeats: Set<SeatID>
    var startedAt: Date
    var selectedSeat: SeatID?
    /// 마지막으로 좌석을 고른 시각
    var selectedAt: Date?
    /// 고른 좌석을 다른 사람이 먼저 잡아가 선택이 풀렸는지 여부 (다른 좌석을 고르면 해제)
    var isSelectedSeatTaken = false
}

/// 다른 사람이 좌석을 먼저 잡아가는 순간 (좌석 사라짐)
nonisolated struct SeatTaking: Equatable, Sendable {
    /// 시작부터의 시간 (초)
    var time: TimeInterval
    var seat: SeatID
}

/// 좌석 사라짐 일정
nonisolated enum SeatTakingSchedule {
    /// 좌석이 사라지기 시작하는 시점 (제한 시간 대비). 시작하자마자 사라지지 않도록 유예를 둔다
    static let startRatio = 0.15
    /// 좌석이 사라지는 마지막 시점 (제한 시간 대비)
    static let endRatio = 0.85

    /// 빈 좌석 중 하나만 끝까지 남기고, 나머지가 무작위 순서 · 시각에 사라지는 일정을 만든다
    static func make<Generator: RandomNumberGenerator>(
        seats: Set<SeatID>,
        timeLimit: TimeInterval,
        using generator: inout Generator
    ) -> [SeatTaking] {
        let takenSeats = Array(seats).shuffled(using: &generator).dropLast()
        let range = (timeLimit * startRatio)...(timeLimit * endRatio)
        let times = takenSeats.map { _ in Double.random(in: range, using: &generator) }.sorted()

        return zip(times, takenSeats).map { SeatTaking(time: $0, seat: $1) }
    }
}

/// 포도알 연습 한 판의 결과
nonisolated struct SeatPracticeResult: Equatable, Sendable {
    var difficulty: SeatDifficulty
    var seat: SeatID?
    /// 시작부터 마지막으로 좌석을 고른 순간까지 (좌석을 못 골랐으면 nil)
    var seatSelectionTime: TimeInterval?
    /// 좌석을 고른 순간부터 예매하기를 누른 순간까지 (시간 초과면 nil)
    var bookingTime: TimeInterval?
    /// 이번 기록이 난이도 최고 기록인지 여부
    var isNewBest = false

    var isSuccess: Bool {
        return bookingTime != nil
    }

    /// 예매까지 걸린 전체 시간 (성공일 때만)
    var totalTime: TimeInterval? {
        guard let seatSelectionTime, let bookingTime else { return nil }

        return seatSelectionTime + bookingTime
    }
}

/// 포도알 연습 난이도별 최고 기록
nonisolated struct SeatPracticeRecords: Codable, Equatable, Sendable {
    private var bestTimes: [String: TimeInterval] = [:]

    /// 난이도의 최고 기록 (예매까지 걸린 시간)
    func bestTime(for difficulty: SeatDifficulty) -> TimeInterval? {
        return bestTimes[difficulty.rawValue]
    }

    /// 기록이 최고 기록보다 빠르면 저장하고, 최고 기록인지 돌려준다
    mutating func record(_ time: TimeInterval, for difficulty: SeatDifficulty) -> Bool {
        if let best = bestTime(for: difficulty), best <= time {
            return false
        }
        bestTimes[difficulty.rawValue] = time

        return true
    }
}

// MARK: - 보안 문자 입력 연습

/// 보안 문자 입력 연습 규칙 (영문 대문자 6자리, 대소문자 구분 없이 입력)
nonisolated enum CaptchaPractice {
    /// 보안 문자 길이
    static let length = 6
    /// 보안 문자에 쓰는 글자
    static let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    /// 기울이거나 겹치면 헷갈리는 글자 (어려움에서 자주 나온다)
    static let confusableLetters = Array("OQDCGVYWIJLEFPRMNUH")

    /// 입력한 글자를 대문자로 바꾸고, 영문이 아닌 글자를 빼고, 6자리까지만 남긴다
    static func sanitized(_ input: String) -> String {
        return String(input.uppercased().filter { letters.contains($0) }.prefix(length))
    }
}

/// 보안 문자 입력 연습 난이도 (글자를 비트는 정도)
nonisolated enum CaptchaDifficulty: String, CaseIterable, Codable, Sendable {
    case easy
    case normal
    case hard

    /// 헷갈리는 글자를 고를 비율
    var confusableRatio: Double {
        switch self {
        case .easy, .normal: return 0
        case .hard: return 0.5
        }
    }
}

/// 화면에 띄운 보안 문자 하나 (seed가 같으면 같은 모양으로 그린다)
nonisolated struct CaptchaChallenge: Equatable, Sendable {
    var text: String
    var seed: UInt64
    var difficulty: CaptchaDifficulty

    /// 난이도에 맞는 무작위 보안 문자를 만든다
    static func random<Generator: RandomNumberGenerator>(
        difficulty: CaptchaDifficulty,
        using generator: inout Generator
    ) -> CaptchaChallenge {
        let letters = (0..<CaptchaPractice.length).map { _ in
            let pool = Double.random(in: 0..<1, using: &generator) < difficulty.confusableRatio
                ? CaptchaPractice.confusableLetters
                : CaptchaPractice.letters

            return pool.randomElement(using: &generator) ?? "A"
        }

        return CaptchaChallenge(text: String(letters), seed: generator.next(), difficulty: difficulty)
    }
}

/// 진행 중인 보안 문자 연습 한 판
nonisolated struct CaptchaPracticeRound: Equatable, Sendable {
    var difficulty: CaptchaDifficulty
    var challenge: CaptchaChallenge
    /// 처음 보안 문자가 뜬 시각 (틀리거나 새로고침해도 이어서 잰다)
    var startedAt: Date
    var input = ""
    var wrongCount = 0
    var refreshCount = 0
    /// 방금 틀려서 새 문자로 바뀌었다는 안내를 보여 줄지 여부 (다시 입력하기 시작하면 숨긴다)
    var showsWrongAnswer = false
}

/// 보안 문자 연습 한 판의 결과
nonisolated struct CaptchaPracticeResult: Equatable, Sendable {
    var difficulty: CaptchaDifficulty
    /// 처음 보안 문자가 뜬 순간부터 통과할 때까지 걸린 시간
    var totalTime: TimeInterval
    var wrongCount: Int
    var refreshCount: Int
    /// 이번 기록이 난이도 최고 기록인지 여부
    var isNewBest = false
}

/// 보안 문자 연습 난이도별 최고 기록
nonisolated struct CaptchaPracticeRecords: Codable, Equatable, Sendable {
    private var bestTimes: [String: TimeInterval] = [:]

    /// 난이도의 최고 기록 (통과까지 걸린 시간)
    func bestTime(for difficulty: CaptchaDifficulty) -> TimeInterval? {
        return bestTimes[difficulty.rawValue]
    }

    /// 기록이 최고 기록보다 빠르면 저장하고, 최고 기록인지 돌려준다
    mutating func record(_ time: TimeInterval, for difficulty: CaptchaDifficulty) -> Bool {
        if let best = bestTime(for: difficulty), best <= time {
            return false
        }
        bestTimes[difficulty.rawValue] = time

        return true
    }
}

// MARK: - 표시 형식

/// 연습 기록 숫자 형식
nonisolated enum PracticeNumberFormat {
    /// 소수 자리를 고정한 초 숫자 (예: 0.087)
    static func seconds(_ value: TimeInterval, fractionLength: Int = 3) -> String {
        return value.formatted(.number.precision(.fractionLength(fractionLength)))
    }

    /// 부호를 붙인 초 숫자 (예: +0.087, −0.120)
    static func signedSeconds(_ value: TimeInterval) -> String {
        let sign = value < 0 ? "\u{2212}" : "+"

        return sign + seconds(abs(value))
    }

    /// 시각의 밀리초 세 자리 (예: 087)
    static func milliseconds(of date: Date) -> String {
        let milliseconds = Int((date.timeIntervalSince1970 * 1000).rounded(.down)) % 1000

        return String(format: "%03d", milliseconds)
    }
}
