//
//  PipPacer+Name.swift
//  SomTime
//

import SwiftUI

// 화면에 표시할 이름
extension PipPacer {
    var nameKey: LocalizedStringKey {
        switch self {
        case .off: return "pacerOff"
        case .jogger: return "pacerJoggerName"
        case .swimmer: return "pacerSwimmerName"
        case .cyclist: return "pacerCyclistName"
        case .fox: return "pacerFoxName"
        case .cat: return "pacerCatName"
        case .paws: return "pacerPawsName"
        case .rocket: return "pacerRocketName"
        case .plane: return "pacerPlaneName"
        case .camperVan: return "pacerCamperVanName"
        case .dna: return "pacerDnaName"
        }
    }
}
