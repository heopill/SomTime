//
//  PipPacer.swift
//  SomTime
//

import UIKit

/// PiP 시계 왼쪽에서 달리는 페이서. 원본 값(rawValue)은 지갑의 해제 기록에 그대로 저장되므로 바꾸지 않는다
nonisolated enum PipPacer: String, CaseIterable, Codable, Sendable {
    /// 페이서 없음 (PiP에 시계만 보인다)
    case off
    case jogger
    case swimmer
    case cyclist
    case fox
    case cat
    case paws
    case rocket
    case plane
    case camperVan
    case dna

    /// 처음부터 쓸 수 있는 기본 페이서
    static let defaultPacer: PipPacer = .jogger
    /// 페이서 한 바퀴를 이루는 프레임 수
    static let frameCount = 8
    /// 잠긴 페이서를 해제하는 데 드는 포인트
    static let unlockPrice = 50

    /// 해제하는 데 드는 포인트 (페이서 없음과 기본 페이서는 무료)
    var price: Int {
        return isFree ? 0 : Self.unlockPrice
    }

    /// 포인트 없이 쓸 수 있는지 여부
    var isFree: Bool {
        return self == .off || self == Self.defaultPacer
    }

    /// 에셋 카탈로그의 프레임 이름 (pacerJogger0 ~ pacerJogger7). 페이서 없음은 프레임이 없다
    var frameNames: [String] {
        guard self != .off else { return [] }

        let base = "pacer" + rawValue.prefix(1).uppercased() + rawValue.dropFirst()

        return (0..<Self.frameCount).map { "\(base)\($0)" }
    }

    /// 프레임 이미지 (흰색 단색 + 투명 배경). 그리는 쪽은 에셋 이름을 몰라도 되도록 여기서만 읽는다
    func frames() -> [UIImage] {
        return frameNames.compactMap { UIImage(named: $0) }
    }
}
