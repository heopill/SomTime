//
//  ClockColor+Name.swift
//  SomTime
//

import SwiftUI

// 화면에 표시할 이름 (앱 전용: 위젯 확장은 이름을 쓰지 않으므로 Shared에 두지 않는다)
extension ClockColor {
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
