//
//  PipAspectRatio.swift
//  SomTime
//

import CoreGraphics

/// 설정에서 고르는 PiP 시계 창 비율.
/// 시스템은 PiP 창 높이에 최소값을 두고 프레임 비율대로 폭을 정한다
nonisolated enum PipAspectRatio: String, CaseIterable, Codable {
    /// 10:1 막대형. 폭이 화면 폭 근처에서 막혀 높이가 낮아지므로, 영상을 거의 가리지 않는 얇은 띠가 된다
    case bar
    /// 2:1 창형. 모서리에 두는 작은 창
    case window

    /// PiP에 그리는 시계 프레임 크기 (pt)
    var frameSize: CGSize {
        switch self {
        case .bar: return CGSize(width: 220, height: 22)
        case .window: return CGSize(width: 120, height: 60)
        }
    }
}
