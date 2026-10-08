//
//  DeviceCapability.swift
//  SomTime
//

import UIKit

/// 기기 기능 확인
enum DeviceCapability {
    /// 다이나믹 아일랜드가 있는 iPhone인지 여부.
    /// 공식 API가 없어 Safe Area로 판단한다 (다이나믹 아일랜드 기기는 상단 · 가로 측면 inset이 51pt 이상, 노치 기기는 47pt 이하)
    static var hasDynamicIsland: Bool {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return false }

        let window = UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.keyWindow }
            .first
        guard let insets = window?.safeAreaInsets else { return false }

        return max(insets.top, insets.left, insets.right) >= 51
    }
}
