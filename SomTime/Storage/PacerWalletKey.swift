//
//  PacerWalletKey.swift
//  SomTime
//

import ComposableArchitecture
import Foundation

/// 페이서 지갑을 iCloud 키-값 저장소(NSUbiquitousKeyValueStore)에 JSON으로 저장하는 공유 키.
/// iCloud에 로그인하지 않았으면 기기 안에만 남는다
nonisolated struct PacerWalletKey: SharedKey {
    typealias Value = PacerWallet

    private static let storageKey = "pacerWallet"

    var id: String {
        return Self.storageKey
    }

    /// 저장된 지갑을 읽는다. 값이 없으면 기본 지갑을 쓰되 저장하지 않는다
    /// (재설치 직후 iCloud 동기화가 오기 전에 빈 지갑이 기존 기록을 덮어쓰지 않도록)
    func load(context: LoadContext<PacerWallet>, continuation: LoadContinuation<PacerWallet>) {
        guard let wallet = Self.storedWallet() else {
            continuation.resumeReturningInitialValue()
            return
        }

        continuation.resume(returning: wallet)
    }

    /// 다른 기기에서 바꾸었거나 재설치 뒤 늦게 도착한 iCloud 값을 반영한다
    func subscribe(context: LoadContext<PacerWallet>, subscriber: SharedSubscriber<PacerWallet>) -> SharedSubscription {
        let observer = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default,
            queue: nil
        ) { _ in
            guard let wallet = Self.storedWallet() else { return }

            subscriber.yield(wallet)
        }

        return SharedSubscription {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// 지금 iCloud에 있는 지갑과 합친 뒤 저장한다 (다른 기기에서 해제한 페이서를 지우지 않도록)
    func save(_ value: PacerWallet, context: SaveContext, continuation: SaveContinuation) {
        let wallet = Self.storedWallet().map { value.merged(with: $0) } ?? value
        do {
            let data = try JSONEncoder().encode(wallet)
            NSUbiquitousKeyValueStore.default.set(data, forKey: Self.storageKey)
            continuation.resume()
        } catch {
            continuation.resume(throwing: error)
        }
    }

    /// iCloud 키-값 저장소에 저장된 지갑 (없거나 읽을 수 없으면 nil)
    private static func storedWallet() -> PacerWallet? {
        guard let data = NSUbiquitousKeyValueStore.default.data(forKey: storageKey) else { return nil }

        return try? JSONDecoder().decode(PacerWallet.self, from: data)
    }
}
