//
//  PipPacerSpeed.swift
//  SomTime
//

import Foundation

/// 목표 시각까지 남은 시간에 따른 페이서 애니메이션 속도 (한 바퀴 8프레임 기준 초당 프레임 수)
nonisolated enum PipPacerSpeed {
    /// 목표 시각이 없거나 5분 넘게 남았을 때
    static let calmFramesPerSecond: Double = 8
    /// 목표 시각 10초 전 직전까지 빨라지는 최대 속도
    static let hurryFramesPerSecond: Double = 12
    /// 목표 시각 10초 전부터 (경고색 구간)
    static let sprintFramesPerSecond: Double = 16
    /// 빨라지기 시작하는 남은 시간
    private static let hurryStart: TimeInterval = 5 * 60
    /// 전력 질주하는 남은 시간
    private static let sprintStart: TimeInterval = 10

    /// 남은 시간에 맞는 초당 프레임 수 (목표 시각이 없거나 지났으면 nil을 넘긴다)
    static func framesPerSecond(remaining: TimeInterval?) -> Double {
        guard let remaining, remaining <= hurryStart else { return calmFramesPerSecond }
        guard remaining > sprintStart else { return sprintFramesPerSecond }

        // 5분 → 10초 사이를 로그 비율로 나눠, 목표에 가까워질수록 빨라지는 폭이 커지게 한다
        let progress = 1 - log(remaining / sprintStart) / log(hurryStart / sprintStart)

        return calmFramesPerSecond + (hurryFramesPerSecond - calmFramesPerSecond) * progress
    }
}
