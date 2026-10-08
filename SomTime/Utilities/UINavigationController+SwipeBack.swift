//
//  UINavigationController+SwipeBack.swift
//  SomTime
//

import UIKit

// 내비게이션 바를 숨기고 커스텀 헤더를 쓰는 화면에서도 왼쪽 가장자리 스와이프로 뒤로 갈 수 있게 한다
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    /// 루트 화면이 아닐 때만 뒤로 스와이프 제스처를 시작한다
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
