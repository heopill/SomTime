//
//  DesignMetrics.swift
//  SomTime
//

import CoreGraphics

/// 모서리 반경 (DESIGN.md 3. 디자인 토큰)
enum CornerRadius {
    static let card: CGFloat = 20 // 기능 카드, 메뉴 행, 결과 카드
    static let control: CGFloat = 18 // 디자인 카드, 선택 버튼, 기본 버튼, 리스트 그룹
    static let summaryRow: CGFloat = 16 // 설정 요약 행
    static let input: CGFloat = 14 // 입력창, 보조 버튼, PiP 창, 아이콘 칸
    static let segmentOuter: CGFloat = 12 // 세그먼트 바깥
    static let segmentInner: CGFloat = 10 // 세그먼트 선택 칸
}

/// 간격 (DESIGN.md 3. 디자인 토큰)
enum Spacing {
    static let screenHorizontal: CGFloat = 20 // 화면 좌우 여백
    static let section: CGFloat = 24 // 섹션 간
    static let card: CGFloat = 12 // 카드 간
    static let cardPadding: CGFloat = 18 // 카드 내부 여백
    static let iconText: CGFloat = 14 // 아이콘-텍스트 간
    static let minTouchTarget: CGFloat = 44 // 최소 터치 영역
}
