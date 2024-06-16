//
//  advSettings.swift
//  BiblePause
//
//  Created by Maria Novikova on 16.06.2024.
//

import SwiftUI

// MARK: Константы
protocol DisplayNameProvider {
    var displayName: String { get }
}
enum PauseType: String, CaseIterable, Identifiable, DisplayNameProvider {
    case none
    case time
    case full
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
            case .none: return "Не делать пауз"
            case .time: return "Приостанавливать на время"
            case .full: return "Останавливать полностью"
        }
    }
}

enum PauseBlock: String, CaseIterable, Identifiable, DisplayNameProvider {
    case verse
    case paragraph
    case fragment
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
            case .verse: return "стиха"
            case .paragraph: return "абзаца"
            case .fragment: return "отрывка"
        }
    }
}

// MARK: SettingsManager
class SettingsManager: ObservableObject {
    
    @AppStorage("fontIncreasePercent") var fontIncreasePercent: Double = 100.0
    
    @AppStorage("pauseType") var pauseType: PauseType = .none
    @AppStorage("pauseLength") var pauseLength: Double = 3.0
    @AppStorage("pauseBlock") var pauseBlock: PauseBlock = .verse
    
}
