//
//  PageSetupView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI
import OpenAPIURLSession

struct PageSetupView: View {
    
    let client: any APIProtocol
    
    @State private var toast: FancyToast? = nil
    
    @ObservedObject var settingsManager = SettingsManager()
    @ObservedObject var windowsDataManager: WindowsDataManager
    
    @Binding var showFromRead: Bool
    
    // MARK: Языки и переводы
    
    @State private var isLanguagesLoading: Bool = true
    @State private var languageTexts: [String] = []
    @State private var languageKeys: [String]  = []
    @State private var languageKey: String = UserDefaults.standard.string(forKey: "languageKey") ?? "en"
    
    @State private var isTranslationsLoading: Bool = true
    
    
    let translateTexts = ["SYNO (Русский Синодальный)", "НРП (Новый Русский)", "BTI (под редакцией Кулаковых)"]
    let translateKeys  = ["syno",                       "nrp",                 "bti"]
    @State private var translateKey: String = UserDefaults.standard.string(forKey: "translateKey") ?? "syno"
    
    let audioTexts = ["Александр Бондаренко", "''Свет на востоке''"]
    let audioKeys  = ["bondarenko",           "eastlight"]
    @State private var audioKey = "bondarenko"
    
    
    init(windowsDataManager: WindowsDataManager, showFromRead: Binding<Bool>) {
        self.windowsDataManager = windowsDataManager
        self._showFromRead = showFromRead
        self.client = Client(serverURL: URL(string: "http://helper-vm-maria:8000")!, transport: URLSessionTransport())
    }
    
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
                                let (textVerses, _) = getExcerptTextualVerses(excerpts: "jhn 1:1-3")
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
                        if isLanguagesLoading {
                            Text("Loading languages...")
                        }
                        else {
                            viewSelectList(texts: languageTexts, keys: languageKeys,
                                           userDefaultsKeyName: "languageKey", selectedKey: $languageKey,
                                           onSelect: { selectedLanguageKey in
                                                print("Selected language key: \(selectedLanguageKey)")
                            })
                                .padding(.vertical, -5)
                        }
                        
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
        .toastView(toast: $toast)
        .onAppear {
            fetchLanguages()
        }
    }
    
    func fetchLanguages() {
        Task {
            do {
                let response = try await client.get_languages()
                let languages = try response.ok.body.json
                
                for language in languages {
                    self.languageKeys.append(language.alias)
                    self.languageTexts.append("\(language.name_national) (\(language.name_en))")
                }
                
                self.isLanguagesLoading = false
            } catch {
                self.isLanguagesLoading = false
                toast = FancyToast(type: .error, title: "Ошибка", message: error.localizedDescription)
            }
        }
    }
    
    func fetchTranslations() {
        Task {
            do {
                let response = try await client.get_translations(query: .init(languagess: "ru"))
                let translations = try response.ok.body.json
                
                for translation in translations {
                    //self.languageKeys.append(language.alias)
                    //self.languageTexts.append("\(language.name_national) (\(language.name_en))")
                    //translation.alias
                }
                
                self.isTranslationsLoading = false
            } catch {
                self.isTranslationsLoading = false
                toast = FancyToast(type: .error, title: "Ошибка", message: error.localizedDescription)
            }
        }
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
