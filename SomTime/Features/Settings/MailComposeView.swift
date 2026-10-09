//
//  MailComposeView.swift
//  SomTime
//

import SwiftUI
@preconcurrency import MessageUI

/// 문의 메일에 자동으로 채워 넣을 수신자 / 제목 / 본문을 구성한다
enum SupportInfo {
    /// 문의 받는 사람
    static let recipient = "somtime.support@gmail.com"

    /// 메일 제목
    static var subject: String {
        return String(localized: "contactMailSubject")
    }

    /// 메일을 보낼 수 없을 때 클립보드에 복사할 전체 정보 (받는사람 + 제목 + 본문)
    static var clipboardText: String {
        return """
        \(String(localized: "contactMailRecipient \(recipient)"))
        \(String(localized: "contactMailSubjectLabel \(subject)"))

        \(body)
        """
    }

    /// 문의 내용 안내 + 기기/앱 정보가 채워진 본문
    static var body: String {
        return """
        \(String(localized: "contactMailGuide"))


        ────────────────────
        \(String(localized: "contactMailAutoFilledNotice"))
        \(String(localized: "contactMailDevice \(deviceModelName)"))
        \(String(localized: "contactMailOSVersion \(UIDevice.current.systemVersion)"))
        \(String(localized: "contactMailAppVersion \(appVersion)"))
        \(String(localized: "contactMailLocale \(Locale.current.identifier)"))
        ────────────────────
        """
    }

    /// 앱 버전 (표시 버전 + 빌드 번호)
    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"

        return "\(version) (\(build))"
    }

    /// 사람이 읽기 좋은 기기 이름 (예: iPhone 15 Pro). 매핑에 없으면 식별자를 그대로 표시한다
    private static var deviceModelName: String {
        let identifier = deviceIdentifier

        return modelNames[identifier] ?? identifier
    }

    /// 기기 모델 식별자 (예: iPhone16,1). 시뮬레이터에서는 시뮬레이트 중인 기기 식별자를 사용한다
    private static var deviceIdentifier: String {
        if let simulatorID = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulatorID
        }

        var systemInfo = utsname()
        uname(&systemInfo)
        let identifier = Mirror(reflecting: systemInfo.machine).children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }

            result.append(Character(UnicodeScalar(UInt8(value))))
        }

        return identifier.isEmpty ? UIDevice.current.model : identifier
    }

    /// 식별자 → 마케팅 이름 매핑 (iPhone 11 ~ 17 계열, SE, Air)
    private static let modelNames: [String: String] = [
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE (2nd generation)",
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,6": "iPhone SE (3rd generation)",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,5": "iPhone 16e",
        "iPhone18,1": "iPhone 17 Pro",
        "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17",
        "iPhone18,4": "iPhone Air"
    ]
}

/// MFMailComposeViewController를 SwiftUI에서 사용하기 위한 래퍼
struct MailComposeView: UIViewControllerRepresentable {
    /// 자동 입력할 수신자 / 제목 / 본문
    let recipient: String
    let subject: String
    let body: String
    /// 작성 창이 닫힐 때 호출된다
    var onFinish: () -> Void = {}

    /// 수신자 / 제목 / 본문이 채워진 메일 작성 창을 만든다
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([recipient])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)

        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    /// 작성 창 닫힘을 전달받을 코디네이터를 만든다
    func makeCoordinator() -> Coordinator {
        return Coordinator(onFinish: onFinish)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        /// 보내기 / 취소 / 저장 등으로 작성 창이 끝나면 닫는다
        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            onFinish()
        }
    }
}
