//
//  ClockDisplaySettings.swift
//  SomTime
//

import Foundation

/// 시계를 그릴 때 필요한 설정 묶음 (설정 화면 값 → Live Activity, PiP에 전달)
nonisolated struct ClockDisplaySettings: Codable, Hashable {
    var design: ClockDesign
    var color: ClockColor
    var isTwentyFourHour: Bool
    var showsSeconds: Bool
}
