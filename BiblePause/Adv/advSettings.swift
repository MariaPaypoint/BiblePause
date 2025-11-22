import SwiftUI

// MARK: Constants
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
    
    var shortName: String {
        switch self {
            case .verse: return "стих"
            case .paragraph: return "абзац"
            case .fragment: return "отр."
        }
    }
}

