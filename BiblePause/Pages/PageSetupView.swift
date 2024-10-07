//
//  PageSetupView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI

struct PageSetupView: View {
    
    @State private var toast: FancyToast? = nil
    
    @ObservedObject var settingsManager = SettingsManager()
    @EnvironmentObject var windowsDataManager: WindowsDataManager
    
    @Binding var showFromRead: Bool
    
    // MARK: Языки и переводы
    
    // отдельные настройки нужны для того, чтобы не соохранять некорректные данные
    @State private var isLanguagesLoading: Bool = true
    @State private var languageTexts: [String] = []
    @State private var languageKeys: [String]  = []
    @State private var language: String = "" // инициализируется в onAppear
    
    @State private var isTranslationsLoading: Bool = true
    @State private var translateTexts: [String] = []
    @State private var translateKeys: [String]  = []
    @State private var translate: String = "" // инициализируется в onAppear
    
    @State private var translateResponse: [Components.Schemas.TranslationModel] = []
    @State private var audioTexts: [String] = []
    @State private var audioKeys: [String]  = []
    @State private var audio: String = "" // инициализируется в onAppear
    
    
    init(showFromRead: Binding<Bool>) {
        self._showFromRead = showFromRead
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
                        MenuButtonView()
                            .environmentObject(windowsDataManager)
                    }
                    Spacer()
                    
                    Text("Настройки")
                        .fontWeight(.bold)
                        .padding(.trailing, 32) // компенсация меню, чтобы надпись была по центру
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal, globalBasePadding)
                
                ScrollViewReader { proxy in
                    ScrollView() {
                        VStack {
                            
                            ViewFont()
                            
                            ViewPause()
                            
                            ViewLangTranslateAudio(proxy: proxy)
                        }
                        .padding(.horizontal, globalBasePadding)
                    }
                    .foregroundColor(.white)
                }
            }
            // слой меню
            MenuView()
                .environmentObject(windowsDataManager)
                .offset(x: windowsDataManager.showMenu ? 0 : -getRect().width)
            
        }
        
        // подложка
        .background(
            Color("DarkGreen")
        )
        .toastView(toast: $toast)
        .onAppear {
            self.language = settingsManager.language
            self.translate = String(settingsManager.translation)
            self.audio = String(settingsManager.voice)
            fetchLanguages()
        }
    }
    
    // MARK: Шрифт
    @ViewBuilder private func ViewFont() -> some View {
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
        
    }
    
    // MARK: Пауза
    @ViewBuilder private func ViewPause() -> some View {
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
    }
    
    // MARK: Языки трио
    @ViewBuilder private func ViewLangTranslateAudio(proxy: ScrollViewProxy) -> some View {
        
        viewGroupHeader(text: "Язык Библии")
        if isLanguagesLoading {
            Text("Loading languages...")
        }
        else {
            viewSelectList(texts: languageTexts,
                           keys: languageKeys,
                           selectedKey: $language,
                           onSelect: { selectedLanguageKey in
                                settingsManager.language = selectedLanguageKey
                                self.translate = ""
                                self.audio = ""
                                fetchTranslations()
                                scrollToBottom(proxy: proxy)
                           }
            )
            .padding(.vertical, -5)
        }
        
        viewGroupHeader(text: "Перевод")
        viewSelectList(texts: translateTexts,
                       keys: translateKeys,
                       selectedKey: $translate,
                       onSelect: { selectedTranslateKey in
                            settingsManager.translation = Int(selectedTranslateKey)!
                            self.audio = ""
                            showAudios()
                            scrollToBottom(proxy: proxy)
                       }
        )
        .padding(.vertical, -5)
        
        viewGroupHeader(text: "Читает")
        viewSelectList(texts: audioTexts,
                       keys: audioKeys,
                       selectedKey: $audio,
                       onSelect: { selectedTranslateKey in
                            settingsManager.voice = Int(selectedTranslateKey)!
                            scrollToBottom(proxy: proxy)
                       }
        )
        .padding(.vertical, -5)
        
        
        // кнопки
        if settingsManager.language != self.language || String(settingsManager.translation) != self.translate || String(settingsManager.voice) != self.audio {
            
            let saveEnabled =  self.language != "" && self.translate != "" && self.audio != ""
            
            Button {
                if saveEnabled {
                    settingsManager.language = self.language
                    settingsManager.translation = Int(self.translate) ?? 0
                    settingsManager.voice = Int(self.audio) ?? 0
                    
                    toast = FancyToast(type: .success, title: "Успех", message: "Настройки сохранены")
                }
                else {
                    toast = FancyToast(type: .warning, title: "Внимание!", message: self.translate == "" ? "Выберите перевод" : "Выберите кто читает")
                }
            } label: {
                VStack {
                    Text("Сохранить выбор")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(5)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(saveEnabled ? Color("Marigold") : .white.opacity(0.2))
            .padding(.top, 25)
            //.disabled(saveDisabled)
            
            
            Button {
                self.language = settingsManager.language
                self.translate = String(settingsManager.translation)
                self.audio = String(settingsManager.voice)
                fetchLanguages()
                showAudios()
                //scrollToBottom(proxy: proxy)
                //toast = FancyToast(type: .info, title: "OK", message: "Значения восстановлены")
            } label: {
                VStack {
                    Text("Отменить выбор")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(5)
                }
            }
            //.buttonStyle(PlainButtonStyle())
            //.background(Color.clear)
            .buttonStyle(.borderedProminent)
            .tint(Color("DarkGreen"))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white, lineWidth: 1) // Рамка вокруг кнопки
            )
            .padding(.top, 5)
        }
        
        Spacer()
            .id("bottom")
    }
    
    func scrollToBottom(proxy: ScrollViewProxy) {
        print("scrollToBottom")
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    // MARK: Api-запросы
    
    func fetchLanguages() {
        Task {
            do {
                self.languageKeys = []
                self.languageTexts = []
                
                let response = try await windowsDataManager.client.get_languages()
                let languages = try response.ok.body.json
                
                for language in languages {
                    self.languageKeys.append(language.alias)
                    self.languageTexts.append("\(language.name_national) (\(language.name_en))")
                }
                fetchTranslations()
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
                self.isTranslationsLoading = true
                
                let response = try await windowsDataManager.client.get_translations(query: .init(language: self.language))
                self.translateResponse = try response.ok.body.json
                
                self.translateKeys = []
                self.translateTexts = []
                for translation in self.translateResponse {
                    self.translateKeys.append("\(translation.code)")
                    self.translateTexts.append("\(translation.description ?? translation.name) (\(translation.name))")
                }
                showAudios()
                self.isTranslationsLoading = false
            } catch {
                self.isTranslationsLoading = false
                toast = FancyToast(type: .error, title: "Ошибка", message: error.localizedDescription)
            }
        }
    }
    
    func showAudios() {
        
        self.audioKeys = []
        self.audioTexts = []
        for translation in self.translateResponse {
            if "\(translation.code)" == self.translate {
                for voice in translation.voices {
                    self.audioKeys.append("\(voice.code)")
                    self.audioTexts.append("\(voice.name)")
                }
                break
            }
        }
    }
}

struct TestPageSetupView: View {
    
    @State private var showFromRead: Bool = true
    @StateObject var windowsDataManager = WindowsDataManager()
    
    var body: some View {
        PageSetupView(showFromRead: $showFromRead)
            .environmentObject(windowsDataManager)
    }
}

#Preview {
    TestPageSetupView()
}
