//
//  PipAspectRatio+PacerSlot.swift
//  SomTime
//

import CoreGraphics

// PiP 시계의 페이서 자리. SwiftUI 레이아웃(PipClockFrame)과 영상 프레임 합성(PipClockFrameRenderer)이 같은 값을 쓴다
extension PipAspectRatio {
    /// 페이서 자리 크기 (페이서 프레임과 같은 3:2 비율)
    static let pacerSlotSize = CGSize(width: 27, height: 18)
    /// 페이서 자리와 시계 글자 · 남은 시간 사이 간격
    static let pacerSlotSpacing: CGFloat = 6
    /// 시계 글자 양옆 기본 여백
    static let clockSideInset: CGFloat = 12
    /// 창형에서 페이서를 시계 아래 줄에 둘 때 시간 줄 높이와 두 줄 사이 간격 (페이서 자리 위치를 계산할 수 있게 고정한다)
    static let windowClockRowHeight: CGFloat = 22
    static let windowRowSpacing: CGFloat = 4
    /// 막대형에서 페이서 자리 왼쪽 여백
    private static let barPacerLeading: CGFloat = 10

    /// 페이서를 시계 아래 줄에 두는지 여부.
    /// 창형은 폭이 좁아 시계 왼쪽에 두면 오전/오후를 켰을 때 시간이 잘리므로 아래 줄에 둔다
    var placesPacerBelowClock: Bool {
        return self == .window
    }

    /// 프레임 안에서 페이서를 그릴 자리 (pt, 왼쪽 위 기준).
    /// 막대형은 시계 왼쪽, 창형은 시계 아래 줄 (남은 시간이 있으면 그 왼쪽, 없으면 가운데)
    func pacerSlotRect(hasCountdown: Bool) -> CGRect {
        let size = Self.pacerSlotSize
        guard placesPacerBelowClock else {
            return CGRect(x: Self.barPacerLeading, y: (frameSize.height - size.height) / 2, width: size.width, height: size.height)
        }

        let rowsHeight = Self.windowClockRowHeight + Self.windowRowSpacing + size.height
        let x = hasCountdown ? Self.clockSideInset : (frameSize.width - size.width) / 2
        let y = (frameSize.height - rowsHeight) / 2 + Self.windowClockRowHeight + Self.windowRowSpacing

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    /// 페이서를 시계 왼쪽에 둘 때(막대형) 시계 글자 앞쪽 여백
    var clockLeadingWithPacer: CGFloat {
        return pacerSlotRect(hasCountdown: false).maxX + Self.pacerSlotSpacing
    }
}
