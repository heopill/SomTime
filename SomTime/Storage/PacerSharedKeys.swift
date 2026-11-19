//
//  PacerSharedKeys.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

// PiP 페이서 선택과 포인트 지갑

extension SharedKey where Self == AppStorageKey<PipPacer>.Default {
    /// 지금 고른 페이서 (기기 설정이라 기기에만 저장한다. 모르는 값이면 기본 페이서로 읽힌다)
    static var pipPacer: Self {
        Self[.appStorage("pipPacer"), default: PipPacer.defaultPacer]
    }
}

extension SharedKey where Self == PacerWalletKey.Default {
    /// 포인트와 해제한 페이서 (iCloud 키-값 저장소에 저장해 같은 Apple ID 기기끼리 동기화한다)
    static var pacerWallet: Self {
        Self[PacerWalletKey(), default: PacerWallet()]
    }
}
