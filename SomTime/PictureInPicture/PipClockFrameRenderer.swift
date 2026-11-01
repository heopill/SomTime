//
//  PipClockFrameRenderer.swift
//  SomTime
//

import CoreMedia
import CoreVideo
import SwiftUI

/// 시계 화면(SwiftUI)을 PiP에 넣을 영상 프레임(CMSampleBuffer)으로 만든다.
/// 페이서가 달리면 초당 8~16번 그려야 하므로, 시계 이미지는 내용이 바뀔 때만 다시 렌더링하고 페이서 프레임만 매번 덧그린다
final class PipClockFrameRenderer {
    /// PiP 창을 크게 키워도 선명하도록 6배로 그린다 (10:1은 1320×132px, 2:1은 720×360px)
    private static let renderScale: CGFloat = 6
    /// 목표 시각 직전 깜빡임의 흐린 순간 투명도 (시계 글자와 같게)
    private static let dimmedAlpha: CGFloat = 0.35

    private var pixelBufferPool: CVPixelBufferPool?
    private var poolSize: (width: Int, height: Int) = (0, 0)
    private var clockImage: (key: ClockImageKey, image: CGImage)?
    private var pacerSprites: (key: PacerSpriteKey, images: [CGImage])?

    /// 지금 설정으로 시계 프레임 하나를 만든다 (countdown이 있으면 목표 시각까지 남은 시간도 그린다).
    /// 목표 시각 직전 강조 중이면 시계 · 남은 시간 · 페이서를 경고색으로 그린다
    func sampleBuffer(
        time: String,
        milliseconds: String?,
        countdown: String?,
        emphasis: PipClockEmphasis,
        settings: ClockDisplaySettings,
        aspectRatio: PipAspectRatio,
        pacer: PipPacer,
        pacerFrame: Int
    ) -> CMSampleBuffer? {
        let key = ClockImageKey(
            time: time,
            milliseconds: milliseconds,
            countdown: countdown,
            emphasis: emphasis,
            design: settings.design,
            color: settings.color,
            aspectRatio: aspectRatio,
            reservesPacerSlot: pacer != .off
        )
        guard let clock = clockImage(for: key) else { return nil }

        let sprite = pacerSprite(pacer, frame: pacerFrame, isWarning: emphasis != .none, color: settings.color)
        // 창형은 남은 시간이 있으면 페이서가 그 왼쪽, 없으면 가운데로 간다
        let slot = aspectRatio.pacerSlotRect(hasCountdown: countdown != nil)
        let pixelBuffer = makePixelBuffer(width: clock.width, height: clock.height) { context in
            context.draw(clock, in: CGRect(x: 0, y: 0, width: clock.width, height: clock.height))
            guard let sprite else { return }

            // 비트맵 좌표는 아래쪽이 0이므로 위쪽 기준인 자리 위치를 뒤집는다
            let scale = Self.renderScale
            context.setAlpha(emphasis == .warningDimmed ? Self.dimmedAlpha : 1)
            context.draw(sprite, in: CGRect(
                x: slot.minX * scale,
                y: (aspectRatio.frameSize.height - slot.maxY) * scale,
                width: slot.width * scale,
                height: slot.height * scale
            ))
        }
        guard let pixelBuffer else { return nil }

        return makeSampleBuffer(from: pixelBuffer)
    }

    /// 시계 이미지 (입력이 지난번과 같으면 다시 렌더링하지 않는다)
    private func clockImage(for key: ClockImageKey) -> CGImage? {
        if let clockImage, clockImage.key == key {
            return clockImage.image
        }

        // 목표 시각 직전에는 시계 색과 상관없이 경고색(빨강)으로 그린다
        let accent = key.emphasis == .none ? key.color.color : Color(.warning)
        let renderer = ImageRenderer(
            content: PipClockFrame(
                time: key.time,
                milliseconds: key.milliseconds,
                countdown: key.countdown,
                emphasis: key.emphasis,
                design: key.design,
                aspectRatio: key.aspectRatio,
                reservesPacerSlot: key.reservesPacerSlot
            )
            .environment(\.clockAccent, accent)
        )
        renderer.scale = Self.renderScale
        guard let image = renderer.cgImage else { return nil }

        clockImage = (key, image)

        return image
    }

    /// 강조색으로 칠한 페이서 프레임 (페이서 · 색이 바뀔 때만 8장을 다시 만든다. 페이서 없음이면 nil)
    private func pacerSprite(_ pacer: PipPacer, frame: Int, isWarning: Bool, color: ClockColor) -> CGImage? {
        guard pacer != .off else { return nil }

        let key = PacerSpriteKey(pacer: pacer, color: color, isWarning: isWarning)
        if pacerSprites?.key != key {
            let tint = UIColor(isWarning ? Color(.warning) : color.color)
            let slot = PipAspectRatio.pacerSlotSize
            let size = CGSize(width: slot.width * Self.renderScale, height: slot.height * Self.renderScale)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            let images = pacer.frames().compactMap { frame in
                renderer.image { _ in
                    frame.withTintColor(tint, renderingMode: .alwaysOriginal).draw(in: CGRect(origin: .zero, size: size))
                }
                .cgImage
            }
            pacerSprites = (key, images)
        }
        guard let images = pacerSprites?.images, !images.isEmpty else { return nil }

        return images[frame % images.count]
    }

    /// 크기에 맞는 BGRA 픽셀 버퍼를 만들어 그린다 (같은 크기면 풀에서 버퍼를 재사용)
    private func makePixelBuffer(width: Int, height: Int, draw: (CGContext) -> Void) -> CVPixelBuffer? {
        guard let pool = pixelBufferPool(width: width, height: height) else { return nil }

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        guard let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        // 풀에서 받은 버퍼에는 이전 프레임이 남아 있으므로 비우고 그린다
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        draw(context)

        return pixelBuffer
    }

    /// 프레임 크기에 맞는 픽셀 버퍼 풀을 돌려준다 (크기가 바뀌면 새로 만든다)
    private func pixelBufferPool(width: Int, height: Int) -> CVPixelBufferPool? {
        if let pixelBufferPool, poolSize == (width, height) {
            return pixelBufferPool
        }

        let attributes: [CFString: Any] = [
            kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey: width,
            kCVPixelBufferHeightKey: height,
            kCVPixelBufferIOSurfacePropertiesKey: [:] as CFDictionary,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]
        var pool: CVPixelBufferPool?
        CVPixelBufferPoolCreate(kCFAllocatorDefault, nil, attributes as CFDictionary, &pool)
        pixelBufferPool = pool
        poolSize = (width, height)

        return pool
    }

    /// 픽셀 버퍼를 받는 즉시 화면에 표시되는 샘플 버퍼로 감싼다
    private func makeSampleBuffer(from pixelBuffer: CVPixelBuffer) -> CMSampleBuffer? {
        var formatDescription: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescriptionOut: &formatDescription
        )
        guard let formatDescription else { return nil }

        var timing = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 1),
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),
            decodeTimeStamp: .invalid
        )
        var sampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(
            allocator: kCFAllocatorDefault,
            imageBuffer: pixelBuffer,
            formatDescription: formatDescription,
            sampleTiming: &timing,
            sampleBufferOut: &sampleBuffer
        )
        guard let sampleBuffer else { return nil }

        // 타임베이스 없이 받는 즉시 표시한다
        if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true),
           CFArrayGetCount(attachments) > 0 {
            let attachment = unsafeBitCast(CFArrayGetValueAtIndex(attachments, 0), to: CFMutableDictionary.self)
            CFDictionarySetValue(
                attachment,
                Unmanaged.passUnretained(kCMSampleAttachmentKey_DisplayImmediately).toOpaque(),
                Unmanaged.passUnretained(kCFBooleanTrue).toOpaque()
            )
        }

        return sampleBuffer
    }
}

/// 시계 이미지를 다시 렌더링해야 하는지 판단하는 입력값
private struct ClockImageKey: Equatable {
    let time: String
    let milliseconds: String?
    let countdown: String?
    let emphasis: PipClockEmphasis
    let design: ClockDesign
    let color: ClockColor
    let aspectRatio: PipAspectRatio
    let reservesPacerSlot: Bool
}

/// 칠한 페이서 프레임을 다시 만들어야 하는지 판단하는 입력값
private struct PacerSpriteKey: Equatable {
    let pacer: PipPacer
    let color: ClockColor
    let isWarning: Bool
}
