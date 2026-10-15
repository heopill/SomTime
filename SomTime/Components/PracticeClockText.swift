//
//  PracticeClockText.swift
//  SomTime
//

import SwiftUI

/// 정각 클릭 연습 시계 텍스트. 사용자가 고른 디자인 · 시간 형식을 따르고 초는 항상 표시한다 (밀리초는 작게 + 투명도 75%)
struct PracticeClockText: View {
    /// 시계가 놓이는 자리별 크기
    enum Size {
        case card
        case ready
        case playing

        var placement: FontStyle.ClockPlacement {
            switch self {
            case .card: return .practiceCard
            case .ready: return .practiceReady
            case .playing: return .practicePlaying
            }
        }

        var millisecondsPlacement: FontStyle.ClockPlacement {
            switch self {
            case .card: return .practiceCardMilliseconds
            case .ready: return .practiceReadyMilliseconds
            case .playing: return .practicePlayingMilliseconds
            }
        }
    }

    let date: Date
    let settings: ClockDisplaySettings
    var showsMilliseconds = true
    let size: Size

    @Environment(\.clockAccent) private var accent

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: ClockTimeFormatter.string(
                from: date,
                isTwentyFourHour: settings.isTwentyFourHour,
                showsSeconds: true,
                showsDayPeriod: settings.showsDayPeriod,
                design: settings.design
            ))
            .fontStyle(.clock(settings.design, placement: size.placement))
            if showsMilliseconds {
                Text(verbatim: ".\(PracticeNumberFormat.milliseconds(of: date))")
                    .fontStyle(.clock(settings.design, placement: size.millisecondsPlacement))
                    .opacity(0.75)
            }
        }
        .foregroundStyle(accent)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
    }
}

#Preview {
    let settings = ClockDisplaySettings(design: .classic, color: .amber, isTwentyFourHour: true, showsSeconds: true, showsDayPeriod: true)

    VStack(spacing: 20) {
        PracticeClockText(date: TimingPractice.startDate(), settings: settings, size: .card)
        PracticeClockText(date: TimingPractice.startDate(), settings: settings, size: .ready)
        PracticeClockText(date: TimingPractice.startDate(), settings: settings, showsMilliseconds: false, size: .playing)
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.island))
}
