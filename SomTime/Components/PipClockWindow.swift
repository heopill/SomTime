//
//  PipClockWindow.swift
//  SomTime
//

import SwiftUI

/// PiP 시계 창 (island 배경). 홈 · 페이서 상점 미리보기에서 쓰는 테두리 있는 창 모양.
/// 남은 시간 없이 시계만 보여 주므로, 페이서가 있으면 창 비율과 상관없이 시계 왼쪽에서 달리게 한다
struct PipClockWindow: View {
    let time: String
    var milliseconds: String?
    let design: ClockDesign
    var aspectRatio: PipAspectRatio = ClockSettingsStorage.DefaultValue.pipAspectRatio
    var pacer: PipPacer = .off

    var body: some View {
        content
            .frame(width: aspectRatio.frameSize.width, height: aspectRatio.frameSize.height)
            .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.input))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.input)
                    .strokeBorder(Color(.borderStrong), lineWidth: 1)
            }
    }

    /// 페이서 유무와 창 비율에 맞춘 시간 · 페이서 배치
    @ViewBuilder
    private var content: some View {
        let clock = PipClockText(time: time, milliseconds: milliseconds, design: design)
        if pacer == .off {
            clock
                .padding(.horizontal, PipAspectRatio.clockSideInset)
        } else {
            // 페이서는 시계 왼쪽 자리에서 달린다. 막대형은 시간을 창 가운데에, 창형은 페이서 오른쪽 나머지 폭의 가운데에 둔다
            let slot = aspectRatio.pacerSlotRect(hasCountdown: false)
            clock
                .padding(.leading, aspectRatio.clockLeadingWithPacer)
                .padding(.trailing, aspectRatio.clockTrailingWithPacer)
                .frame(width: aspectRatio.frameSize.width, height: aspectRatio.frameSize.height)
                .overlay(alignment: .topLeading) {
                    PipPacerView(pacer: pacer)
                        .frame(width: slot.width, height: slot.height)
                        .offset(x: slot.minX, y: slot.minY)
                }
        }
    }
}

/// 창형 PiP에서 남은 시간이 있을 때 페이서를 시계 아래 줄에 두는 배치. 첫 줄은 시간, 둘째 줄은 페이서와 남은 시간이다.
/// 남은 시간은 페이서 자리 오른쪽 나머지 폭의 가운데에 둔다.
/// 줄 높이를 고정해 페이서 자리가 pacerSlotRect(hasCountdown:)와 같은 위치에 오게 한다
private struct PipClockOverPacerRow<Pacer: View>: View {
    let clock: PipClockText
    let countdown: PipCountdownText
    let pacer: Pacer

    var body: some View {
        VStack(spacing: PipAspectRatio.windowRowSpacing) {
            clock
                .frame(height: PipAspectRatio.windowClockRowHeight)
            HStack(spacing: PipAspectRatio.pacerSlotSpacing) {
                pacer
                    .frame(width: PipAspectRatio.pacerSlotSize.width, height: PipAspectRatio.pacerSlotSize.height)
                countdown
                    .frame(maxWidth: .infinity)
            }
            .frame(height: PipAspectRatio.pacerSlotSize.height)
        }
        .padding(.horizontal, PipAspectRatio.clockSideInset)
    }
}

/// 목표 시각 직전 PiP 시계 강조 상태
enum PipClockEmphasis {
    /// 평소
    case none
    /// 목표 시각 10초 전부터: 시계와 남은 시간을 경고색으로
    case warning
    /// 마지막 3초 깜빡임 중 흐린 순간 (경고색 + 투명도)
    case warningDimmed
}

/// 실제 PiP 창에 영상 프레임으로 그리는 시계 화면 (검정 배경 + 가운데 시간. 모서리는 시스템 PiP 창이 둥글게 자른다).
/// PiP 창 모양은 프레임 비율을 따른다. 남은 시간은 막대형이면 시간 오른쪽, 창형이면 시간 아래에 둔다.
/// 강조 중이면 경고색은 그리는 쪽이 clockAccent로 넣어 주고, 남은 시간도 같은 색으로 그린다.
/// 페이서는 그리는 쪽이 프레임마다 덧그리므로, 여기서는 자리만 비워 둔다.
/// 시계 모드는 시계 왼쪽을 비우고(막대형은 오른쪽도 같게 비워 시간을 가운데에 둔다),
/// 카운트다운 모드는 남은 시간과 같은 줄을 비운다 (막대형은 시계 왼쪽, 창형은 시계 아래 줄의 남은 시간 왼쪽)
struct PipClockFrame: View {
    let time: String
    var milliseconds: String?
    var countdown: String?
    var emphasis: PipClockEmphasis = .none
    let design: ClockDesign
    let aspectRatio: PipAspectRatio
    var reservesPacerSlot = false

    var body: some View {
        layout
            .opacity(emphasis == .warningDimmed ? 0.35 : 1)
            .frame(width: aspectRatio.frameSize.width, height: aspectRatio.frameSize.height)
            .background(Color(.island))
    }

    /// 페이서 자리와 창 비율에 맞춘 시간 · 남은 시간 배치
    @ViewBuilder
    private var layout: some View {
        if reservesPacerSlot && aspectRatio.placesPacerBelowClock(hasCountdown: countdown != nil), let countdownText {
            PipClockOverPacerRow(clock: clock, countdown: countdownText, pacer: Color.clear)
        } else {
            content
                .padding(.leading, reservesPacerSlot ? aspectRatio.clockLeadingWithPacer : PipAspectRatio.clockSideInset)
                // 남은 시간이 없는 일반 시계는 페이서 반대쪽도 비워 둔다 (막대형은 시간이 창 정가운데에 온다)
                .padding(.trailing, reservesPacerSlot && countdown == nil ? aspectRatio.clockTrailingWithPacer : PipAspectRatio.clockSideInset)
        }
    }

    /// 남은 시간이 있으면 창 비율에 맞춰 시간과 함께 배치한다
    @ViewBuilder
    private var content: some View {
        if let countdownText {
            switch aspectRatio {
            case .bar:
                // 남은 시간은 글자가 작아 기준선에 맞추면 아래로 처져 보이므로 시간 높이의 가운데에 맞춘다
                HStack(alignment: .center, spacing: 10) {
                    clock
                    countdownText
                }
            case .window:
                VStack(spacing: 2) {
                    clock
                    countdownText
                }
            }
        } else {
            clock
        }
    }

    private var clock: PipClockText {
        return PipClockText(time: time, milliseconds: milliseconds, design: design)
    }

    private var countdownText: PipCountdownText? {
        return countdown.map { PipCountdownText(countdown: $0, design: design, isEmphasized: emphasis != .none) }
    }
}

/// PiP 시계 아래 · 옆의 목표 시각까지 남은 시간 (깃발 아이콘 + 4:27, 밀리초와 같은 크기).
/// 평소에는 textSecondary, 목표 시각 직전에는 시계와 같은 경고색
private struct PipCountdownText: View {
    let countdown: String
    let design: ClockDesign
    var isEmphasized = false

    @Environment(\.clockAccent) private var accent

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            Image(systemName: "flag.checkered")
                .font(.system(size: 9, weight: .semibold))
            Text(verbatim: countdown)
                .fontStyle(.clock(design, placement: .pipMilliseconds))
        }
        .foregroundStyle(isEmphasized ? accent : Color(.textSecondary))
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

/// PiP 시계 시간 텍스트. 밀리초가 있으면 작게(약 2/3) + 투명도 75%로 붙인다.
/// 시간과 밀리초를 한 Text로 이어 붙여, 폭이 모자라면 둘이 함께 줄어든다 (따로 두면 시간만 줄다가 가운데가 "…"로 잘린다).
/// 창형에서 페이서를 시계 왼쪽에 두면 폭이 좁아, 오전/오후 · 밀리초를 함께 켜도 잘리지 않게 0.4배까지 줄인다
struct PipClockText: View {
    let time: String
    var milliseconds: String?
    let design: ClockDesign

    @Environment(\.clockAccent) private var accent

    var body: some View {
        Text(styledTime)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }

    /// 시간(큰 글자) 뒤에 밀리초(작은 글자, 투명도 75%)를 붙인 문자열
    private var styledTime: AttributedString {
        var text = styled(time, style: .clock(design, placement: .pip), color: accent)
        if let milliseconds {
            text += styled(".\(milliseconds)", style: .clock(design, placement: .pipMilliseconds), color: accent.opacity(0.75))
        }

        return text
    }

    /// FontStyle의 폰트 · 자간과 색을 입힌 문자열을 만든다
    private func styled(_ string: String, style: FontStyle, color: Color) -> AttributedString {
        var text = AttributedString(string)
        text.font = style.font
        text.tracking = style.tracking
        text.foregroundColor = color

        return text
    }
}

#Preview {
    VStack(spacing: Spacing.card) {
        PipClockWindow(time: "14:05:32", design: .classic)
        PipClockWindow(time: "14:05:32", milliseconds: "418", design: .classic)
        PipClockWindow(time: "14:05:32", design: .dot)
            .environment(\.clockAccent, ClockColor.mint.color)
        PipClockWindow(time: "14:05:32", design: .classic, aspectRatio: .window)
        PipClockWindow(time: "14:05:32", design: .classic, pacer: .jogger)
        PipClockWindow(time: "14:05:32", design: .classic, aspectRatio: .window, pacer: .fox)
        PipClockFrame(time: "14:05:32", design: .bold, aspectRatio: .bar)
        PipClockFrame(time: "19:55:32", milliseconds: "418", countdown: "4:27", design: .classic, aspectRatio: .bar, reservesPacerSlot: true)
        PipClockFrame(time: "19:55:32", milliseconds: "418", countdown: "4:27", design: .classic, aspectRatio: .bar)
        PipClockFrame(time: "19:55:32", milliseconds: "418", countdown: "4:27", design: .classic, aspectRatio: .window)
        PipClockFrame(time: "PM 11:40:05", milliseconds: "621", countdown: "4:59:15", design: .bold, aspectRatio: .window, reservesPacerSlot: true)
        PipClockFrame(time: "11:40:05 PM", milliseconds: "621", design: .mono, aspectRatio: .window, reservesPacerSlot: true)
        PipClockFrame(time: "19:59:52", milliseconds: "418", countdown: "0:08", emphasis: .warning, design: .classic, aspectRatio: .bar)
            .environment(\.clockAccent, Color(.warning))
        PipClockFrame(time: "19:59:58", milliseconds: "418", countdown: "0:02", emphasis: .warningDimmed, design: .classic, aspectRatio: .window)
            .environment(\.clockAccent, Color(.warning))
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
