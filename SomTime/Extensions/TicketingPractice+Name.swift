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

extension CaptchaDifficulty {
    var nameKey: LocalizedStringKey {
        switch self {
        case .easy: return "seatDifficultyEasy"
        case .normal: return "seatDifficultyNormal"
        case .hard: return "seatDifficultyHard"
        }
    }

    /// 난이도 버튼의 큰 글자 (글자 모양)
    var styleKey: LocalizedStringKey {
        switch self {
        case .easy: return "captchaStyleEasy"
        case .normal: return "captchaStyleNormal"
        case .hard: return "captchaStyleHard"
        }
    }

    /// 난이도 버튼의 설명 (무엇을 연습하는지)
    var focusKey: LocalizedStringKey {
        switch self {
        case .easy: return "captchaFocusEasy"
        case .normal: return "captchaFocusNormal"
        case .hard: return "captchaFocusHard"
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
