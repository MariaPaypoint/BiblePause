import Foundation

var globalCurrentTranslationIndex: Int = 0

var globalDebug = true

let globalBasePadding = 22.0
let globalCornerRadius = 6.0

var bibleParts: [String] {
    [
        "bible.part.old".localized,
        "bible.part.new".localized
    ]
}

var bibleHeaders: [Int: String] {
    [
        1: "bible.header.1".localized,
        6: "bible.header.6".localized,
        18: "bible.header.18".localized,
        23: "bible.header.23".localized,
        28: "bible.header.28".localized,
        40: "bible.header.40".localized,
        45: "bible.header.45".localized,
        52: "bible.header.52".localized,
        66: "bible.header.66".localized
    ]
}
