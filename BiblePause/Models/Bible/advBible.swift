//
//  advExcerpt.swift
//  cep
//
//  Created by Maria Novikova on 31.12.2022.
//

import SwiftUI
import OpenAPIURLSession


// MARK: Отрывок - массив строк (возвращает список стихов и информацию, является ли отрывок одной единственной целой главой)

func getExcerptTextualVerses(excerpts: String) -> ([BibleTextualVerseFull], Bool) {
    
    var resVerses: [BibleTextualVerseFull] = []
    var resSingleChapter: Bool = false
    
    let clear_excerpts = excerpts.trimmingCharacters(in: .whitespacesAndNewlines)
    //let clear_excerpts = "dfdfg, mfodd; 3:3, mf 18, mf 18:kk, mk kk:4, mk 6:4-uu, mk 6:w-4, mk 7:4-5, mk 7:14, , mk 70:14, mk 7:140, mf 5:47-50" // check correct/incorrect values
    
    guard clear_excerpts != "" else {
        if globalDebug { resVerses.append(BibleTextualVerseFull(number: 0, html: "EMPTY EXCERPT")) }
        return (resVerses, resSingleChapter)
    }
    
    var oldVerse: Int = 0
    
    let arrClearExcerpts = clear_excerpts.components(separatedBy: ",")
    
    for excerpt in arrClearExcerpts {
        let arrExcerpt = excerpt.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
        guard arrExcerpt.count == 2 else {
            if globalDebug { resVerses.append(BibleTextualVerseFull(number: 0, html: "INCORRECT EXCERPT: \(excerpt)")) }
            continue
        }
        let book_name = arrExcerpt[0] // for example: mf
        let chapter_and_verses = arrExcerpt[1]
        
        let book = (globalBibleText.getCurrentTranslation().books.first(where: {$0.code == book_name}))
        guard book != nil else {
            if globalDebug { resVerses.append(BibleTextualVerseFull(number: 0, html: "INCORRECT BOOK: \(book_name)")) }
            continue
        }
        
        let arrChapterAndVerses = chapter_and_verses.components(separatedBy: ":")
        guard arrChapterAndVerses.count == 1 || arrChapterAndVerses.count == 2 else {
            if globalDebug { resVerses.append(BibleTextualVerseFull(number: 0, html: "INCORRECT CHAPTER AND VERSES: \(chapter_and_verses)")) }
            continue
        }
        guard Int(arrChapterAndVerses[0]) != nil else {
            resVerses.append(BibleTextualVerseFull(number: 0, html: "INCORRECT CHAPTER (NOT INT): \(arrChapterAndVerses[0])"))
            continue
        }
        let chapter_index = Int(arrChapterAndVerses[0])!
        let chapter = book!.chapters.first(where: {element in element.id == chapter_index})
        guard chapter != nil else {
            if globalDebug { resVerses.append(BibleTextualVerseFull(number: 0, html: "NONEXISTENT CHAPTER: \(chapter_index)")) }
            continue
        }
        let verses_interval = arrChapterAndVerses.count == 1 ? "1-\(chapter!.verses.count)" : arrChapterAndVerses[1]
        
        let arrVersesInterval = verses_interval.components(separatedBy: "-")
        guard Int(arrVersesInterval[0]) != nil else {
            if globalDebug { resVerses.append(BibleTextualVerseFull(number: 0, html: "INCORRECT INTERVAL (NOT INT): \(arrVersesInterval[0])")) }
            continue
        }
        guard arrVersesInterval.count == 1 || (arrVersesInterval.count == 2 && Int(arrVersesInterval[1]) != nil) else {
            if globalDebug { resVerses.append(BibleTextualVerseFull(number: 0, html: "INCORRECT INTERVAL (NOT INT): \(arrVersesInterval[1])")) }
            continue
        }
        
        let verse_first = Int(arrVersesInterval[0])!
        let verse_last = arrVersesInterval.count > 1 ? Int(arrVersesInterval[1])! : Int(arrVersesInterval[0])!
        
        for verse_index in verse_first...verse_last {
            let verse = chapter!.verses.first(where: {element in element.id == verse_index})
            guard verse != nil else {
                if globalDebug { resVerses.append(BibleTextualVerseFull(number: 0, html: "INCORRECT VERSE: \(verse_index)")) }
                break
            }
            let text = verse!.text
            resVerses.append(BibleTextualVerseFull(
                number: verse_index,
                html: text,
                bookDigitCode: book!.id,
                chapterDigitCode: chapter!.id,
                //changedBook: !(oldBook == book!.id || oldBook == 0),
                //changedChapter: !(oldChapter == chapter!.id || oldChapter == 0),
                skippedVerses: !(verse!.id - oldVerse == 1 || oldVerse == 0)
            ))
            
            oldVerse = verse!.id
            
        }
        resSingleChapter = arrClearExcerpts.count == 1 && arrChapterAndVerses.count == 1
    }
    
    return (resVerses, resSingleChapter)
}


func getExcerptTextualVersesOnline(excerpts: String, client: APIProtocol, translation: Int, voice: Int) async throws -> ([BibleTextualVerseFull], [BibleAcousticalVerseFull], String, Bool, Components.Schemas.PartsWithAlignmentModel?) {
    do {
        let response = try await client.get_excerpt_with_alignment(query: .init(translation: translation, excerpt: excerpts, voice: voice))
        
        if let unprocessableContent = try? response.unprocessableContent {
            let detail = try unprocessableContent.body.json.detail
            throw NSError(domain: "getExcerptTextualVersesOnline", code: 422, userInfo: [NSLocalizedDescriptionKey: detail])
        }
        
        let answer = try response.ok.body.json
        let parts = answer.parts
        
        var resTextVerses: [BibleTextualVerseFull] = []
        var resAudioVerses: [BibleAcousticalVerseFull] = []
        var resFirstUrl: String = ""
        var resPart: Components.Schemas.PartsWithAlignmentModel?
        let resSingleChapter = answer.is_single_chapter
        
        //var oldBook: Int = 0
        //var oldChapter: Int = 0
        var oldVerse: Int = 0
        
        for part in parts {
            if resFirstUrl == "" { resFirstUrl = part.audio_link }
            resPart = part
            for verse in part.verses {
                var verseFull = BibleTextualVerseFull(
                    number: verse.number,
                    html: verse.html,
                    join: verse.join,
                    bookDigitCode: part.book.number,
                    chapterDigitCode: part.chapter_number,
                    //changedBook: !(oldBook == part.book_number || oldBook == 0),
                    //changedChapter: !(oldChapter == part.chapter_number || oldChapter == 0),
                    skippedVerses: !(verse.number - oldVerse == 1 || oldVerse == 0),
                    startParagraph: verse.start_paragraph
                )
                for note in part.notes {
                    if note.verse_code == verse.code {
                        verseFull.notes.append(BibleNote(id: note.code, text: note.text, positionHtml: note.position_html))
                    }
                }
                for title in part.titles {
                    if title.before_verse_code == verse.code {
                        var titleWithNotes = BibleTitle(id: title.code, text: title.text, metadata: title.metadata, reference: title.reference)
                        
                        // Добавляем примечания к заголовку
                        for note in part.notes {
                            if note.title_code == title.code {
                                titleWithNotes.notes.append(BibleNote(id: note.code, text: note.text, positionHtml: note.position_html))
                            }
                        }
                        
                        verseFull.beforeTitle = titleWithNotes
                    }
                }
                resTextVerses.append(verseFull)
                
                resAudioVerses.append(BibleAcousticalVerseFull(
                    number: verse.number,
                    text: verse.text,
                    begin: verse.begin,
                    end: verse.end
                ))
                //oldBook =  part.book_number
                //oldChapter = part.chapter_number
                oldVerse = verse.number
            }
        }
        
        // Ensure the first audio URL includes the api_key as a query parameter
        var firstURLWithKey = resFirstUrl
        if let original = URL(string: resFirstUrl) {
            let withKey = SettingsManager.audioURLWithKey(from: original)
            firstURLWithKey = withKey.absoluteString
        }
        return (resTextVerses, resAudioVerses, firstURLWithKey, resSingleChapter, resPart)
    } catch {
        
        throw error
    }
}

// MARK: Audio

// Дополнение данными по аудио
func getExcerptAudioVerses(textVerses: [BibleTextualVerseFull]) -> ([BibleAcousticalVerseFull], String) {
    
    var resVerses: [BibleAcousticalVerseFull] = []
    
    let voice = globalBibleAudio.getCurrentVoice()
    
    var audioBook: BibleAcousticalBook?
    var audioChapter: BibleAcousticalChapter?
    
    var bookDigitCode: Int = 0
    var chapterDigitCode: Int = 0
    
    for textVerse in textVerses {
        
        guard textVerse.number != 0 else { continue } // ошибка стиха, но может он один такой
        
        if chapterDigitCode == 0 {
            // для первого стиха находим и проверяем книгу/главу
            audioBook = voice.books.first(where: {element in element.id == textVerse.bookDigitCode})
            guard audioBook != nil else {
                return (resVerses, "Book (\(textVerse.bookDigitCode)) not found in current voice")
            }
            
            audioChapter = audioBook!.chapters.first(where: {element in element.id == textVerse.chapterDigitCode})
            guard audioBook != nil else {
                return (resVerses, "Chapter (\(textVerse.chapterDigitCode)) not found in book (\(textVerse.bookDigitCode)) in current voice")
            }
            
            bookDigitCode = textVerse.bookDigitCode
            chapterDigitCode = textVerse.chapterDigitCode
        }
        else {
            // для остальных стихов просто проверяем, что книга и глава не изменились
            
            guard bookDigitCode == textVerse.bookDigitCode else {
                return (resVerses, "There are too many books in the excerpt")
            }
            guard chapterDigitCode == textVerse.chapterDigitCode else {
                return (resVerses, "There are too many chapters in the excerpt")
            }
            
        }
        
        // находим и проверяем стих
        
        let audioVerse = audioChapter!.verses.first(where: {element in element.id == textVerse.number})
        guard audioVerse != nil else {
            return (resVerses, "Verse (\(textVerse.number)) not found in chapter(\(textVerse.chapterDigitCode)) in book (\(textVerse.bookDigitCode)) in current voice")
        }
        
        resVerses.append(BibleAcousticalVerseFull(
            number: textVerse.number,
            text: textVerse.html,
            begin: audioVerse!.begin,
            end: audioVerse!.end))
    }
    
    return (resVerses, "")
}

// получение номера главы из отрывка (для аудио, например)
func getExcerptBookChapterDigitCode(verses: [BibleTextualVerseFull]) -> (String, String) {
    
    //let resVerses = getExcerptStrings(excerpts: excerpts)
    let resVerses = verses
    
    guard !resVerses.isEmpty else { return ("","") }
    
    guard resVerses[0].number != 0 else { return ("","") }
    
    return (
        String(format: "%02d", resVerses[0].bookDigitCode),
        String(format: "%02d", resVerses[0].chapterDigitCode)
    )
}

// Начало и конец отрывка в текущей озвучке
func getExcerptPeriod(audioVerses: [BibleAcousticalVerseFull]) -> (Double, Double) {
    
    guard audioVerses.count > 0 else {
        return (0, 0)
    }
    
    // это нужно, чтобы если отрывок начинается с 1 стиха, то позиционировать на начало дорожки, а не на первый стих
    //let period_from: Double = audioVerses[0].id == 1 ? 0 : audioVerses[0].begin
    
    let period_from: Double = audioVerses[0].begin
    let period_to: Double = audioVerses[audioVerses.count - 1].end
    
    return (period_from - 0, period_to - 0)
}

// MARK: Отрывок в 1 строку
/*
func getExcerptText(excerpts: String) -> String {
    
    let (verses, _) = getExcerptTextualVerses(excerpts: excerpts)
    
    var resText = ""
    
    for (verse) in verses {
        resText = resText + verse.text + " "
    }
    
    return resText.trimmingCharacters(in: CharacterSet(charactersIn: " ,"))
}
*/
