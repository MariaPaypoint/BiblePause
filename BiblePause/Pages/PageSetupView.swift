//
//  PageSetupView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI

// MARK: Константы
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

//let pauseBlockTexts = ["стиха", "абзаца", "отрывка"]
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
}

struct PageSetupView: View {
    
    @Binding var showMenu: Bool
    @Binding var selectedMenuItem: MenuItem
    @Binding var showFromRead: Bool
    
    @Binding var fontIncreasePercent: Double
    
    //@AppStorage("pauseType") private var pauseType: String = pauseTypeValues.none.rawValue
    //var pauseTypeText: String {
    //    (pauseTypeValues(rawValue: pauseType) ?? .none).displayName
    //}
    @AppStorage("pauseType") private var pauseType: PauseType = .none
    
    // MARK: Паузы
    //@State private var pauseTypeText = pauseTypeTexts[0]
    //var pauseTypeValue: pauseTypeValues {
    //    let mapping: [String: pauseTypeValues] = [
    //        pauseTypeTexts[0]: .none,
    //        pauseTypeTexts[1]: .time,
    //        pauseTypeTexts[2]: .full
    //    ]
    //    return mapping[pauseTypeText] ?? .none
    //}
    
    @State private var pauseLength = "3"
    
    @AppStorage("pauseBlock") private var pauseBlock: PauseBlock = .verse
    
    //@State private var pauseBlockText = pauseBlockTexts[0]
    //var pauseBlock: PauseBlock {
    //    let mapping: [String: PauseBlock] = [
    //        pauseBlockTexts[0]: .verse,
    //        pauseBlockTexts[1]: .paragraph,
    //        pauseBlockTexts[2]: .fragment
    //    ]
    //    return mapping[pauseBlockText] ?? .verse
    //}
    
    // MARK: Языки и переводы
    let languageTexts = ["Английский", "Русский", "Украинский"]
    let languageKeys  = ["en",         "ru",      "ua"]
    @State private var languageKey: String = UserDefaults.standard.string(forKey: "languageKey") ?? "en"
    
    let translateTexts = ["SYNO (Русский Синодальный)", "НРП (Новый Русский)", "BTI (под редакцией Кулаковых)"]
    let translateKeys  = ["syno",                       "nrp",                 "bti"]
    @State private var translateKey: String = UserDefaults.standard.string(forKey: "translateKey") ?? "syno"
    
    let audioTexts = ["Александр Бондаренко", "''Свет на востоке''"]
    let audioKeys  = ["bondarenko",           "eastlight"]
    @State private var audioKey = "bondarenko"
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                // MARK: шапка
                HStack {
                    if showFromRead {
                        
                        Button {
                            showFromRead = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.title)
                                .fontWeight(.light)
                        }
                        .foregroundColor(Color.white.opacity(0.5))
                    }
                    else {
                        MenuButtonView(
                            showMenu: $showMenu,
                            selectedMenuItem: $selectedMenuItem)
                    }
                    Spacer()
                    
                    Text("Настройки")
                        .fontWeight(.bold)
                        .padding(.trailing, 32) // компенсация меню, чтобы надпись была по центру
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, globalBasePadding)
                
                ScrollView() {
                    VStack {
                        // MARK: Шрифт
                        VStack {
                            viewGroupHeader(text: "Шрифт")
                            
                            HStack {
                                Text("\(Int(fontIncreasePercent))%")
                                    .foregroundColor(.white)
                                    .frame(width: 70)
                                
                                Spacer()
                                
                                HStack(spacing: 0) {
                                    Button(action: {
                                        if fontIncreasePercent > 10 {
                                            fontIncreasePercent = fontIncreasePercent - 10
                                        }
                                    }) {
                                        Text("A")
                                            .font(.title3)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.clear)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Divider() // Разделительная линия между кнопками
                                        .background(Color.white)
                                    
                                    Button(action: {
                                        if fontIncreasePercent < 500 {
                                            fontIncreasePercent = fontIncreasePercent + 10
                                        }
                                    }) {
                                        Text("A")
                                            .font(.title)
                                            .frame(maxWidth: .infinity)
                                            .background(Color.clear)
                                            .foregroundColor(.white)
                                    }
                                }
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .stroke(Color.white, lineWidth: 1)
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.clear)
                                )
                                .frame(maxWidth: 200)
                                .frame(maxHeight: 42)
                                .padding()
                                
                                Spacer()
                                Button {
                                    fontIncreasePercent = 100.0
                                } label: {
                                    Text("Сброс")
                                        .foregroundColor(Color("Mustard"))
                                        .frame(width: 70)
                                }
                            }
                            
                            Text("Пример:")
                                .foregroundColor(.white.opacity(0.5))
                            ScrollView() {
                                let (textVerses, _) = getExcerptTextVerses(excerpts: "jhn 1:1-3")
                                viewExcerpt(verses: textVerses, fontIncreasePercent: fontIncreasePercent)
                                    .padding(.bottom, 20)
                                    .id("top")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 158)
                        }
                        
                        // MARK: Пауза
                        viewGroupHeader(text: "Пауза")
                        VStack(spacing: 15) {
                            viewEnumPicker(title: pauseType.displayName, selection: $pauseType)
                            
                            if pauseType != .none {
                                // время
                                if pauseType == .time {
                                    HStack {
                                        Text("Делать паузу")
                                            .frame(width: 140, alignment: .leading)
                                        Spacer()
                                        TextField("", text: $pauseLength)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 12)
                                            .background(Color("DarkGreen-light").opacity(0.6))
                                            .cornerRadius(5)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 5)
                                                    .stroke(.white.opacity(0.25), lineWidth: 1)
                                            )
                                            .multilineTextAlignment(.center)
                                        
                                        Text("сек.")
                                    }
                                }
                                
                                // после чего
                                HStack {
                                    Text("После каждого")
                                        .frame(width: 140, alignment: .leading)
                                    Spacer()
                                    
                                    viewEnumPicker(title: pauseBlock.displayName, selection: $pauseBlock)
                                }
                            }
                        }
                        .padding(1)
                        
                        // MARK: Языки
                        viewGroupHeader(text: "Язык Библии")
                        viewSelectList(texts: languageTexts, keys: languageKeys, userDefaultsKeyName: "languageKey", selectedKey: $languageKey)
                            .padding(.vertical, -5)
                        
                        viewGroupHeader(text: "Перевод")
                        viewSelectList(texts: translateTexts, keys: translateKeys, userDefaultsKeyName: "translateKey", selectedKey: $translateKey)
                            .padding(.vertical, -5)
                        
                        viewGroupHeader(text: "Читает")
                        viewSelectList(texts: audioTexts, keys: audioKeys, userDefaultsKeyName: "audioKey", selectedKey: $audioKey)
                            .padding(.vertical, -5)
                    }
                    .padding(.horizontal, globalBasePadding)
                }
                .foregroundColor(.white)
            }
            
            // слой меню
            MenuView(showMenu: $showMenu,
                     selectedMenuItem: $selectedMenuItem
            )
            .offset(x: showMenu ? 0 : -getRect().width)
            
        }
        // подложка
        .background(
            Color("DarkGreen")
        )
    }
}

struct TestPageSetupView: View {
    
    @State var showMenu: Bool = false
    @State var selectedMenuItem: MenuItem = .main
    @State private var showFromRead: Bool = true
    
    @AppStorage("fontIncreasePercent") private var fontIncreasePercent: Double = 100.0
    
    var body: some View {
        PageSetupView(showMenu: $showMenu,
                      selectedMenuItem: $selectedMenuItem,
                      showFromRead: $showFromRead,
                      fontIncreasePercent: $fontIncreasePercent)
    }
}

#Preview {
    TestPageSetupView()
}
