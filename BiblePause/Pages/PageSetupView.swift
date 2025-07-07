//
//  PageSetupView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI

struct PageSetupView: View {
    
    @State private var toast: FancyToast? = nil
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Binding var showFromRead: Bool
    
    // Для примера отображения текста
    @State private var isExampleLoading: Bool = true
    @State private var exampleVerses: [BibleTextualVerseFull] = []
    @State private var exampleErrorText: String = ""
    
    // MARK: Языки и переводы
    
    // отдельные настройки нужны для того, чтобы не соохранять некорректные данные
    @State private var isLanguagesLoading: Bool = true
    @State private var languageTexts: [String] = []
    @State private var languageKeys: [String]  = []
    @State private var language: String = "" // инициализируется в onAppear
    
    @State private var translationsResponse: [Components.Schemas.TranslationModel] = []
    
    @State private var isTranslationsLoading: Bool = true
    @State private var translationKeys: [String]  = []
    @State private var translationTexts: [String] = []
    @State private var translationNames: [String] = []
    @State private var translation: String = "" // инициализируется в onAppear
    @State private var translationName: String = ""
    
    @State private var voiceTexts: [String] = []
    @State private var voiceKeys: [String]  = []
    @State private var voiceMusics: [Bool]  = []
    @State private var voice: String = "" // инициализируется в onAppear
    @State private var voiceName: String = ""
    @State private var voiceMusic: Bool = false
    
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
                            .environmentObject(settingsManager)
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
                            
                            ViewAutoNextChapter()
                            
                            ViewLangTranslateAudio(proxy: proxy)
                        }
                        .padding(.horizontal, globalBasePadding)
                    }
                    .foregroundColor(.white)
                }
            }
            // слой меню
            MenuView()
                .environmentObject(settingsManager)
                .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
            
        }
        
        // подложка
        .background(
            Color("DarkGreen")
        )
        .toastView(toast: $toast)
        .onAppear {
            self.language = settingsManager.language
            self.translation = String(settingsManager.translation)
            self.voice = String(settingsManager.voice)
            fetchLanguages()
            loadExampleText()
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
                if isExampleLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                } else if exampleErrorText != "" {
                    Text(exampleErrorText)
                        .foregroundColor(.pink)
                        .frame(maxWidth: .infinity)
                        .padding(20)
                } else {
                    viewExcerpt(verses: exampleVerses, fontIncreasePercent: settingsManager.fontIncreasePercent)
                        .padding(.bottom, 20)
                        .id("top")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
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
                        
                        HStack(spacing: 0) {
                            Button(action: {
                                if settingsManager.pauseLength >= 1 {
                                    settingsManager.pauseLength -= 1
                                }
                            }) {
                                Image(systemName: "minus")
                                    .padding(10)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            
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
                            .background(Color("DarkGreen-light").opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(.white.opacity(0.25), lineWidth: 1)
                            )
                            .multilineTextAlignment(.center)
                            
                            Button(action: {
                                settingsManager.pauseLength += 1
                            }) {
                                Image(systemName: "plus")
                                    .padding(10)
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(.white.opacity(0.4), lineWidth: 1)
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.clear)
                        )
                        
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
    
    // MARK: Автоматический переход к следующей главе
    @ViewBuilder private func ViewAutoNextChapter() -> some View {
        viewGroupHeader(text: "Проигрыватель")
        VStack(spacing: 15) {
            HStack {
                Toggle("Автопереход к следующей главе", isOn: $settingsManager.autoNextChapter)
                    .toggleStyle(SwitchToggleStyle(tint: Color("DarkGreen-accent")))
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
                           onSelect: { selectedLanguageIndex in
                                self.language = languageKeys[selectedLanguageIndex]
                                self.translation = ""
                                self.voice = ""
                                fetchTranslations()
                                scrollToBottom(proxy: proxy)
                           }
            )
            .padding(.vertical, -5)
        }
        
        viewGroupHeader(text: "Перевод")
        viewSelectList(texts: translationTexts,
                       keys: translationKeys,
                       selectedKey: $translation,
                       onSelect: { selectedTranslateIndex in
                            self.translation = translationKeys[selectedTranslateIndex]
                            self.translationName = translationNames[selectedTranslateIndex]
                            self.voice = ""
                            showAudios()
                            scrollToBottom(proxy: proxy)
                       }
        )
        .padding(.vertical, -5)
        
        viewGroupHeader(text: "Читает")
        viewSelectList(texts: voiceTexts,
                       keys: voiceKeys,
                       selectedKey: $voice,
                       onSelect: { selectedTranslateIndex in
                            self.voice = voiceKeys[selectedTranslateIndex]
                            self.voiceName = voiceTexts[selectedTranslateIndex]
                            self.voiceMusic = voiceMusics[selectedTranslateIndex]
                            scrollToBottom(proxy: proxy)
                       }
        )
        .padding(.vertical, -5)
        
        
        // кнопки
        if settingsManager.language != self.language || String(settingsManager.translation) != self.translation || String(settingsManager.voice) != self.voice {
            
            let saveEnabled =  self.language != "" && self.translation != "" && self.voice != ""
            
            Button {
                if saveEnabled {
                    //settingsManager.language = self.language
                    //settingsManager.translation = Int(self.translation) ?? 0
                    //settingsManager.voice = Int(self.voice) ?? 0
                    settingsManager.language = self.language
                    settingsManager.translation = Int(self.translation)!
                    settingsManager.translationName = self.translationName
                    settingsManager.voice = Int(self.voice)!
                    settingsManager.voiceName = self.voiceName
                    settingsManager.voiceMusic = self.voiceMusic
                    
                    // загрузить инфу о переводе
                    //fetchTranslationInfo()
                    
                    //toast = FancyToast(type: .success, title: "Успех", message: "Настройки сохранены")
                }
                else {
                    toast = FancyToast(type: .warning, title: "Внимание!", message: self.translation == "" ? "Выберите перевод" : "Выберите кто читает")
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
                self.translation = String(settingsManager.translation)
                self.voice = String(settingsManager.voice)
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
        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    // Загрузка примера текста
    func loadExampleText() {
        Task {
            do {
                self.isExampleLoading = true
                self.exampleErrorText = ""
                
                let (verses, _, _, _, _) = try await getExcerptTextualVersesOnline(excerpts: "jhn 1:1-3", client: settingsManager.client, translation: settingsManager.translation, voice: settingsManager.voice)
                
                self.exampleVerses = verses
                self.isExampleLoading = false
            } catch {
                self.exampleErrorText = "Ошибка загрузки примера"
                self.isExampleLoading = false
            }
        }
    }
    
    // MARK: Api-запросы
    
    func fetchLanguages() {
        Task {
            do {
                self.languageKeys = []
                self.languageTexts = []
                
                let response = try await settingsManager.client.get_languages()
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
                
                let response = try await settingsManager.client.get_translations(query: .init(language: self.language))
                self.translationsResponse = try response.ok.body.json
                
                self.translationKeys = []
                self.translationTexts = []
                for translation in self.translationsResponse {
                    self.translationKeys.append("\(translation.code)")
                    self.translationTexts.append("\(translation.description ?? translation.name) (\(translation.name))")
                    self.translationNames.append(translation.name)
                }
                showAudios()
                self.isTranslationsLoading = false
            } catch {
                self.isTranslationsLoading = false
                toast = FancyToast(type: .error, title: "Ошибка", message: error.localizedDescription)
            }
        }
    }
    
    /*
    func fetchTranslationInfo() {
        Task {
            do {
                //self.isTranslationsLoading = true
                
                let response = try await settingsManager.client.get_translation_info(query: .init(translation: Int(self.translation)!))
                let translationInfoResponse = try response.ok.body.json
                
                settingsManager.translationInfo = translationInfoResponse
                
                //self.isTranslationsLoading = false
            } catch {
                //self.isTranslationsLoading = false
                toast = FancyToast(type: .error, title: "Ошибка", message: error.localizedDescription)
            }
        }
    }
    */
    
    func showAudios() {
        
        self.voiceKeys = []
        self.voiceTexts = []
        for translation in self.translationsResponse {
            if "\(translation.code)" == self.translation {
                for voice in translation.voices {
                    self.voiceKeys.append("\(voice.code)")
                    self.voiceTexts.append("\(voice.name)")
                    self.voiceMusics.append(voice.is_music)
                }
                break
            }
        }
    }
}

struct TestPageSetupView: View {
    
    @State private var showFromRead: Bool = true
    
    var body: some View {
        PageSetupView(showFromRead: $showFromRead)
            .environmentObject(SettingsManager())
    }
}

#Preview {
    TestPageSetupView()
}
