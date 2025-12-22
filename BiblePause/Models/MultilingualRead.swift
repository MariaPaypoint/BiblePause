import Foundation

enum MultilingualStepType: String, Codable {
    case read
    case pause
}

enum MultilingualReadUnit: String, Codable, CaseIterable, DisplayNameProvider {
    case verse
    case paragraph
    case fragment
    case chapter
    
    // helper for localization view
    var localized: String {
        switch self {
        case .verse: return "unit.verse".localized
        case .paragraph: return "unit.paragraph".localized
        case .fragment: return "unit.fragment".localized
        case .chapter: return "unit.chapter".localized
        }
    }
    
    var displayName: String {
        return localized
    }
}

struct MultilingualStep: Identifiable, Codable, Equatable {
    var id = UUID()
    var type: MultilingualStepType
    
    // Read properties
    var languageCode: String = ""
    var languageName: String = "" // Added for UI convenience
    var translationCode: Int = 0
    var translationName: String = ""
    var voiceCode: Int = 0
    var voiceName: String = ""
    var voiceMusic: Bool = false
    var fontIncreasePercent: Double = 100.0
    
    // Pause properties
    var pauseDuration: Double = 2.0

    static func == (lhs: MultilingualStep, rhs: MultilingualStep) -> Bool {
        return lhs.id == rhs.id &&
        lhs.type == rhs.type &&
        lhs.languageCode == rhs.languageCode &&
        lhs.translationCode == rhs.translationCode &&
        lhs.voiceCode == rhs.voiceCode &&
        lhs.pauseDuration == rhs.pauseDuration &&
        lhs.fontIncreasePercent == rhs.fontIncreasePercent
    }
}

struct MultilingualTemplate: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var steps: [MultilingualStep]
    var unit: MultilingualReadUnit
}
