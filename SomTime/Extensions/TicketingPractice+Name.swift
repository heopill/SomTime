//
//  TicketingPractice+Name.swift
//  SomTime
//

import SwiftUI

// 티켓팅 연습 화면에 표시할 이름

extension SeatDifficulty {
    var nameKey: LocalizedStringKey {
        switch self {
        case .easy: return "seatDifficultyEasy"
        case .normal: return "seatDifficultyNormal"
        case .hard: return "seatDifficultyHard"
        }
    }
}

extension TimingVerdict {
    var titleKey: LocalizedStringKey {
        switch self {
        case .perfect: return "timingVerdictPerfect"
        case .great: return "timingVerdictGreat"
        case .slightlyLate: return "timingVerdictSlightlyLate"
        case .slightlyEarly: return "timingVerdictSlightlyEarly"
        case .retry: return "timingVerdictRetry"
        }
    }
}
