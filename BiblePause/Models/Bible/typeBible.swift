// Необходимые типы для работы с Библией через API

import Foundation

// MARK: Verse structures

// Полная версия стиха с указанием главы и книги
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
    let reference: String?
    var notes: [BibleNote] = []
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

