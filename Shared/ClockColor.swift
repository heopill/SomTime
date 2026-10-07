//
//  ClockColor.swift
//  SomTime
//

import SwiftUI

/// 설정에서 고르는 시계 색상 (시계 숫자와 강조색으로 함께 쓰임)
enum ClockColor: String, CaseIterable, Codable {
    case white
    case amber
    case mint
    case sky
    case lavender
    case coral

    var color: Color {
        switch self {
        case .white: return Color(.clockWhite)
        case .amber: return Color(.clockAmber)
        case .mint: return Color(.clockMint)
        case .sky: return Color(.clockSky)
        case .lavender: return Color(.clockLavender)
        case .coral: return Color(.clockCoral)
        }
    }

    var nameKey: LocalizedStringKey {
        switch self {
        case .white: return "clockColorWhite"
        case .amber: return "clockColorAmber"
        case .mint: return "clockColorMint"
        case .sky: return "clockColorSky"
        case .lavender: return "clockColorLavender"
        case .coral: return "clockColorCoral"
        }
    }
}

extension EnvironmentValues {
    /// 사용자가 고른 시계 색상 (켜진 토글, 선택 테두리, 기본 버튼 배경에 쓰이는 강조색)
    @Entry var clockAccent: Color = ClockColor.amber.color
}
