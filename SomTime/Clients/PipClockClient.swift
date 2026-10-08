//
//  PipClockClient.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

/// PiP 플로팅 시계를 시작 · 업데이트 · 종료한다
@DependencyClient
nonisolated struct PipClockClient {
    /// PiP 시계를 켜고 창이 뜰 때까지 기다린다 (켜진 동안 앱이 백그라운드로 가면 자동으로 다시 뜬다)
    var start: @Sendable (_ settings: ClockDisplaySettings, _ aspectRatio: PipAspectRatio) async throws -> Void
    /// 떠 있는 PiP 시계의 표시 설정과 창 비율을 바꾼다
    var update: @Sendable (_ settings: ClockDisplaySettings, _ aspectRatio: PipAspectRatio) async -> Void
    /// PiP 시계를 끈다
    var stop: @Sendable () async -> Void
    /// 사용자나 시스템이 PiP 창을 닫는 이벤트
    var events: @Sendable () async -> AsyncStream<PipClockEvent> = { .finished }
}

extension PipClockClient: DependencyKey {
    nonisolated static let liveValue = PipClockClient(
        start: { settings, aspectRatio in
            try await PipClockController.shared.start(settings, aspectRatio: aspectRatio)
        },
        update: { settings, aspectRatio in
            await PipClockController.shared.update(settings, aspectRatio: aspectRatio)
        },
        stop: {
            await PipClockController.shared.stop()
        },
        events: {
            return await PipClockController.shared.events()
        }
    )

    nonisolated static let testValue = PipClockClient()
}

extension DependencyValues {
    nonisolated var pipClockClient: PipClockClient {
        get { self[PipClockClient.self] }
        set { self[PipClockClient.self] = newValue }
    }
}
