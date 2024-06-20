//
//  PageSetupView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI

struct PageSetupView: View {
    
    @ObservedObject var settingsManager = SettingsManager()
    @ObservedObject var windowsDataManager: WindowsDataManager
    
    @Binding var showFromRead: Bool
    
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
                        MenuButtonView(windowsDataManager: windowsDataManager)
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
                                Text("\(Int(settingsManager.fontIncreasePercent))%")
                                    .foregroundColor(.white)
                                    .frame(width: 70)
                                
                                Spacer()
                                
                                HStack(spacing: 0) {
                                    Button(action: {
                                        if settingsManager.fontIncreasePercent > 10 {
                                            settingsManager.fontIncreasePercent = settingsManager.fontIncreasePercent - 10
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
                                        if settingsManager.fontIncreasePercent < 500 {
                                            settingsManager.fontIncreasePercent = settingsManager.fontIncreasePercent + 10
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
                                    settingsManager.fontIncreasePercent = 100.0
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
                                viewExcerpt(verses: textVerses, fontIncreasePercent: settingsManager.fontIncreasePercent)
                                    .padding(.bottom, 20)
                                    .id("top")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 158)
                        }
                        
                        // MARK: Пауза
                        viewGroupHeader(text: "Пауза")
                        VStack(spacing: 15) {
                            viewEnumPicker(title: settingsManager.pauseType.displayName, selection: $settingsManager.pauseType)
                            
                            if settingsManager.pauseType != .none {
                                // время
                                if settingsManager.pauseType == .time {
                                    HStack {
                                        Text("Делать паузу")
                                            .frame(width: 140, alignment: .leading)
                                        Spacer()
                                        TextField("", text: Binding(
                                            get: {
                                                String(settingsManager.pauseLength)
                                            },
                                            set: { newValue in
                                                if let value = Double(newValue) {
                                                    settingsManager.pauseLength = value
                                                }
                                            }
                                        ))
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
                                    
                                    viewEnumPicker(title: settingsManager.pauseBlock.displayName, selection: $settingsManager.pauseBlock)
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
            MenuView(windowsDataManager: windowsDataManager)
                .offset(x: windowsDataManager.showMenu ? 0 : -getRect().width)
            
        }
        // подложка
        .background(
            Color("DarkGreen")
        )
    }
}

struct TestPageSetupView: View {
    
    @State private var showFromRead: Bool = true
    @StateObject var windowsDataManager = WindowsDataManager()
    
    var body: some View {
        PageSetupView(windowsDataManager: windowsDataManager,
                      showFromRead: $showFromRead)
    }
}

#Preview {
    TestPageSetupView()
}
