//
//  typeBook.swift
//  23234234
//
//  Created by Maria Novikova on 05.07.2022.
//

import Foundation

// MARK: Text

struct BibleTextVerse: Hashable, Codable {
    var id: Int
    var text: String
}

struct BibleTextChapter: Hashable, Codable, Identifiable {
    var id: Int
    var verses: [BibleTextVerse]
}

struct BibleTextBook: Hashable, Codable, Identifiable {
    let id: Int
    let code: String
    let shortName: String
    let fullName: String
    var chapters: [BibleTextChapter]
}

struct BibleTextTranslation: Hashable, Codable {
    var code: String
    var lang: String
    var shortName: String
    var fullName: String
    var books: [BibleTextBook]
}

// MARK: Audio

struct BibleAudioVerse: Hashable, Codable {
    let id: Int
    //let begin: String
    //let end: String
    let begin: Double
    let end: Double
}

struct BibleAudioChapter: Hashable, Codable, Identifiable {
    let id: Int
    let verses: [BibleAudioVerse]
}

struct BibleAudioBook: Hashable, Codable, Identifiable {
    let id: Int
    let chapters: [BibleAudioChapter]
}

struct BibleAudioVoice: Hashable, Codable {
    let code: String
    let translation: String
    let books: [BibleAudioBook]
}

// MARK: Advanced

// более полная версия стиха, с указанием главы и книги

struct BibleTextVerseFull: Hashable {
    let id: Int
    let text: String
    var bookDigitCode: Int = 0
    var chapterDigitCode: Int = 0
     
    var changedBook = false
    var changedChapter = false
    var skippedVerses = false
}

struct BibleAudioVerseFull: Hashable {
    let id: Int
    let text: String
    let begin: Double
    let end: Double
}

