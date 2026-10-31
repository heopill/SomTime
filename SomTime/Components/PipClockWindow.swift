//
//  PipClockWindow.swift
//  SomTime
//

import SwiftUI

/// PiP 시계 창 (island 배경). 홈 · 페이서 상점 미리보기에서 쓰는 테두리 있는 창 모양.
/// 페이서가 있으면 왼쪽 자리에서 달리게 한다
struct PipClockWindow: View {
    let time: String
    var milliseconds: String?
    let design: ClockDesign
    var aspectRatio: PipAspectRatio = ClockSettingsStorage.DefaultValue.pipAspectRatio
    var pacer: PipPacer = .off

    var body: some View {
        PipClockText(time: time, milliseconds: milliseconds, design: design)
            .padding(.leading, pacer == .off ? PipAspectRatio.clockSideInset : aspectRatio.clockLeadingWithPacer)
            .padding(.trailing, pacer == .off ? PipAspectRatio.clockSideInset : aspectRatio.centeredClockTrailingWithPacer)
            .frame(width: aspectRatio.frameSize.width, height: aspectRatio.frameSize.height)
            .overlay(alignment: .topLeading) {
                PipPacerSlot(pacer: pacer, aspectRatio: aspectRatio)
            }
            .background(Color(.island), in: RoundedRectangle(cornerRadius: CornerRadius.input))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.input)
                    .strokeBorder(Color(.borderStrong), lineWidth: 1)
            }
    }
}

/// PiP 시계 왼쪽 페이서 자리 (페이서 없음이면 아무것도 그리지 않는다)
private struct PipPacerSlot: View {
    let pacer: PipPacer
    let aspectRatio: PipAspectRatio

    var body: some View {
        if pacer != .off {
            let slot = aspectRatio.pacerSlotRect
            PipPacerView(pacer: pacer)
                .frame(width: slot.width, height: slot.height)
                .offset(x: slot.minX, y: slot.minY)
        }
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
/// 페이서는 그리는 쪽이 프레임마다 덧그리므로, 여기서는 왼쪽 자리만 비워 둔다 (남은 시간이 없는 막대형은 오른쪽도 같게 비워 시간을 가운데에 둔다)
struct PipClockFrame: View {
    let time: String
    var milliseconds: String?
    var countdown: String?
    var emphasis: PipClockEmphasis = .none
    let design: ClockDesign
    let aspectRatio: PipAspectRatio
    var reservesPacerSlot = false

    var body: some View {
        content
            .opacity(emphasis == .warningDimmed ? 0.35 : 1)
            .padding(.leading, reservesPacerSlot ? aspectRatio.clockLeadingWithPacer : PipAspectRatio.clockSideInset)
            // 남은 시간이 없는 일반 시계는 오른쪽도 비워 시간을 창 정가운데에 둔다
            .padding(.trailing, reservesPacerSlot && countdown == nil ? aspectRatio.centeredClockTrailingWithPacer : PipAspectRatio.clockSideInset)
            .frame(width: aspectRatio.frameSize.width, height: aspectRatio.frameSize.height)
            .background(Color(.island))
    }

    /// 남은 시간이 있으면 창 비율에 맞춰 시간과 함께 배치한다
    @ViewBuilder
    private var content: some View {
        let clock = PipClockText(time: time, milliseconds: milliseconds, design: design)
        if let countdown {
            switch aspectRatio {
            case .bar:
                // 남은 시간은 글자가 작아 기준선에 맞추면 아래로 처져 보이므로 시간 높이의 가운데에 맞춘다
                HStack(alignment: .center, spacing: 10) {
                    clock
                    PipCountdownText(countdown: countdown, design: design, isEmphasized: emphasis != .none)
                }
            case .window:
                VStack(spacing: 2) {
                    clock
                    PipCountdownText(countdown: countdown, design: design, isEmphasized: emphasis != .none)
                }
            }
        } else {
            clock
        }
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

/// PiP 시계 시간 텍스트. 밀리초가 있으면 작게(약 2/3) + 투명도 75%로 붙인다
struct PipClockText: View {
    let time: String
    var milliseconds: String?
    let design: ClockDesign

    @Environment(\.clockAccent) private var accent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: time)
                .fontStyle(.clock(design, placement: .pip))
            if let milliseconds {
                Text(verbatim: ".\(milliseconds)")
                    .fontStyle(.clock(design, placement: .pipMilliseconds))
                    .opacity(0.75)
            }
        }
        .foregroundStyle(accent)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
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
        PipClockFrame(time: "19:59:52", milliseconds: "418", countdown: "0:08", emphasis: .warning, design: .classic, aspectRatio: .bar)
            .environment(\.clockAccent, Color(.warning))
        PipClockFrame(time: "19:59:58", milliseconds: "418", countdown: "0:02", emphasis: .warningDimmed, design: .classic, aspectRatio: .window)
            .environment(\.clockAccent, Color(.warning))
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
