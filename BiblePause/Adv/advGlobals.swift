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
        1: "Закон пятикнижия (Тора)",
        6: "Исторические книги",
        18: "Учительные",
        23: "Большие пророки",
        28: "Малые пророки",
        40: "Евангелия и Деяния",
        45: "Соборные послания",
        52: "Послания Павла",
        66: "Пророческие"
    ]
