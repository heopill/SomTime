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

    /// 페이서를 시계 아래 줄에 두는지 여부.
    /// 창형은 남은 시간이 시계 아래 줄에 있으므로 페이서도 그 줄(남은 시간 왼쪽)에 두고, 남은 시간이 없으면 시계 줄에 둔다.
    /// 막대형은 남은 시간도 시계와 같은 줄이라 늘 시계 줄에 둔다
    func placesPacerBelowClock(hasCountdown: Bool) -> Bool {
        return self == .window && hasCountdown
    }

    /// 프레임 안에서 페이서를 그릴 자리 (pt, 왼쪽 위 기준).
    /// 시계 줄에 둘 때는 시계 왼쪽, 창형에서 남은 시간이 있으면 시계 아래 줄의 남은 시간 왼쪽
    func pacerSlotRect(hasCountdown: Bool) -> CGRect {
        let size = Self.pacerSlotSize
        guard placesPacerBelowClock(hasCountdown: hasCountdown) else {
            return CGRect(x: clockRowPacerLeading, y: (frameSize.height - size.height) / 2, width: size.width, height: size.height)
        }

        let rowsHeight = Self.windowClockRowHeight + Self.windowRowSpacing + size.height
        let y = (frameSize.height - rowsHeight) / 2 + Self.windowClockRowHeight + Self.windowRowSpacing

        return CGRect(x: Self.clockSideInset, y: y, width: size.width, height: size.height)
    }

    /// 페이서를 시계 왼쪽에 둘 때 시계 글자 앞쪽 여백
    var clockLeadingWithPacer: CGFloat {
        return pacerSlotRect(hasCountdown: false).maxX + Self.pacerSlotSpacing
    }

    /// 페이서를 시계 왼쪽에 두고 남은 시간이 없을 때 시계 글자 뒤쪽 여백.
    /// 막대형은 앞쪽과 같게 비워 시간을 창 정가운데에 둔다. 창형은 폭이 좁아 같게 비우면 글자가 너무 작아지므로 기본 여백을 둔다
    var clockTrailingWithPacer: CGFloat {
        return self == .bar ? clockLeadingWithPacer : Self.clockSideInset
    }

    /// 페이서를 시계 왼쪽에 둘 때 페이서 자리 왼쪽 여백 (창형은 폭이 좁아 조금 줄인다)
    private var clockRowPacerLeading: CGFloat {
        return self == .bar ? 10 : 8
    }
}
