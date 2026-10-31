//
//  PipAspectRatio+PacerSlot.swift
//  SomTime
//

import CoreGraphics

// PiP 시계 왼쪽의 페이서 자리. SwiftUI 레이아웃(PipClockFrame)과 영상 프레임 합성(PipClockFrameRenderer)이 같은 값을 쓴다
extension PipAspectRatio {
    /// 페이서 자리 크기 (페이서 프레임과 같은 3:2 비율)
    static let pacerSlotSize = CGSize(width: 27, height: 18)
    /// 페이서 자리와 시계 글자 사이 간격
    static let pacerSlotSpacing: CGFloat = 6

    /// 프레임 안에서 페이서를 그릴 자리 (pt, 왼쪽 위 기준)
    var pacerSlotRect: CGRect {
        let size = Self.pacerSlotSize
        let leading: CGFloat = self == .bar ? 10 : 8

        return CGRect(x: leading, y: (frameSize.height - size.height) / 2, width: size.width, height: size.height)
    }

    /// 페이서가 없을 때 시계 글자 양옆 여백
    static let clockSideInset: CGFloat = 12

    /// 페이서가 있을 때 시계 글자 앞쪽 여백
    var clockLeadingWithPacer: CGFloat {
        return pacerSlotRect.maxX + Self.pacerSlotSpacing
    }

    /// 페이서가 있고 남은 시간이 없을 때 시계 글자 뒤쪽 여백.
    /// 막대형은 앞쪽과 같게 비워 시간을 창 정가운데에 둔다. 창형은 폭이 좁아 같게 비우면 글자가 너무 작아지므로 기본 여백을 둔다
    var centeredClockTrailingWithPacer: CGFloat {
        return self == .bar ? clockLeadingWithPacer : Self.clockSideInset
    }
}
