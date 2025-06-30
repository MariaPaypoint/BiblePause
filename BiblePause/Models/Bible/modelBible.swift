//
//  modelBooks.swift
//  23234234
//
//  Created by Maria Novikova on 05.07.2022.
//

import Foundation

// MARK: Auidio

struct VoiсeHeader {
    let code: String
    let reader: String
    let translationCode: String
}

class BibleAudio {
    
    let favoriteVoiceHeaders: [VoiсeHeader] = [
        VoiсeHeader(code: "bondarenko", reader: "Александр Бодаренко", translationCode: "syn"),
        VoiсeHeader(code: "prozorovsky", reader: "Н.Семёнов-Прозоровский", translationCode: "bti")
    ]
    
    private var activeVoices: [String: BibleAcousticalVoice] = [:]
    
    private var currentVoiceIndex: Int = 0
    private var currentVoice: BibleAcousticalVoice
    
    init() {
        let code = favoriteVoiceHeaders[currentVoiceIndex].code
        let translationCode = favoriteVoiceHeaders[currentVoiceIndex].translationCode
        //print("audio json: ", translationCode + "-" + code + ".json")
        activeVoices[code] = loadBibleTranslate(translationCode + "-" + code + ".json")
        currentVoice = activeVoices[code]!
    }
    
    func getCurrentVoice() -> BibleAcousticalVoice {
        return currentVoice;
    }
    
}

// MARK: Text

struct TranslationTextHeader {
    let code: String
    let shortName: String
}

class BibleText {
    
    let favoriteTranslationHeaders: [TranslationTextHeader] = [
        TranslationTextHeader(code: "syn", shortName: "SYNO"),
        TranslationTextHeader(code: "nrt", shortName: "НРП"),
        TranslationTextHeader(code: "kjv", shortName: "KJV"),
        TranslationTextHeader(code: "bti", shortName: "BTI")
    ]
    
    private var activeTranslations: [String: BibleTextualTranslation] = [:]
    
    private var currentTranslationIndex: Int = 0
    private var currentTranslation: BibleTextualTranslation
    
    init() {
        let code = favoriteTranslationHeaders[currentTranslationIndex].code
        activeTranslations[code] = loadBibleTranslate(code + ".json")
        currentTranslation = activeTranslations[code]!
    }
    
    func getTranslationNames() -> [String] {
        
        var arrTranslationsNames:[String] = []
        
        for translationHeader in favoriteTranslationHeaders {
            arrTranslationsNames.append(translationHeader.shortName)
        }
        
        return arrTranslationsNames
    }
    
    func getCurrentTranslationIndex() -> Int {
        return currentTranslationIndex
    }
    func setCurrentTranslation(index: Int) -> Void {
        
        currentTranslationIndex = index
        //print(index)
        
        let code = favoriteTranslationHeaders[currentTranslationIndex].code
        if activeTranslations[code] == nil {
            activeTranslations[code] = loadBibleTranslate(code + ".json")
        }
        currentTranslation = activeTranslations[code]!
    }
    
    func getCurrentTranslation() -> BibleTextualTranslation {
        return currentTranslation;
    }
}

let globalBibleText = BibleText()
let globalBibleAudio = BibleAudio()

func loadBibleTranslate<T: Decodable>(_ filename: String) -> T {
    let data: Data
    
    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
    else {
        fatalError("Couldn't find \(filename) in main bundle.")
    }
    
    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle: \n\(error).")
    }
    
    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self): \n\(error).")
    }
    
}
