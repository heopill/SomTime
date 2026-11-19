//
//  PacerTip.swift
//  SomTime
//

import SwiftUI
import TipKit

/// 홈 화면 페이서 버튼을 처음 한 번 알려 주는 말풍선 (닫거나 버튼을 누르면 다시 뜨지 않는다)
nonisolated struct PacerTip: Tip {
    var title: Text {
        Text("pacerTipTitle")
    }

    var message: Text? {
        Text("pacerTipMessage")
    }

    var image: Image? {
        Image(systemName: "figure.run")
    }
}
