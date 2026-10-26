//
//  CaptchaImage.swift
//  SomTime
//

import SwiftUI

/// 보안 문자 그림. 실제 예매처처럼 밝은 바탕에 글자를 기울이고 곡선 · 점을 겹쳐 그린다 (seed가 같으면 같은 모양)
struct CaptchaImage: View {
    let challenge: CaptchaChallenge

    /// 그림의 가로 : 세로 비율
    static let aspectRatio: CGFloat = 200 / 64

    private static let background = Color(red: 0.93, green: 0.94, blue: 0.95)
    private static let inks = [
        Color(red: 0.17, green: 0.18, blue: 0.22),
        Color(red: 0.2, green: 0.25, blue: 0.36),
        Color(red: 0.25, green: 0.18, blue: 0.28),
    ]

    var body: some View {
        Canvas { context, size in
            var generator = SeededRandomGenerator(seed: challenge.seed)
            let style = challenge.difficulty.captchaStyle
            // 선 굵기 · 점 크기는 높이 64pt 기준으로 맞춘다 (카드 미리보기처럼 작게 그려도 같은 느낌)
            let scale = size.height / 64

            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Self.background))
            if !style.linesOverText {
                Self.drawLines(in: context, size: size, scale: scale, style: style, generator: &generator)
            }
            Self.drawLetters(challenge.text, in: context, size: size, style: style, generator: &generator)
            if style.linesOverText {
                Self.drawLines(in: context, size: size, scale: scale, style: style, generator: &generator)
            }
            Self.drawDots(in: context, size: size, scale: scale, style: style, generator: &generator)
        }
        .aspectRatio(Self.aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement()
        .accessibilityLabel(Text("captchaImageAccessibility \(challenge.text.map(String.init).joined(separator: " "))"))
    }

    /// 글자를 한 칸씩 기울이고 위아래 · 좌우로 흔들어 그린다
    private static func drawLetters(
        _ text: String,
        in context: GraphicsContext,
        size: CGSize,
        style: Style,
        generator: inout SeededRandomGenerator
    ) {
        let count = Double(text.count)
        let slot = size.width * style.textWidthRatio / count
        let startX = (size.width - slot * count) / 2 + slot / 2

        for (index, letter) in text.enumerated() {
            let fontSize = size.height * Double.random(in: style.fontSizeRange, using: &generator)
            let design = style.designs.randomElement(using: &generator) ?? .serif
            let ink = Array(inks.prefix(style.inkCount)).randomElement(using: &generator) ?? inks[0]
            let x = startX + slot * Double(index) + slot * Double.random(in: -style.horizontalJitter...style.horizontalJitter, using: &generator)
            let y = size.height / 2 + size.height * Double.random(in: -style.verticalJitter...style.verticalJitter, using: &generator)
            let angle = Double.random(in: -style.maxRotation...style.maxRotation, using: &generator)

            var layer = context
            layer.translateBy(x: x, y: y)
            layer.rotate(by: .degrees(angle))
            layer.draw(
                Text(String(letter))
                    .font(.system(size: fontSize, weight: .semibold, design: design))
                    .foregroundStyle(ink),
                at: .zero,
                anchor: .center
            )
        }
    }

    /// 그림을 가로지르는 곡선을 그린다
    private static func drawLines(
        in context: GraphicsContext,
        size: CGSize,
        scale: CGFloat,
        style: Style,
        generator: inout SeededRandomGenerator
    ) {
        for _ in 0..<style.lineCount {
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height * Double.random(in: 0.15...0.85, using: &generator)))
            path.addCurve(
                to: CGPoint(x: size.width, y: size.height * Double.random(in: 0.15...0.85, using: &generator)),
                control1: CGPoint(x: size.width * 0.33, y: size.height * Double.random(in: -0.2...1.2, using: &generator)),
                control2: CGPoint(x: size.width * 0.66, y: size.height * Double.random(in: -0.2...1.2, using: &generator))
            )
            let lineWidth = Double.random(in: style.lineWidthRange, using: &generator) * scale

            context.stroke(path, with: .color(inks[0].opacity(0.75)), lineWidth: lineWidth)
        }
    }

    /// 바탕에 잔점을 뿌린다
    private static func drawDots(
        in context: GraphicsContext,
        size: CGSize,
        scale: CGFloat,
        style: Style,
        generator: inout SeededRandomGenerator
    ) {
        for _ in 0..<style.dotCount {
            let radius = Double.random(in: 0.8...1.6, using: &generator) * scale
            let center = CGPoint(
                x: Double.random(in: 0...size.width, using: &generator),
                y: Double.random(in: 0...size.height, using: &generator)
            )
            let dot = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))

            context.fill(dot, with: .color(inks[0].opacity(0.6)))
        }
    }
}

extension CaptchaImage {
    /// 글자를 비트는 정도
    struct Style {
        /// 글자 기울기 최대 각도 (±도)
        let maxRotation: Double
        /// 좌우 흔들림 (글자 칸 대비)
        let horizontalJitter: Double
        /// 위아래 흔들림 (그림 높이 대비)
        let verticalJitter: Double
        /// 글자 크기 (그림 높이 대비)
        let fontSizeRange: ClosedRange<Double>
        let designs: [Font.Design]
        /// 글자 색 가짓수 (앞에서부터)
        let inkCount: Int
        /// 글자 6개가 차지하는 폭 (그림 폭 대비). 작을수록 글자가 겹친다
        let textWidthRatio: Double
        let lineCount: Int
        /// 곡선 굵기 (높이 64pt 기준)
        let lineWidthRange: ClosedRange<Double>
        /// 곡선을 글자 위에 그릴지 여부 (쉬움은 글자 뒤에 그려 읽기 쉽게 한다)
        let linesOverText: Bool
        let dotCount: Int
    }
}

extension CaptchaDifficulty {
    /// 난이도별 글자를 비트는 정도 (쉬움: 거의 반듯 · 보통: 실제 예매처 수준 · 어려움: 글자 겹침 + 곡선 · 점 많음)
    var captchaStyle: CaptchaImage.Style {
        switch self {
        case .easy:
            return CaptchaImage.Style(
                maxRotation: 5,
                horizontalJitter: 0.04,
                verticalJitter: 0.03,
                fontSizeRange: 0.5...0.52,
                designs: [.serif],
                inkCount: 1,
                textWidthRatio: 0.86,
                lineCount: 1,
                lineWidthRange: 1...1.2,
                linesOverText: false,
                dotCount: 0
            )
        case .normal:
            return CaptchaImage.Style(
                maxRotation: 15,
                horizontalJitter: 0.08,
                verticalJitter: 0.08,
                fontSizeRange: 0.46...0.56,
                designs: [.serif, .default],
                inkCount: 2,
                textWidthRatio: 0.84,
                lineCount: 3,
                lineWidthRange: 1.2...1.8,
                linesOverText: true,
                dotCount: 14
            )
        case .hard:
            return CaptchaImage.Style(
                maxRotation: 25,
                horizontalJitter: 0.12,
                verticalJitter: 0.11,
                fontSizeRange: 0.46...0.6,
                designs: [.serif, .default, .rounded],
                inkCount: 3,
                textWidthRatio: 0.74,
                lineCount: 5,
                lineWidthRange: 1.4...2.4,
                linesOverText: true,
                dotCount: 30
            )
        }
    }
}

/// seed가 같으면 같은 순서의 난수를 내는 생성기 (SplitMix64). 같은 보안 문자를 다시 그려도 모양이 바뀌지 않게 한다
private struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    /// 다음 난수를 만든다
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var value = state
        value = (value ^ (value >> 30)) &* 0xBF58_476D_1CE4_E5B9
        value = (value ^ (value >> 27)) &* 0x94D0_49BB_1331_11EB

        return value ^ (value >> 31)
    }
}

#Preview {
    VStack(spacing: Spacing.card) {
        CaptchaImage(challenge: CaptchaChallenge(text: "KTRMBA", seed: 11, difficulty: .easy))
        CaptchaImage(challenge: CaptchaChallenge(text: "XQHFNW", seed: 23, difficulty: .normal))
        CaptchaImage(challenge: CaptchaChallenge(text: "QOVYJW", seed: 37, difficulty: .hard))
    }
    .padding(Spacing.screenHorizontal)
    .background(Color(.background))
}
