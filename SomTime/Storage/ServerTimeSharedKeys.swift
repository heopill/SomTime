//
//  ServerTimeSharedKeys.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

// 서버 시간 화면과 홈이 함께 읽고 쓰는 값

extension SharedKey where Self == AppStorageKey<String>.Default {
    /// 서버 시간 화면의 사이트 주소 입력값
    static var serverTimeURL: Self {
        Self[.appStorage("serverTimeURL", store: ClockSettingsStorage.userDefaults), default: ""]
    }
}

extension SharedKey where Self == AppStorageKey<ServerTimeDisplayMode>.Default {
    /// 서버 시간 표시 방식 (다이나믹 아일랜드 / PiP)
    static var serverTimeDisplayMode: Self {
        Self[.appStorage("serverTimeDisplayMode", store: ClockSettingsStorage.userDefaults), default: .island]
    }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
    /// 서버 시간 PiP의 밀리초 표시 여부
    static var showsServerTimeMilliseconds: Self {
        Self[.appStorage("showsServerTimeMilliseconds", store: ClockSettingsStorage.userDefaults), default: false]
    }
}

extension SharedKey where Self == FileStorageKey<ServerTimeMeasurement?>.Default {
    /// 마지막 측정 결과 (App Group 컨테이너에 저장)
    static var serverTimeMeasurement: Self {
        Self[.fileStorage(serverTimeMeasurementFileURL), default: nil]
    }

    private static var serverTimeMeasurementFileURL: URL {
        let directory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: ClockSettingsStorage.appGroupIdentifier)
            ?? URL.applicationSupportDirectory

        return directory.appending(component: "serverTimeMeasurement.json")
    }
}

extension SharedKey where Self == InMemoryKey<ServerClockSession?>.Default {
    /// 실행 중인 서버 시간 시계 (앱이 실행되는 동안만 유지)
    static var serverClockSession: Self {
        Self[.inMemory("serverClockSession"), default: nil]
    }
}
