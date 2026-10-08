//
//  FontStyle.swift
//  SomTime
//

import SwiftUI

struct FontStyle {
    let font: Font
    let fontSize: CGFloat
    let lineHeightMultiple: CGFloat // 행간 비율
    let trackingRatio: CGFloat // 자간 비율 (-0.02 = -2%)

    // SwiftUI lineSpacing에 대응하는 줄 간격
    var lineSpacing: CGFloat {
        return fontSize * (lineHeightMultiple - 1)
    }

    // SwiftUI tracking에 대응하는 자간 (pt)
    var tracking: CGFloat {
        return fontSize * trackingRatio
    }

    /// 번들에 포함된 커스텀 폰트로 스타일을 만든다 (isFixedSize가 true면 Dynamic Type을 따르지 않음)
    init(
        fontName: String,
        fontSize: CGFloat,
        lineHeightMultiple: CGFloat = 1,
        trackingRatio: CGFloat = 0,
        isFixedSize: Bool = false
    ) {
        self.font = isFixedSize
            ? Font.custom(fontName, fixedSize: fontSize)
            : Font.custom(fontName, size: fontSize)
        self.fontSize = fontSize
        self.lineHeightMultiple = lineHeightMultiple
        self.trackingRatio = trackingRatio
    }

    /// 시스템 폰트 등 이미 만들어진 Font로 스타일을 만든다
    init(font: Font, fontSize: CGFloat, lineHeightMultiple: CGFloat = 1, trackingRatio: CGFloat = 0) {
        self.font = font
        self.fontSize = fontSize
        self.lineHeightMultiple = lineHeightMultiple
        self.trackingRatio = trackingRatio
    }
}

// MARK: - 폰트 이름

extension FontStyle {
    enum FontName {
        static let pretendardRegular = "Pretendard-Regular"
        static let pretendardMedium = "Pretendard-Medium"
        static let pretendardSemiBold = "Pretendard-SemiBold"
        static let pretendardBold = "Pretendard-Bold"
        static let dotoBlack = "Doto-Black"
    }
}

// MARK: - 화면 텍스트

extension FontStyle {
    // MARK: Pretendard-Bold (Title)
    static let homeTitle = FontStyle(fontName: FontName.pretendardBold, fontSize: 28, lineHeightMultiple: 1.3, trackingRatio: -0.02) // 홈 타이틀
    static let screenTitle = FontStyle(fontName: FontName.pretendardBold, fontSize: 24, lineHeightMultiple: 1.3, trackingRatio: -0.02) // 하위 화면 타이틀 (설정, 서버 시간)
    static let primaryButton = FontStyle(fontName: FontName.pretendardBold, fontSize: 16, lineHeightMultiple: 1.3) // 기본 버튼 (시작, 시계 끄기)

    // MARK: Pretendard-SemiBold
    static let cardTitle = FontStyle(fontName: FontName.pretendardSemiBold, fontSize: 16, lineHeightMultiple: 1.5) // 기능 카드, 메뉴 행 제목
    static let secondaryButton = FontStyle(fontName: FontName.pretendardSemiBold, fontSize: 14, lineHeightMultiple: 1.5) // 보조 버튼, 선택 버튼 (측정, 다이나믹 아일랜드)
    static let sectionTitle = FontStyle(fontName: FontName.pretendardSemiBold, fontSize: 13, lineHeightMultiple: 1.5) // 섹션 제목, 세그먼트

    // MARK: Pretendard-Regular (Body)
    static let rowLabel = FontStyle(fontName: FontName.pretendardRegular, fontSize: 15, lineHeightMultiple: 1.5) // 리스트 행 레이블, 입력창
    static let summary = FontStyle(fontName: FontName.pretendardRegular, fontSize: 14, lineHeightMultiple: 1.5) // 홈 하단 설정 요약 행
    static let detail = FontStyle(fontName: FontName.pretendardRegular, fontSize: 13, lineHeightMultiple: 1.5) // 보조 설명, 카드 상태 문구
    static let caption = FontStyle(fontName: FontName.pretendardRegular, fontSize: 12, lineHeightMultiple: 1.5) // 캡션, 디자인 카드 이름
}

// MARK: - 시계 숫자

extension FontStyle {
    /// 시계 숫자가 표시되는 위치
    enum ClockPlacement {
        case island // 다이나믹 아일랜드 Compact
        case minimal // 다이나믹 아일랜드 Minimal
        case expanded // 다이나믹 아일랜드 Expanded
        case lockScreen // 잠금 화면, StandBy
        case pip // PiP 플로팅 시계
        case pipMilliseconds // PiP 플로팅 시계의 밀리초 (약 2/3 크기)
        case serverTime // 서버 시간 결과
        case serverTimeMilliseconds // 서버 시간 결과의 밀리초
        case designCard // 설정의 디자인 카드 미리보기

        var fontSize: CGFloat {
            switch self {
            case .island: return 15
            case .minimal: return 13
            case .expanded: return 44
            case .lockScreen: return 30
            case .pip: return 28
            case .pipMilliseconds: return 19
            case .serverTime: return 38
            case .serverTimeMilliseconds: return 24
            case .designCard: return 26
            }
        }
    }

    /// 시계 디자인과 표시 위치에 맞는 시계 숫자 스타일을 만든다 (크기 고정, 숫자 폭 고정)
    static func clock(_ design: ClockDesign, placement: ClockPlacement) -> FontStyle {
        return clock(design, size: placement.fontSize)
    }

    /// 시계 디자인과 임의의 크기로 시계 숫자 스타일을 만든다 (가로 모드 아일랜드처럼 공간에 맞춰 크기를 줄일 때 사용)
    static func clock(_ design: ClockDesign, size: CGFloat) -> FontStyle {
        switch design {
        case .classic:
            return FontStyle(font: Font.custom(FontName.pretendardMedium, fixedSize: size).monospacedDigit(), fontSize: size)
        case .mono:
            return FontStyle(font: Font.system(size: size, weight: .medium, design: .monospaced), fontSize: size)
        case .bold:
            return FontStyle(font: Font.custom(FontName.pretendardBold, fixedSize: size).monospacedDigit(), fontSize: size, trackingRatio: -0.04)
        case .dot:
            return FontStyle(font: Font.custom(FontName.dotoBlack, fixedSize: size), fontSize: size, trackingRatio: 0.02)
        }
    }
}

// MARK: - View 적용

private struct FontStyleModifier: ViewModifier {
    let style: FontStyle

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .lineSpacing(style.lineSpacing)
            .tracking(style.tracking)
    }
}

extension View {
    /// 지정한 FontStyle(폰트, 크기, 행간, 자간)을 한 번에 적용한다
    func fontStyle(_ style: FontStyle) -> some View {
        modifier(FontStyleModifier(style: style))
    }
}
