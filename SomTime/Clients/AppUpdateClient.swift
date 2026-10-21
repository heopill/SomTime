//
//  AppUpdateClient.swift
//  SomTime
//

import ComposableArchitecture
import Foundation
import OSLog

/// 앱스토어에 올라온 새 버전 정보
nonisolated struct AppUpdate: Equatable, Sendable {
    /// 앱스토어 최신 버전 (예: 26.3.0)
    var version: String
    /// 앱스토어의 앱 페이지
    var storeURL: URL
}

/// 앱스토어 최신 버전을 확인해 지금 설치된 버전과 비교한다
@DependencyClient
nonisolated struct AppUpdateClient {
    /// 설치된 버전보다 새 버전이 있고 이 기기의 iOS에서 받을 수 있으면 그 정보를 돌려준다 (없거나 확인하지 못하면 nil)
    var availableUpdate: @Sendable () async -> AppUpdate?
}

extension AppUpdateClient: DependencyKey {
    nonisolated static let liveValue = AppUpdateClient(
        availableUpdate: {
            return await AppStoreVersionChecker().availableUpdate()
        }
    )

    nonisolated static let testValue = AppUpdateClient()
}

extension DependencyValues {
    nonisolated var appUpdateClient: AppUpdateClient {
        get { self[AppUpdateClient.self] }
        set { self[AppUpdateClient.self] = newValue }
    }
}

// MARK: - 확인

/// iTunes Lookup API로 앱스토어 최신 버전과 최소 iOS 버전을 받아 비교한다
private nonisolated struct AppStoreVersionChecker {
    private static let logger = Logger(subsystem: "dev.seongpil.SomTime", category: "AppUpdate")

    /// Lookup API 응답 (필요한 값만 읽는다)
    private struct LookupResponse: Decodable {
        var results: [Result]

        struct Result: Decodable {
            var version: String
            var minimumOsVersion: String?
            var trackViewUrl: URL
        }
    }

    /// 앱스토어 최신 버전이 설치된 버전보다 높고, 이 기기의 iOS가 최소 버전 이상이면 업데이트 정보를 돌려준다
    func availableUpdate() async -> AppUpdate? {
        guard let bundleID = Bundle.main.bundleIdentifier,
              let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              let release = await fetchRelease(bundleID: bundleID) else { return nil }

        guard Self.isVersion(currentVersion, olderThan: release.version) else { return nil }

        // 새 버전이 요구하는 iOS보다 낮은 기기는 업데이트를 받을 수 없으므로 알리지 않는다
        if let minimumOSVersion = release.minimumOsVersion,
           Self.isVersion(Self.currentOSVersion, olderThan: minimumOSVersion) {
            return nil
        }

        Self.logger.notice("update available \(currentVersion, privacy: .public) → \(release.version, privacy: .public)")

        return AppUpdate(version: release.version, storeURL: release.trackViewUrl)
    }

    /// 기기 지역의 앱스토어에서 이 앱의 최신 출시 정보를 받는다 (실패하면 nil)
    private func fetchRelease(bundleID: String) async -> LookupResponse.Result? {
        var components = URLComponents(string: "https://itunes.apple.com/lookup")
        var queryItems = [URLQueryItem(name: "bundleId", value: bundleID)]
        if let region = Locale.current.region?.identifier {
            queryItems.append(URLQueryItem(name: "country", value: region))
        }
        components?.queryItems = queryItems
        guard let url = components?.url else { return nil }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10

        do {
            let (data, _) = try await URLSession.shared.data(for: request)

            return try JSONDecoder().decode(LookupResponse.self, from: data).results.first
        } catch {
            Self.logger.notice("lookup failed (\(String(describing: error), privacy: .public))")

            return nil
        }
    }

    /// 이 기기의 iOS 버전 (예: 18.6.2)
    private static var currentOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion

        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// 점으로 나눈 숫자를 앞에서부터 비교해 lhs가 rhs보다 낮은 버전인지 확인한다 (26.2와 26.2.0은 같다)
    static func isVersion(_ lhs: String, olderThan rhs: String) -> Bool {
        let lhsParts = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let rhsParts = rhs.split(separator: ".").map { Int($0) ?? 0 }

        for index in 0..<max(lhsParts.count, rhsParts.count) {
            let lhsPart = index < lhsParts.count ? lhsParts[index] : 0
            let rhsPart = index < rhsParts.count ? rhsParts[index] : 0
            if lhsPart != rhsPart {
                return lhsPart < rhsPart
            }
        }

        return false
    }
}
