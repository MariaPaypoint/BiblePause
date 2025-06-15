// Необходимые типы: стихи, главы, книги, варианты

import Foundation

// MARK: Text

struct BibleTextualVerse: Hashable, Codable {
    var id: Int
    var text: String
}

struct BibleTextualChapter: Hashable, Codable, Identifiable {
    var id: Int
    var verses: [BibleTextualVerse]
}

struct BibleTextualBook: Hashable, Codable, Identifiable {
    let id: Int
    let code: String
    let shortName: String
    let fullName: String
    var chapters: [BibleTextualChapter]
}

// BibleTextualTranslation
struct BibleTextualTranslation: Hashable, Codable {
    var code: String
    var lang: String
    var shortName: String
    var fullName: String
    var books: [BibleTextualBook]
}

// MARK: Audio

struct BibleAcousticalVerse: Hashable, Codable {
    let id: Int
    //let begin: String
    //let end: String
    let begin: Double
    let end: Double
}

struct BibleAcousticalChapter: Hashable, Codable, Identifiable {
    let id: Int
    let verses: [BibleAcousticalVerse]
}

struct BibleAcousticalBook: Hashable, Codable, Identifiable {
    let id: Int
    let chapters: [BibleAcousticalChapter]
}

// BibleAcousticalVoice
struct BibleAcousticalVoice: Hashable, Codable {
    let code: String
    let translation: String
    let books: [BibleAcousticalBook]
}

// MARK: Advanced

// более полная версия стиха, с указанием главы и книги

struct BibleTextualVerseFull: Hashable {
    let number: Int
    let html: String
    var join: Int = 0
    
    // чтобы выбор книги и главы позиционировался корректно
    var bookDigitCode: Int = 0
    var chapterDigitCode: Int = 0
     
    //var changedBook = false
    //var changedChapter = false
    var skippedVerses = false
    
    var startParagraph = false
    
    var notes: [BibleNote] = []
    
    var beforeTitle: BibleTitle?
    
}

struct BibleTitle: Hashable, Codable {
    let id: Int
    let text: String
    let metadata: String?
}

struct BibleNote: Hashable, Codable {
    let id: Int
    let text: String
    let positionHtml: Int
}

struct BibleAcousticalVerseFull: Hashable {
    let number: Int
    let text: String
    let begin: Double
    let end: Double
}

