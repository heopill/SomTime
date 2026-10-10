//
//  ServerTimeClient.swift
//  SomTime
//

import ComposableArchitecture
import Foundation
import OSLog

/// 사이트 서버 시각을 측정해 폰 시각 대비 오프셋을 구한다
@DependencyClient
nonisolated struct ServerTimeClient {
    /// 사이트에 반복 요청해 서버 시각 오프셋과 오차를 측정한다 (수 초 걸림)
    var measure: @Sendable (_ url: URL) async throws -> ServerTimeOffsetResult
}

/// 서버 시각 측정 결과
nonisolated struct ServerTimeOffsetResult: Equatable, Sendable {
    /// 서버 시각 - 폰 시각 (초)
    var offset: TimeInterval
    /// 오차 범위 (± 초)
    var accuracy: TimeInterval
}

nonisolated enum ServerTimeError: Error, Equatable {
    /// 사이트에 연결하지 못함
    case requestFailed
    /// 응답에 Date 헤더가 없음
    case noDateHeader
}

extension ServerTimeClient: DependencyKey {
    nonisolated static let liveValue = ServerTimeClient(
        measure: { url in
            return try await ServerTimeMeasurer(url: url).measure()
        }
    )

    nonisolated static let testValue = ServerTimeClient()
}

extension DependencyValues {
    nonisolated var serverTimeClient: ServerTimeClient {
        get { self[ServerTimeClient.self] }
        set { self[ServerTimeClient.self] = newValue }
    }
}

// MARK: - 측정

/// 응답 Date 헤더(초 단위)로 서버 시각을 맞춘다.
/// 요청마다 "응답을 만든 순간의 서버 초"가 주어지므로, 왕복 시간의 가운데에 서버가 응답했다고 보고(지연을 왕복 시간의 절반으로 보정)
/// 오프셋이 들어갈 수 있는 범위를 좁혀 간다. 초가 바뀌는 순간 근처로 요청을 보낼수록 범위가 좁아진다
private nonisolated struct ServerTimeMeasurer {
    /// 여러 위상(초 안의 위치)에 고르게 보내는 첫 요청 수와 간격
    private static let spreadSampleCount = 8
    private static let spreadInterval: Duration = .milliseconds(130)
    /// 초가 바뀌는 예상 순간을 겨냥해 보내는 요청 수
    private static let refineSampleCount = 4

    private static let logger = Logger(subsystem: "dev.seongpil.SomTime", category: "ServerTime")

    let url: URL

    /// 요청 하나의 결과 (폰 시각 기준 보낸 시각 · 받은 시각, 서버 Date 헤더의 초)
    private struct Sample {
        var sentAt: TimeInterval
        var receivedAt: TimeInterval
        var serverSecond: TimeInterval

        var midpoint: TimeInterval {
            return (sentAt + receivedAt) / 2
        }

        var roundTrip: TimeInterval {
            return receivedAt - sentAt
        }
    }

    /// 측정을 진행한다 (연결 준비 → 여러 위상 요청 → 초가 바뀌는 순간 겨냥 요청)
    func measure() async throws -> ServerTimeOffsetResult {
        let session = URLSession(configuration: Self.sessionConfiguration)
        defer { session.invalidateAndCancel() }

        // 첫 요청은 연결 · TLS 준비가 섞여 지연이 비대칭이므로 방식 확인에만 쓴다
        let method = try await probeMethod(session: session)
        var samples: [Sample] = []

        for _ in 0..<Self.spreadSampleCount {
            samples.append(try await request(session: session, method: method))
            try await Task.sleep(for: Self.spreadInterval)
        }

        for _ in 0..<Self.refineSampleCount {
            let estimate = Self.estimate(samples)
            let roundTrip = Self.medianRoundTrip(samples)
            // 다음 서버 초가 바뀌는 순간에 요청의 가운데가 오도록 보낸다
            let now = Date().timeIntervalSince1970
            var boundary = (now + estimate.offset).rounded(.up)
            if boundary - estimate.offset - roundTrip / 2 < now + 0.05 {
                boundary += 1
            }
            let sendAt = boundary - estimate.offset - roundTrip / 2
            try await Task.sleep(for: .seconds(max(0, sendAt - Date().timeIntervalSince1970)))
            samples.append(try await request(session: session, method: method))
        }

        let result = Self.estimate(samples)
        Self.logger.notice("measured offset \(result.offset, privacy: .public)s ±\(result.accuracy, privacy: .public)s with \(samples.count, privacy: .public) samples")

        return result
    }

    /// HEAD 요청으로 서버 시각을 받을 수 있는지 확인하고, 안 되면 GET을 쓴다
    private func probeMethod(session: URLSession) async throws -> String {
        do {
            _ = try await request(session: session, method: "HEAD")

            return "HEAD"
        } catch {
            Self.logger.notice("HEAD failed (\(String(describing: error), privacy: .public)), falling back to GET")
            _ = try await request(session: session, method: "GET")

            return "GET"
        }
    }

    /// 요청 하나를 보내고 응답 헤더가 도착한 순간까지의 시각과 서버 Date 헤더를 기록한다 (본문은 받지 않는다)
    private func request(session: URLSession, method: String) async throws -> Sample {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")

        let sentAt = Date().timeIntervalSince1970
        let bytes: URLSession.AsyncBytes
        let response: URLResponse
        do {
            (bytes, response) = try await session.bytes(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ServerTimeError.requestFailed
        }
        let receivedAt = Date().timeIntervalSince1970
        bytes.task.cancel()

        guard let httpResponse = response as? HTTPURLResponse,
              let dateHeader = httpResponse.value(forHTTPHeaderField: "Date"),
              let serverDate = Self.parseHTTPDate(dateHeader) else { throw ServerTimeError.noDateHeader }

        return Sample(sentAt: sentAt, receivedAt: receivedAt, serverSecond: serverDate.timeIntervalSince1970)
    }

    /// 표본들이 허용하는 오프셋 범위의 가운데와 반폭을 구한다.
    /// 응답 순간(왕복의 가운데) m의 서버 시각은 [S, S+1) 안에 있으므로 오프셋은 [S - m, S + 1 - m) 안에 있다
    private static func estimate(_ samples: [Sample]) -> ServerTimeOffsetResult {
        let lower = samples.map { $0.serverSecond - $0.midpoint }.max() ?? 0
        let upper = samples.map { $0.serverSecond + 1 - $0.midpoint }.min() ?? 1
        if lower <= upper {
            return ServerTimeOffsetResult(offset: (lower + upper) / 2, accuracy: (upper - lower) / 2)
        }

        // 지연이 고르지 않아 범위가 겹치지 않으면, 지연을 가정하지 않는 넓은 범위([S - 받은 시각, S + 1 - 보낸 시각))로 다시 구한다
        let wideLower = samples.map { $0.serverSecond - $0.receivedAt }.max() ?? 0
        let wideUpper = samples.map { $0.serverSecond + 1 - $0.sentAt }.min() ?? 1
        if wideLower <= wideUpper {
            return ServerTimeOffsetResult(offset: (wideLower + wideUpper) / 2, accuracy: (wideUpper - wideLower) / 2)
        }

        // 그래도 겹치지 않으면 각 표본 범위 가운데의 중앙값을 쓴다
        let centers = samples.map { $0.serverSecond + 0.5 - $0.midpoint }.sorted()

        return ServerTimeOffsetResult(offset: centers[centers.count / 2], accuracy: 0.5)
    }

    /// 표본 왕복 시간의 중앙값
    private static func medianRoundTrip(_ samples: [Sample]) -> TimeInterval {
        let roundTrips = samples.map(\.roundTrip).sorted()
        guard !roundTrips.isEmpty else { return 0 }

        return roundTrips[roundTrips.count / 2]
    }

    /// HTTP Date 헤더(RFC 1123, 예: Thu, 08 Oct 2026 14:05:32 GMT)를 읽는다
    private static func parseHTTPDate(_ string: String) -> Date? {
        return httpDateFormatter.date(from: string)
    }

    private static let httpDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"

        return formatter
    }()

    /// 캐시 없이 짧게 기다리는 세션 설정 (같은 연결을 재사용해 왕복 시간을 줄인다)
    private static var sessionConfiguration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 5

        return configuration
    }
}
