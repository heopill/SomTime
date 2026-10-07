//
//  ClockDesign.swift
//  SomTime
//

import SwiftUI

/// 설정에서 고르는 시계 디자인
enum ClockDesign: String, CaseIterable, Codable {
    /// 기본 (Pretendard Medium)
    case classic
    /// 모노 (SF Mono)
    case mono
    /// 굵게 (Pretendard Bold, 자간 -4%)
    case bold
    /// 도트 (Doto Black)
    case dot

    var nameKey: LocalizedStringKey {
        switch self {
        case .classic: return "clockDesignClassic"
        case .mono: return "clockDesignMono"
        case .bold: return "clockDesignBold"
        case .dot: return "clockDesignDot"
        }
    }
}
