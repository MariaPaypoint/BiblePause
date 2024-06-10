//
//  advConst.swift
//  cep
//
//  Created by Maria Novikova on 14.08.2022.
//

import Foundation

var globalCurrentTranslationIndex: Int = 0

//let cTranslationsNames = ["SYNO", "НРП", "EASY", "РБЦ"]
//let cTranslationsCodes = ["SYNO", "NRT", "EASY", "RBC"]
//let cTranslations: [String:String] = ["SYNO":"SYNO", "NRT":"НРП", "2":"EASY", "3":"РБЦ"]

var globalDebug = true

let globalBasePadding = 22.0
let globalCornerRadius = 6.0

let bibleParts = ["Ветхий Завет", "Новый Завет"]
let bibleHeaders: [Int: String] = [
        0: "Закон пятикнижия (Тора)",
        5: "Исторические книги",
        17: "Учительные",
        22: "Большие пророки",
        27: "Малые пророки",
        39: "Евангелия и Деяния",
        44: "Соборные послания",
        51: "Послания Павла",
        65: "Пророческие"
    ]
