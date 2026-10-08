//
//  ClockSettingsSharedKeys.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

// 홈과 설정 화면이 함께 읽고 쓰는 시계 설정 (App Group UserDefaults에 저장)

extension SharedKey where Self == AppStorageKey<ClockDesign>.Default {
    static var clockDesign: Self {
        Self[
            .appStorage(ClockSettingsStorage.Key.clockDesign, store: ClockSettingsStorage.userDefaults),
            default: ClockSettingsStorage.DefaultValue.clockDesign
        ]
    }
}

extension SharedKey where Self == AppStorageKey<ClockColor>.Default {
    static var clockColor: Self {
        Self[
            .appStorage(ClockSettingsStorage.Key.clockColor, store: ClockSettingsStorage.userDefaults),
            default: ClockSettingsStorage.DefaultValue.clockColor
        ]
    }
}

extension SharedKey where Self == AppStorageKey<PipAspectRatio>.Default {
    static var pipAspectRatio: Self {
        Self[
            .appStorage(ClockSettingsStorage.Key.pipAspectRatio, store: ClockSettingsStorage.userDefaults),
            default: ClockSettingsStorage.DefaultValue.pipAspectRatio
        ]
    }
}

extension SharedKey where Self == AppStorageKey<Bool>.Default {
    static var isTwentyFourHour: Self {
        Self[
            .appStorage(ClockSettingsStorage.Key.isTwentyFourHour, store: ClockSettingsStorage.userDefaults),
            default: ClockSettingsStorage.DefaultValue.isTwentyFourHour
        ]
    }

    static var showsSeconds: Self {
        Self[
            .appStorage(ClockSettingsStorage.Key.showsSeconds, store: ClockSettingsStorage.userDefaults),
            default: ClockSettingsStorage.DefaultValue.showsSeconds
        ]
    }
}
