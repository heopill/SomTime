//
//  ClockColor.swift
//  SomTime
//

import SwiftUI

/// 설정에서 고르는 시계 색상 (시계 숫자와 강조색으로 함께 쓰임)
nonisolated enum ClockColor: String, CaseIterable, Codable {
    case white
    case amber
    case mint
    case sky
    case lavender
    case coral

    @MainActor var color: Color {
        switch self {
        case .white: return Color(.clockWhite)
        case .amber: return Color(.clockAmber)
        case .mint: return Color(.clockMint)
        case .sky: return Color(.clockSky)
        case .lavender: return Color(.clockLavender)
        case .coral: return Color(.clockCoral)
        }
    }
}

extension EnvironmentValues {
    /// 사용자가 고른 시계 색상 (켜진 토글, 선택 테두리, 기본 버튼 배경에 쓰이는 강조색)
    // 기본값은 메인 액터 밖에서 만들어지므로 생성된 심볼 대신 에셋 이름으로 만든다 (= ClockColor.amber.color)
    @Entry var clockAccent: Color = Color("ClockAmber")
}
