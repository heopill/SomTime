//
//  PipClockController.swift
//  SomTime
//

import AVFoundation
import AVKit
import OSLog
import UIKit

/// PiP 창에서 일어난 일 (홈 토글 동기화용)
nonisolated enum PipClockEvent: Sendable {
    /// 사용자가 PiP 창을 닫았거나 시스템이 PiP를 끝냄 (앱으로 돌아가기 버튼은 제외)
    case closed
}

nonisolated enum PipClockError: Error {
    /// 이 기기는 PiP를 지원하지 않음
    case unsupported
    /// PiP 창을 띄우지 못함
    case startFailed
}

/// 시계 화면을 영상 프레임으로 그려 PiP 창에 띄운다 (AVSampleBufferDisplayLayer + AVPictureInPictureController).
/// 켜져 있는 동안에는 앱이 백그라운드로 갈 때 PiP가 자동으로 다시 시작된다
final class PipClockController: NSObject {
    static let shared = PipClockController()

    private nonisolated static let logger = Logger(subsystem: "dev.seongpil.SomTime", category: "PictureInPicture")
    /// PiP를 띄울 수 있는 상태가 될 때까지 기다리는 최대 시간
    private static let possibleTimeout: Duration = .seconds(2)
    /// PiP 창이 실제로 뜰 때까지 기다리는 최대 시간
    private static let startTimeout: Duration = .seconds(5)
    /// 시스템이 PiP를 띄우기 시작했다면(willStart) 추가로 더 기다리는 시간
    private static let startingGracePeriod: Duration = .seconds(10)
    /// 밀리초를 표시할 때 프레임 간격 (약 30fps. 배터리 소모가 커서 서버 시간 PiP에서만 쓴다)
    private static let millisecondsFrameInterval: Duration = .milliseconds(33)
    /// 직접 끈 PiP 창이 닫힐 때까지 기다리는 최대 시간
    private static let stopTimeout: Duration = .seconds(2)
    /// 오디오 세션을 켜고 끄는 순서를 지키기 위한 직렬 큐 (메인 스레드에서 처리하면 화면이 멈출 수 있다)
    private nonisolated static let audioSessionQueue = DispatchQueue(label: "dev.seongpil.SomTime.audioSession")

    private let frameRenderer = PipClockFrameRenderer()
    private var displayView: SampleBufferDisplayView?
    private var pipController: AVPictureInPictureController?
    private var renderTask: Task<Void, Never>?
    private var settings: ClockDisplaySettings?
    private var aspectRatio = ClockSettingsStorage.DefaultValue.pipAspectRatio
    private var startContinuation: CheckedContinuation<Void, Error>?
    private var stopContinuation: CheckedContinuation<Void, Never>?
    /// 진행 중인 종료 작업 (끄자마자 다시 켜면 이전 창이 닫힌 뒤에 시작하도록)
    private var stopTask: Task<Void, Never>?
    private var isRestoringUserInterface = false
    /// 시스템이 PiP 창을 띄우는 중인지 여부 (willStart ~ didStart/failedToStart)
    private var isPictureInPictureStarting = false
    /// 켜고 끌 때마다 바뀌는 세션 번호 (이전 세션의 늦은 실패 처리가 새 세션을 정리하지 않도록)
    private var session = 0
    private var eventContinuations: [UUID: AsyncStream<PipClockEvent>.Continuation] = [:]

    /// PiP 시계를 켜고 창이 뜰 때까지 기다린다 (이미 떠 있으면 설정만 바꾼다)
    func start(_ settings: ClockDisplaySettings, aspectRatio: PipAspectRatio) async throws {
        guard DeviceCapability.supportsPictureInPicture else { throw PipClockError.unsupported }

        await stopTask?.value
        self.settings = settings
        setAspectRatio(aspectRatio)
        if pipController?.isPictureInPictureActive == true {
            // 이미 떠 있는 창은 그대로 두고 새 설정으로 다시 그린다 (일반 시계 ↔ 서버 시간 전환)
            startRendering()

            return
        }

        let session = session
        do {
            let pipController = try await prepare()
            try await waitUntilPossible(pipController)
            Self.logger.notice("start: picture in picture possible, requesting start")
            try await withCheckedThrowingContinuation { continuation in
                startContinuation = continuation
                // 컨트롤러를 만든 직후 같은 런루프에서 시작을 요청하면 무시되므로 다음 턴에 요청한다
                DispatchQueue.main.async {
                    pipController.startPictureInPicture()
                }
                Task { [weak self] in
                    try? await Task.sleep(for: Self.startTimeout)
                    guard let self, self.isPictureInPictureStarting else {
                        self?.handleStartTimeout()
                        return
                    }

                    // 시스템이 창을 띄우는 중이면 바로 끊지 않고 조금 더 기다린다
                    Self.logger.notice("start: still starting after timeout, waiting more")
                    try? await Task.sleep(for: Self.startingGracePeriod)
                    self.handleStartTimeout()
                }
            }
            Self.logger.notice("start: picture in picture started")
        } catch {
            Self.logger.error("start: failed \(String(describing: error), privacy: .public)")
            if !(error is CancellationError), session == self.session {
                tearDown()
            }
            throw error
        }
    }

    /// 떠 있는 PiP 시계에 바뀐 설정을 바로 반영한다
    func update(_ settings: ClockDisplaySettings, aspectRatio: PipAspectRatio) {
        guard self.settings != nil else { return }

        self.settings = settings
        setAspectRatio(aspectRatio)
        // 밀리초 표시가 바뀌면 그리는 간격도 바뀌므로 다시 시작한다
        if renderTask != nil {
            startRendering()
        } else {
            renderFrame()
        }
    }

    /// PiP 창 비율을 바꾼다 (프레임 크기가 바뀌면 시스템이 PiP 창 모양을 맞춘다). 숨겨 둔 레이어도 오른쪽 아래 기준으로 크기를 맞춘다
    private func setAspectRatio(_ aspectRatio: PipAspectRatio) {
        guard aspectRatio != self.aspectRatio else { return }

        self.aspectRatio = aspectRatio
        guard let displayView else { return }

        let size = aspectRatio.frameSize
        displayView.frame = CGRect(
            x: displayView.frame.maxX - size.width,
            y: displayView.frame.maxY - size.height,
            width: size.width,
            height: size.height
        )
    }

    /// PiP 시계를 끄고 자동 시작도 해제한다 (떠 있던 창이 닫힐 때까지 기다린다)
    func stop() async {
        resumeStart(throwing: CancellationError())
        if let stopTask {
            await stopTask.value

            return
        }

        let task = Task { await stopPictureInPictureAndTearDown() }
        stopTask = task
        await task.value
        stopTask = nil
    }

    /// 떠 있는 PiP 창을 닫고 모두 정리한다
    private func stopPictureInPictureAndTearDown() async {
        if let pipController, pipController.isPictureInPictureActive {
            await withCheckedContinuation { continuation in
                stopContinuation = continuation
                pipController.stopPictureInPicture()
                Task { [weak self] in
                    try? await Task.sleep(for: Self.stopTimeout)
                    self?.resumeStop()
                }
            }
        }
        tearDown()
    }

    /// 기다리고 있는 종료 요청을 끝낸다 (이미 끝났으면 무시)
    private func resumeStop() {
        guard let stopContinuation else { return }

        self.stopContinuation = nil
        stopContinuation.resume()
    }

    /// PiP 창이 닫히는 이벤트를 구독한다
    func events() -> AsyncStream<PipClockEvent> {
        let (stream, continuation) = AsyncStream.makeStream(of: PipClockEvent.self)
        let id = UUID()
        eventContinuations[id] = continuation
        continuation.onTermination = { _ in
            Task { @MainActor in
                PipClockController.shared.eventContinuations[id] = nil
            }
        }

        return stream
    }

    /// 프레임을 그릴 레이어와 PiP 컨트롤러를 준비하고 매초 그리기를 시작한다
    private func prepare() async throws -> AVPictureInPictureController {
        // 컨트롤러를 끌 때마다 새로 만들면 PiP 시스템 서비스와의 연결이 끊겨 시작 요청이 무시되므로 한 번 만들어 재사용한다
        if pipController == nil || displayView?.window == nil {
            try makePictureInPictureController()
        }
        guard let pipController else { throw PipClockError.startFailed }

        await activateAudioSession()
        startRendering()
        pipController.canStartPictureInPictureAutomaticallyFromInline = true

        return pipController
    }

    /// 프레임을 그릴 레이어를 창에 붙이고 PiP 컨트롤러를 만든다
    private func makePictureInPictureController() throws {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first else { throw PipClockError.startFailed }

        // PiP는 레이어가 창 안에 있어야 시작할 수 있어 앱 화면 뒤에 숨겨 둔다.
        // PiP 창은 이 레이어 위치에서 커지며 나오므로, PiP 창이 주로 놓이는 오른쪽 아래에 둔다
        let size = aspectRatio.frameSize
        let insets = window.safeAreaInsets
        let origin = CGPoint(
            x: window.bounds.maxX - insets.right - Spacing.screenHorizontal - size.width,
            y: window.bounds.maxY - insets.bottom - Spacing.screenHorizontal - size.height
        )
        let view = SampleBufferDisplayView(frame: CGRect(origin: origin, size: size))
        view.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin]
        view.isUserInteractionEnabled = false
        displayView?.removeFromSuperview()
        window.insertSubview(view, at: 0)
        displayView = view

        let contentSource = AVPictureInPictureController.ContentSource(
            sampleBufferDisplayLayer: view.displayLayer,
            playbackDelegate: self
        )
        let pipController = AVPictureInPictureController(contentSource: contentSource)
        pipController.delegate = self
        pipController.requiresLinearPlayback = true
        self.pipController = pipController
    }

    /// 레이어가 창에 붙어 PiP를 띄울 수 있는 상태가 될 때까지 기다린다
    private func waitUntilPossible(_ pipController: AVPictureInPictureController) async throws {
        let deadline = ContinuousClock.now + Self.possibleTimeout
        while !pipController.isPictureInPicturePossible {
            guard ContinuousClock.now < deadline else {
                Self.logger.error("start: picture in picture never became possible")
                throw PipClockError.startFailed
            }

            try await Task.sleep(for: .milliseconds(50))
        }
    }

    /// 시계 프레임을 계속 그린다 (보통은 표시하는 초가 바뀌는 순간마다, 밀리초를 표시하면 초당 30번)
    private func startRendering() {
        renderTask?.cancel()
        renderTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let delay = self?.renderFrameAndNextDelay() else { return }

                try? await Task.sleep(for: delay)
            }
        }
    }

    /// 프레임 하나를 그리고 다음 프레임까지 기다릴 시간을 돌려준다
    private func renderFrameAndNextDelay() -> Duration {
        renderFrame()
        guard let settings else { return .seconds(1) }

        if settings.serverTime?.showsMilliseconds == true {
            return Self.millisecondsFrameInterval
        }

        // 서버 시간이면 오프셋을 더한 시각의 초가 바뀌는 순간에 맞춘다
        let now = settings.clockDate().timeIntervalSinceReferenceDate

        return .seconds(now.rounded(.down) + 1 - now + 0.01)
    }

    /// 지금 시각으로 프레임 하나를 그려 레이어에 넣는다
    private func renderFrame() {
        guard let settings, let renderer = displayView?.displayLayer.sampleBufferRenderer else { return }

        // 백그라운드 전환 등으로 디코딩이 멈추면 비우고 다시 넣는다
        if renderer.status == .failed || renderer.requiresFlushToResumeDecoding {
            renderer.flush()
        }

        let date = settings.clockDate()
        let time = ClockTimeFormatter.string(
            from: date,
            isTwentyFourHour: settings.isTwentyFourHour,
            showsSeconds: settings.showsSeconds,
            design: settings.design
        )
        let milliseconds = settings.serverTime?.showsMilliseconds == true
            ? String(format: "%03d", Int((date.timeIntervalSince1970 * 1000).rounded(.down)) % 1000)
            : nil
        guard let sampleBuffer = frameRenderer.sampleBuffer(
            time: time,
            milliseconds: milliseconds,
            settings: settings,
            aspectRatio: aspectRatio
        ) else { return }

        renderer.enqueue(sampleBuffer)
    }

    /// 시작 대기 시간이 지났을 때 처리한다 (창이 이미 떠 있으면 성공으로 본다)
    private func handleStartTimeout() {
        guard startContinuation != nil else { return }

        if pipController?.isPictureInPictureActive == true {
            Self.logger.notice("start: active without didStart callback")
            resumeStart()

            return
        }

        Self.logger.error("start: timed out waiting for didStart (possible \(self.pipController?.isPictureInPicturePossible == true, privacy: .public))")
        resumeStart(throwing: PipClockError.startFailed)
    }

    /// 기다리고 있는 시작 요청을 끝낸다 (이미 끝났으면 무시)
    private func resumeStart(throwing error: Error? = nil) {
        isPictureInPictureStarting = false
        guard let startContinuation else { return }

        self.startContinuation = nil
        if let error {
            startContinuation.resume(throwing: error)
        } else {
            startContinuation.resume()
        }
    }

    /// 그리기, 자동 시작, 오디오 세션을 끈다 (PiP 컨트롤러와 레이어는 다음에 다시 쓰도록 남겨 둔다)
    private func tearDown() {
        session += 1
        renderTask?.cancel()
        renderTask = nil
        pipController?.canStartPictureInPictureAutomaticallyFromInline = false
        displayView?.displayLayer.sampleBufferRenderer.flush(removingDisplayedImage: true, completionHandler: nil)
        settings = nil
        isRestoringUserInterface = false
        isPictureInPictureStarting = false
        deactivateAudioSession()
    }

    /// PiP에 필요한 재생 오디오 세션을 켠다 (다른 앱의 영상 · 음악 소리를 끊지 않도록 섞어서 재생).
    /// 메인 스레드에서 켜고 끄면 화면이 멈출 수 있어 백그라운드에서 처리한다
    private func activateAudioSession() async {
        await withCheckedContinuation { continuation in
            Self.audioSessionQueue.async {
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
                    try audioSession.setActive(true)
                } catch {
                    Self.logger.error("audio session activation failed \(String(describing: error), privacy: .public)")
                }
                continuation.resume()
            }
        }
    }

    /// 오디오 세션을 끈다 (같은 직렬 큐에서 처리해 다음 활성화보다 먼저 끝난다)
    private func deactivateAudioSession() {
        Self.audioSessionQueue.async {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            } catch {
                Self.logger.error("audio session deactivation failed \(String(describing: error), privacy: .public)")
            }
        }
    }

    /// 구독 중인 곳에 이벤트를 알린다
    private func send(_ event: PipClockEvent) {
        for continuation in eventContinuations.values {
            continuation.yield(event)
        }
    }
}

// MARK: - AVPictureInPictureControllerDelegate

extension PipClockController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Self.logger.notice("will start")
        isPictureInPictureStarting = true
    }

    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        Self.logger.notice("did start")
        resumeStart()
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        Self.logger.error("failed to start \(String(describing: error), privacy: .public)")
        resumeStart(throwing: PipClockError.startFailed)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        // 앱으로 돌아가기 버튼: 켜진 상태를 유지하고, 다시 백그라운드로 가면 자동으로 PiP를 띄운다
        isRestoringUserInterface = true
        completionHandler(true)
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        // 토글을 꺼서 직접 닫은 경우: 정리는 stop()이 맡는다
        guard stopContinuation == nil else {
            Self.logger.notice("stopped: by toggle")
            resumeStop()

            return
        }
        guard !isRestoringUserInterface else {
            isRestoringUserInterface = false
            Self.logger.notice("stopped: restored to app, staying armed")

            return
        }

        Self.logger.notice("stopped: closed by user or system")
        tearDown()
        send(.closed)
    }
}

// MARK: - AVPictureInPictureSampleBufferPlaybackDelegate

extension PipClockController: AVPictureInPictureSampleBufferPlaybackDelegate {
    func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {}

    func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        // 끝이 없는 실시간 영상으로 알려 재생 막대를 숨긴다
        return CMTimeRange(start: .negativeInfinity, duration: .positiveInfinity)
    }

    func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        didTransitionToRenderSize newRenderSize: CMVideoDimensions
    ) {}

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        skipByInterval skipInterval: CMTime,
        completion completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}

// MARK: - SampleBufferDisplayView

/// AVSampleBufferDisplayLayer를 기본 레이어로 쓰는 뷰
private final class SampleBufferDisplayView: UIView {
    override class var layerClass: AnyClass {
        return AVSampleBufferDisplayLayer.self
    }

    var displayLayer: AVSampleBufferDisplayLayer {
        return layer as! AVSampleBufferDisplayLayer
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        displayLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
