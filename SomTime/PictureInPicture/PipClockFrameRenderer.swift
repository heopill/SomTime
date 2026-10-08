//
//  PipClockFrameRenderer.swift
//  SomTime
//

import CoreMedia
import CoreVideo
import SwiftUI

/// 시계 화면(SwiftUI)을 PiP에 넣을 영상 프레임(CMSampleBuffer)으로 만든다
final class PipClockFrameRenderer {
    /// PiP 창을 크게 키워도 선명하도록 6배로 그린다 (120×60pt → 720×360px)
    private static let renderScale: CGFloat = 6

    private var pixelBufferPool: CVPixelBufferPool?
    private var poolSize: (width: Int, height: Int) = (0, 0)

    /// 지금 설정으로 시계 프레임 하나를 만든다
    func sampleBuffer(time: String, settings: ClockDisplaySettings) -> CMSampleBuffer? {
        let renderer = ImageRenderer(
            content: PipClockFrame(time: time, design: settings.design)
                .environment(\.clockAccent, settings.color.color)
        )
        renderer.scale = Self.renderScale
        guard let image = renderer.cgImage, let pixelBuffer = makePixelBuffer(from: image) else { return nil }

        return makeSampleBuffer(from: pixelBuffer)
    }

    /// 그린 이미지를 BGRA 픽셀 버퍼에 옮긴다 (같은 크기면 풀에서 버퍼를 재사용)
    private func makePixelBuffer(from image: CGImage) -> CVPixelBuffer? {
        guard let pool = pixelBufferPool(width: image.width, height: image.height) else { return nil }

        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pool, &pixelBuffer)
        guard let pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }

        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

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
