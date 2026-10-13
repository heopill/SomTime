//
//  TicketingPracticeSharedKeys.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

// 티켓팅 연습 기록과 옵션 (위젯과 공유하지 않으므로 앱 전용 저장소에 저장)

extension SharedKey where Self == AppStorageKey<Bool>.Default {
    /// 홈의 티켓팅 연습 타일을 눌러 본 적이 있는지 여부 (NEW 배지 숨김)
    static var hasOpenedTicketingPractice: Self {
        Self[.appStorage("hasOpenedTicketingPractice"), default: false]
    }

    /// 정각 클릭 연습 시계에 밀리초를 표시할지 여부
    static var timingPracticeShowsMilliseconds: Self {
        Self[.appStorage("timingPracticeShowsMilliseconds"), default: true]
    }

    /// 포도알 클릭 연습에서 빈 좌석이 하나씩 사라지게 할지 여부
    static var seatPracticeSeatsVanish: Self {
        Self[.appStorage("seatPracticeSeatsVanish"), default: true]
    }
}

extension SharedKey where Self == AppStorageKey<SeatDifficulty>.Default {
    /// 포도알 클릭 연습에서 마지막으로 고른 난이도
    static var seatPracticeDifficulty: Self {
        Self[.appStorage("seatPracticeDifficulty"), default: .normal]
    }
}

extension SharedKey where Self == FileStorageKey<TimingPracticeRecords>.Default {
    /// 정각 클릭 연습 기록
    static var timingPracticeRecords: Self {
        Self[.fileStorage(.applicationSupportDirectory.appending(component: "timingPracticeRecords.json")), default: TimingPracticeRecords()]
    }
}

extension SharedKey where Self == FileStorageKey<SeatPracticeRecords>.Default {
    /// 포도알 클릭 연습 난이도별 최고 기록
    static var seatPracticeRecords: Self {
        Self[.fileStorage(.applicationSupportDirectory.appending(component: "seatPracticeRecords.json")), default: SeatPracticeRecords()]
    }
}
