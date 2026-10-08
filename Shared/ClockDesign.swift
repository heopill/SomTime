//
//  ClockDesign.swift
//  SomTime
//

import Foundation

/// 설정에서 고르는 시계 디자인
nonisolated enum ClockDesign: String, CaseIterable, Codable {
    /// 기본 (Pretendard Medium)
    case classic
    /// 모노 (SF Mono)
    case mono
    /// 굵게 (Pretendard Bold, 자간 -4%)
    case bold
    /// 도트 (Doto Black)
    case dot

    /// 폰트에 한글 글자가 있는지 여부 (Doto, SF Mono에는 "오전/오후" 글자가 없다)
    var supportsHangul: Bool {
        switch self {
        case .classic, .bold: return true
        case .mono, .dot: return false
        }
    }
}
