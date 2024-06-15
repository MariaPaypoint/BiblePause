//
//  PageSetupView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI

// MARK: Константы
let pauseTypeTexts = ["Не делать пауз", "Приостанавливать на время", "Останавливать полностью"]
enum pauseTypeValues {
    case none
    case time
    case full
}

let pauseBlockTexts = ["стиха", "абзаца", "отрывка"]
enum pauseBlockValues {
    case verse
    case paragraph
    case fragment
}

let languageTexts = ["Английский", "Русский", "Украинский"]
enum languageValues {
    case english
    case russian
    case ukrainian
}

let translateTexts = ["SYNO (Русский Синодальный)", "НРП (Новый Русский)", "BTI (под редакцией Кулаковых)"]
let audioTexts = ["Александр Бондаренко", "''Свет на востоке''"]

struct PageSetupView: View {
    
    @Binding var showMenu: Bool
    @Binding var selectedMenuItem: MenuItem
    @Binding var showFromRead: Bool
    
    @State private var selectedFontIndex = -1
    
    @State private var fontIncreasePersent = 100.0
    
    // MARK: Паузы
    @State private var pauseTypeText = pauseTypeTexts[0]
    var pauseTypeValue: pauseTypeValues {
        let mapping: [String: pauseTypeValues] = [
            pauseTypeTexts[0]: .none,
            pauseTypeTexts[1]: .time,
            pauseTypeTexts[2]: .full
        ]
        return mapping[pauseTypeText] ?? .none
    }
    
    @State private var pauseLength = "3"
    
    @State private var pauseBlockText = pauseBlockTexts[0]
    var pauseBlock: pauseBlockValues {
        let mapping: [String: pauseBlockValues] = [
            pauseBlockTexts[0]: .verse,
            pauseBlockTexts[1]: .paragraph,
            pauseBlockTexts[2]: .fragment
        ]
        return mapping[pauseBlockText] ?? .verse
    }
    
    // MARK: Языки и переводы
    @State private var languageText = languageTexts[1]
    var language: languageValues {
        let mapping: [String: languageValues] = [
            languageTexts[0]: .english,
            languageTexts[1]: .russian,
            languageTexts[2]: .ukrainian
        ]
        return mapping[languageText] ?? .english
    }
    
    @State private var translateText = translateTexts[0]
    
    @State private var audioText = audioTexts[0]
    
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
                
                ScrollView() {
                    
                    // MARK: Шрифт
                    VStack {
                        viewGroup(text: "Шрифт")
                        
                        HStack {
                            Text("\(Int(fontIncreasePersent))%")
                                .foregroundColor(.white)
                                .frame(width: 70)
                            
                            Spacer()
                            
                            HStack(spacing: 0) {
                                Button(action: {
                                    fontIncreasePersent = fontIncreasePersent - 10
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
                                    fontIncreasePersent = fontIncreasePersent + 10
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
                            .frame(maxWidth: 200) // Максимальная ширина для примера
                            .frame(maxHeight: 42)
                            .padding()
                            
                            Spacer()
                            Text("Сброс")
                                .foregroundColor(Color("Mustard"))
                                .frame(width: 70)
                            
                        }
                        
                        Text("Пример:")
                            .foregroundColor(.white.opacity(0.5))
                        ScrollView() {
                            let (textVerses, _) = getExcerptTextVerses(excerpts: "jhn 1:1-3")
                            viewExcerpt(verses: textVerses, selectedId: 0)
                                .padding(.bottom, 20)
                                .id("top")
                                .font(.system(size: 10 * (1 + fontIncreasePersent / 100)))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 158)
                        //.background(.white.opacity(0.1))
                    }
                    
                    // MARK: Пауза
                    viewGroup(text: "Пауза")
                    VStack(spacing: 15) {
                        // тип остановки
                        Menu {
                            Picker("", selection: $pauseTypeText) {
                                ForEach(pauseTypeTexts, id: \.self) { text in
                                    Text(text)
                                }
                            }
                        } label: {
                            HStack {
                                Text(pauseTypeText)
                                
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .padding(.vertical, 9)
                            .padding(.horizontal, 12)
                            .background(Color("DarkGreen-light").opacity(0.6))
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.white.opacity(0.25), lineWidth: 1)
                            )
                        }
                        
                        if pauseTypeValue != .none {
                            // время
                            if pauseTypeValue == .time {
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
                                    //.frame(maxWidth: 100)
                                        .multilineTextAlignment(.center)
                                    
                                    Text("сек.")
                                }
                            }
                            
                            // после чего
                            HStack {
                                Text("После каждого")
                                    .frame(width: 140, alignment: .leading)
                                Spacer()
                                Menu {
                                    Picker("", selection: $pauseBlockText) {
                                        ForEach(pauseBlockTexts, id: \.self) { text in
                                            Text(text)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(pauseBlockText)
                                        
                                        Spacer()
                                        Image(systemName: "chevron.down")
                                    }
                                    .padding(.vertical, 9)
                                    .padding(.horizontal, 12)
                                    .background(Color("DarkGreen-light").opacity(0.6))
                                    .cornerRadius(5)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(.white.opacity(0.25), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding(1)
                    
                    // MARK: Языки
                    viewGroup(text: "Язык Библии")
                    OptionsView(arr: languageTexts, selectedText: $languageText)
                        .padding(.vertical, -5)
                    
                    viewGroup(text: "Перевод")
                    OptionsView(arr: translateTexts, selectedText: $translateText)
                        .padding(.vertical, -5)
                    
                    viewGroup(text: "Читает")
                    OptionsView(arr: audioTexts, selectedText: $audioText)
                        .padding(.vertical, -5)
                    
                }
                .foregroundColor(.white)
            }
            
            // слой меню
            MenuView(showMenu: $showMenu,
                     selectedMenuItem: $selectedMenuItem
            )
            .offset(x: showMenu ? 0 : -getRect().width)
            
        }
        .padding(.horizontal, globalBasePadding)
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
    
    var body: some View {
        PageSetupView(showMenu: $showMenu,
                      selectedMenuItem: $selectedMenuItem,
                      showFromRead: $showFromRead)
    }
}

#Preview {
    TestPageSetupView()
}
