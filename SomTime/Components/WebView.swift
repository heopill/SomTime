//
//  WebView.swift
//  SomTime
//

import SwiftUI
import WebKit

/// 번들에 포함된 로컬 HTML 파일을 표시하는 WebView
struct WebView: UIViewRepresentable {
    /// 표시할 로컬 HTML 파일 URL
    let fileURL: URL

    /// 앱 배경이 비치도록 투명한 WKWebView를 만들고 HTML을 불러온다
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear

        // file:// 로드는 시뮬레이터에서 한글 글꼴이 깨지는 문제가 있어, HTML 문자열로 로드한다
        if let html = try? String(contentsOf: fileURL, encoding: .utf8) {
            webView.loadHTMLString(html, baseURL: fileURL.deletingLastPathComponent())
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}
}
