//
//  LiveClockText.swift
//  SomTimeWidget
//

import SwiftUI
import WidgetKit

/// 시스템이 매초 갱신하는 시계 텍스트.
/// iOS 18+는 현재 시각 Text로 12시간제 · 초 생략을 지원하고, iOS 17(또는 서버 시간 오프셋 사용 시)은 자정 기준 타이머로 24시간제 HH:mm:ss를 그린다
struct LiveClockText: View {
    let state: ClockActivityAttributes.ContentState
    let placement: FontStyle.ClockPlacement
    var alignment: Alignment = .trailing

    var body: some View {
        // 타이머 텍스트는 실제보다 넓은 폭을 차지하므로, 가장 넓은 시각 문자열로 폭을 고정한다
        Text(verbatim: widthTemplate)
            .hidden()
            .overlay(alignment: alignment) {
                liveText
                    .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
            }
            .fontStyle(.clock(state.settings.design, placement: placement))
            .foregroundStyle(state.settings.color.color)
            .lineLimit(1)
    }

    @ViewBuilder
    private var liveText: some View {
        if #available(iOS 18.0, *), state.usesSystemCurrentDate {
            Text(
                .currentDate,
                format: ClockTimeFormatter.formatStyle(
                    isTwentyFourHour: state.settings.isTwentyFourHour,
                    showsSeconds: state.settings.showsSeconds,
                    design: state.settings.design
                )
            )
        } else {
            Text(timerInterval: state.timerRange, countsDown: false, showsHours: true)
        }
    }

    private var widthTemplate: String {
        // 22:58:58 → "22:58:58" / "오후 10:58:58" / "10:58:58 PM" (숫자 폭은 monospacedDigit으로 같음)
        let sample = Calendar.current.date(bySettingHour: 22, minute: 58, second: 58, of: .now) ?? .now
        guard state.usesSystemCurrentDate else {
            return ClockTimeFormatter.string(from: sample)
        }

        return ClockTimeFormatter.string(
            from: sample,
            isTwentyFourHour: state.settings.isTwentyFourHour,
            showsSeconds: state.settings.showsSeconds,
            design: state.settings.design
        )
    }
}

/// 시 · 분 · 초 중 하나만 시스템이 갱신하도록 그리는 텍스트 (iOS 18+, 가로 모드와 Minimal용)
@available(iOS 18.0, *)
struct LiveClockComponentText: View {
    let component: ClockTimeFormatter.Component
    let isTwentyFourHour: Bool

    var body: some View {
        Text(.currentDate, format: ClockTimeFormatter.componentStyle(component, isTwentyFourHour: isTwentyFourHour))
    }
}
