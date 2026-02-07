import SwiftUI
import AVFoundation
import Combine

struct PageSetupView: View {
    private let examplePreviewHeight: CGFloat = 158
    
    @State private var toast: FancyToast? = nil
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    @Binding var showFromRead: Bool
    
    // Sample text preview state
    @State private var isExampleLoading: Bool = true
    @State private var exampleVerses: [BibleTextualVerseFull] = []
    @State private var exampleErrorText: String = ""
    @State private var exampleRefreshToken: Int = 0
    
    // MARK: Languages and translations
    
    // Separate state values so we don't persist invalid data
    @State private var isLanguagesLoading: Bool = true
    @State private var languageTexts: [String] = []
    @State private var languageKeys: [String]  = []
    @State private var language: String = "" // initialized in onAppear
    
    @State private var translationsResponse: [Components.Schemas.TranslationModel] = []
    
    @State private var isTranslationsLoading: Bool = true
    @State private var translationKeys: [String]  = []
    @State private var translationTexts: [String] = []
    @State private var translationNames: [String] = []
    @State private var translation: String = "" // initialized in onAppear
    @State private var translationName: String = ""
    
    @State private var voiceTexts: [String] = []
    @State private var voiceKeys: [String]  = []
    @State private var voiceMusics: [Bool]  = []
    @State private var voiceDescriptions: [String] = []
    @State private var voice: String = "" // initialized in onAppear
    @State private var voiceName: String = ""
    @State private var voiceMusic: Bool = false
    
    // Voice preview helpers
    @State private var previewPlayer: AVPlayer?
    @State private var previewVoiceIndex: Int? = nil
    @State private var previewTimer: AnyCancellable? = nil
    @State private var previewTimeObserver: Any? = nil
    @State private var expandedSelectionSection: SelectionAccordionSection? = nil
    
    init(showFromRead: Binding<Bool>) {
        self._showFromRead = showFromRead
    }

    private enum SelectionAccordionSection {
        case language
        case translation
        case voice
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                // MARK: Header
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
                    
                    Text("page.settings.title".localized)
                        .fontWeight(.bold)
                        .padding(.trailing, 32) // compensate menu button to keep title centered
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
                            
                            ViewInterfaceLanguage()
                        }
                        .padding(.horizontal, globalBasePadding)
                    }
                    .foregroundColor(.white)
                }
            }
            
        }
        
        // Background
        .background(
            Color("DarkGreen")
        )
        .toastView(toast: $toast)
        .onAppear {
            self.language = settingsManager.language
            self.translation = String(settingsManager.translation)
            self.translationName = settingsManager.translationName
            self.voice = String(settingsManager.voice)
            self.voiceName = settingsManager.voiceName
            fetchLanguages()
            loadExampleText(showLoader: true)
        }
        .onDisappear {
            // Stop preview when view disappears
            stopVoicePreview()
        }
    }
    
    // MARK: Font
    @ViewBuilder private func ViewFont() -> some View {
        VStack {
            viewGroupHeader(text: "settings.font".localized)
            
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
                    
                    Divider() // Divider between buttons
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
                    Text("settings.font.reset".localized)
                        .foregroundColor(Color("Mustard"))
                        .frame(width: 70)
                }
            }
            
            Text("settings.font.example".localized)
                .foregroundColor(.white.opacity(0.5))
            ZStack {
                if isExampleLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: examplePreviewHeight)
                } else if exampleErrorText != "" {
                    Text(exampleErrorText)
                        .foregroundColor(.pink)
                        .frame(maxWidth: .infinity)
                        .frame(height: examplePreviewHeight)
                } else if exampleVerses.isEmpty {
                    Text("settings.select_translation".localized)
                        .foregroundColor(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .frame(height: examplePreviewHeight)
                } else {
                    HTMLTextView(htmlContent: generateHTMLContent(verses: exampleVerses, fontIncreasePercent: settingsManager.fontIncreasePercent), scrollToVerse: .constant(nil), isScrollEnabled: false)
                        .frame(height: examplePreviewHeight)
                        .frame(maxWidth: .infinity)
                        .id("font_example_\(exampleRefreshToken)_\(Int(settingsManager.fontIncreasePercent))")
                }
            }
            .frame(height: examplePreviewHeight)
            .transaction { transaction in
                transaction.animation = nil
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        
    }
    
    // MARK: Pause
    @ViewBuilder private func ViewPause() -> some View {
        viewGroupHeader(text: "settings.pause".localized)
        VStack(spacing: 15) {
            viewEnumPicker(title: settingsManager.pauseType.displayName, selection: $settingsManager.pauseType)
            
            if settingsManager.pauseType != .none {
                // Duration controls
                if settingsManager.pauseType == .time {
                    HStack {
                        Text("settings.pause.make_pause".localized)
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
                        
                        Text("settings.pause.unit.seconds".localized)
                    }
                }
                
                // Pause trigger
                HStack {
                    Text("settings.pause.after_every".localized)
                        .frame(width: 140, alignment: .leading)
                    Spacer()
                    
                    viewEnumPicker(title: settingsManager.pauseBlock.displayName, selection: $settingsManager.pauseBlock)
                }
            }

            HStack {
                Toggle("settings.auto_next_chapter".localized, isOn: $settingsManager.autoNextChapter)
                    .toggleStyle(SwitchToggleStyle(tint: Color("DarkGreen-accent")))
            }
        }
        .padding(1)
    }
    
    // MARK: Language / translation / audio
    @ViewBuilder private func ViewLangTranslateAudio(proxy: ScrollViewProxy) -> some View {
        viewGroupHeader(text: "settings.translation_audio".localized)

        VStack(spacing: 10) {
            selectionAccordionSectionCard(
                section: .language,
                title: "settings.bible_language".localized,
                value: selectedLanguageLabel(),
                isLoading: isLanguagesLoading
            ) {
                if isLanguagesLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    compactSelectionList(
                        texts: languageTexts,
                        keys: languageKeys,
                        selectedKey: $language,
                        onSelect: { selectedLanguageIndex in
                            stopVoicePreview()
                            let selectedLanguage = languageKeys[selectedLanguageIndex]
                            transitionToSection(.translation) {
                                self.language = selectedLanguage
                                clearTranslationSelection()
                                clearVoiceSelection()
                                fetchTranslations()
                            }
                        }
                    )
                }
            }

            selectionAccordionSectionCard(
                section: .translation,
                title: "settings.translation".localized,
                value: selectedTranslationLabel(),
                isLoading: isTranslationsLoading
            ) {
                if isTranslationsLoading {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    compactSelectionList(
                        texts: translationTexts,
                        keys: translationKeys,
                        selectedKey: $translation,
                        onSelect: { selectedTranslateIndex in
                            stopVoicePreview()
                            let selectedTranslation = translationKeys[selectedTranslateIndex]
                            let selectedTranslationName = translationNames[selectedTranslateIndex]
                            transitionToSection(.voice) {
                                self.translation = selectedTranslation
                                self.translationName = selectedTranslationName
                                self.voice = ""
                                showAudios()
                                loadExampleText(showLoader: false)
                            }
                        }
                    )
                }
            }

            selectionAccordionSectionCard(
                section: .voice,
                title: "settings.reader".localized,
                value: selectedVoiceLabel(),
                isLoading: false
            ) {
                if voiceTexts.isEmpty {
                    Text("settings.select_translation".localized)
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    compactSelectionListWithPreview(
                        texts: voiceTexts,
                        keys: voiceKeys,
                        selectedKey: $voice,
                        descriptions: voiceDescriptions,
                        onSelect: { selectedTranslateIndex in
                            self.voice = voiceKeys[selectedTranslateIndex]
                            self.voiceName = voiceTexts[selectedTranslateIndex]
                            self.voiceMusic = voiceMusics[selectedTranslateIndex]
                            persistSelectionAfterVoiceChoice()
                            stopVoicePreview()
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedSelectionSection = nil
                            }
                        },
                        onPreview: { index in
                            toggleVoicePreview(index: index)
                        },
                        isPlaying: { index in
                            return previewVoiceIndex == index
                        }
                    )
                }
            }
        }
        
        Spacer()
            .id("bottom")
    }

    @ViewBuilder private func selectionAccordionSectionCard<Content: View>(
        section: SelectionAccordionSection,
        title: String,
        value: String,
        isLoading: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let isExpanded = expandedSelectionSection == section
        VStack(spacing: 0) {
            Button {
                toggleSelectionSection(section)
            } label: {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isExpanded ? Color("Mustard") : Color.white.opacity(0.35))
                        .frame(width: 3, height: 30)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(title)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(value)
                            .font(.callout)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    Spacer()
                    cardTrailing(isExpanded: isExpanded, isLoading: isLoading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)

                content()
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color("DarkGreen-light").opacity(isExpanded ? 0.9 : 0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isExpanded ? Color("Mustard").opacity(0.5) : Color.white.opacity(0.2),
                    lineWidth: isExpanded ? 1.1 : 1
                )
        )
    }

    @ViewBuilder private func compactSelectionList(
        texts: [String],
        keys: [String],
        selectedKey: Binding<String>,
        onSelect: @escaping (Int) -> Void = { _ in }
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(texts.indices, id: \.self) { index in
                let text = texts[index]
                let key = keys[index]
                Button {
                    selectedKey.wrappedValue = key
                    onSelect(index)
                } label: {
                    HStack {
                        Text(text)
                            .foregroundColor(selectedKey.wrappedValue == key ? Color("Mustard") : .white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        if selectedKey.wrappedValue == key {
                            Image(systemName: "checkmark")
                                .foregroundColor(Color("Mustard"))
                        }
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                if index < texts.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
    }

    @ViewBuilder private func compactSelectionListWithPreview(
        texts: [String],
        keys: [String],
        selectedKey: Binding<String>,
        descriptions: [String] = [],
        onSelect: @escaping (Int) -> Void = { _ in },
        onPreview: @escaping (Int) -> Void,
        isPlaying: @escaping (Int) -> Bool
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(texts.indices, id: \.self) { index in
                let text = texts[index]
                let key = keys[index]
                let description = index < descriptions.count ? descriptions[index] : ""

                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(text)
                            .foregroundColor(selectedKey.wrappedValue == key ? Color("Mustard") : .white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        if !description.isEmpty {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    Image(systemName: "checkmark")
                        .foregroundColor(Color("Mustard"))
                        .frame(width: 16)
                        .opacity(selectedKey.wrappedValue == key ? 1 : 0)
                    Button {
                        onPreview(index)
                    } label: {
                        Image(systemName: isPlaying(index) ? "stop.circle.fill" : "play.circle.fill")
                            .foregroundColor(Color("localAccentColor"))
                            .font(.system(size: 24))
                    }
                    .buttonStyle(.plain)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedKey.wrappedValue = key
                    onSelect(index)
                }
                .padding(.vertical, 10)

                if index < texts.count - 1 {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }
        }
    }

    @ViewBuilder private func cardTrailing(isExpanded: Bool, isLoading: Bool) -> some View {
        if isLoading {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.8)
        } else {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white.opacity(0.9))
                    .font(.system(size: 12, weight: .bold))
            }
        }
    }

    private func selectedLanguageLabel() -> String {
        guard let index = languageKeys.firstIndex(of: language), index < languageTexts.count else {
            return "-"
        }
        return languageTexts[index]
    }

    private func selectedTranslationLabel() -> String {
        guard let index = translationKeys.firstIndex(of: translation), index < translationTexts.count else {
            if !translation.isEmpty && !translationName.isEmpty {
                return translationName
            }
            return "settings.select_translation".localized
        }
        return translationTexts[index]
    }

    private func selectedVoiceLabel() -> String {
        guard let index = voiceKeys.firstIndex(of: voice), index < voiceTexts.count else {
            if !voice.isEmpty && !voiceName.isEmpty {
                return voiceName
            }
            return "settings.select_reader".localized
        }
        return voiceTexts[index]
    }

    private func toggleSelectionSection(_ section: SelectionAccordionSection) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSelectionSection == .voice {
                stopVoicePreview()
            }
            if expandedSelectionSection == section {
                expandedSelectionSection = nil
            } else {
                expandedSelectionSection = section
            }
        }
    }

    private func transitionToSection(
        _ next: SelectionAccordionSection,
        applySelection: @escaping () -> Void
    ) {
        if expandedSelectionSection == .voice && next != .voice {
            stopVoicePreview()
        }
        applySelection()
        withAnimation(.easeInOut(duration: 0.22)) {
            expandedSelectionSection = next
        }
    }
    
    func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        DispatchQueue.main.async {
            if animated {
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            } else {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    // Load example text
    func loadExampleText(showLoader: Bool = false) {
        Task {
            do {
                if showLoader || self.exampleVerses.isEmpty {
                    self.isExampleLoading = true
                }
                self.exampleErrorText = ""
                
                // Use current selection if available, otherwise use saved settings
                let translationToUse = Int(self.translation) ?? settingsManager.translation
                
                let (verses, _, _, _, _) = try await getExcerptTextualVersesOnline(excerpts: "jhn 1:1-3", client: settingsManager.client, translation: translationToUse, voice: 0)
                
                self.exampleVerses = verses
                self.isExampleLoading = false
                self.exampleRefreshToken += 1
            } catch {
                if self.exampleVerses.isEmpty {
                    self.exampleErrorText = "error.loading.example".localized
                }
                self.isExampleLoading = false
            }
        }
    }
    
    // MARK: API requests
    
    func fetchLanguages() {
        // Optimistically use cached data if available
        if !settingsManager.cachedLanguages.isEmpty {
             if settingsManager.cachedAllTranslations.isEmpty {
                 Task {
                     async let _ = settingsManager.fetchAllTranslations()
                     self.updateLanguagesList()
                 }
             } else {
                 self.updateLanguagesList()
             }
        } else {
            Task {
                do {
                    self.languageKeys = []
                    self.languageTexts = []
                    
                    // Fetch both concurrently
                    async let _ = settingsManager.fetchLanguages()
                    async let _ = settingsManager.fetchAllTranslations()
                    
                    // Wait for both
                    let _ = try await [try await settingsManager.fetchLanguages(), try await settingsManager.fetchAllTranslations()]
                    
                    self.updateLanguagesList()
                   
                    self.isLanguagesLoading = false
                } catch {
                    self.isLanguagesLoading = false
                    toast = FancyToast(type: .error, title: "error.title".localized, message: error.localizedDescription)
                }
            }
        }
    }
    
    func updateLanguagesList() {
        self.languageKeys = []
        self.languageTexts = []
        
        let languages = settingsManager.cachedLanguages
        
        for language in languages {
            self.languageKeys.append(language.alias)
            self.languageTexts.append("\(language.name_national) (\(language.name_en))")
        }

        if !language.isEmpty && !languageKeys.contains(language) {
            language = ""
            clearTranslationSelection()
            clearVoiceSelection()
        }
        
        fetchTranslations()
        self.isLanguagesLoading = false
    }
    
    func fetchTranslations() {
        // Use cached translations if available
        if !settingsManager.cachedAllTranslations.isEmpty {
            self.updateTranslationsList()
        } else {
            Task {
                try? await settingsManager.fetchAllTranslations()
                self.updateTranslationsList()
            }
        }
    }
    
    func updateTranslationsList() {
        self.isTranslationsLoading = true
        
        self.translationsResponse = settingsManager.getTranslations(for: self.language)
        
        self.translationKeys = []
        self.translationTexts = []
        self.translationNames = []
        for translation in self.translationsResponse {
            self.translationKeys.append("\(translation.code)")
            self.translationTexts.append("\(translation.description ?? translation.name) (\(translation.name))")
            self.translationNames.append(translation.name)
        }

        if translation.isEmpty {
            translationName = ""
        }

        if !translation.isEmpty {
            guard let selectedIndex = translationKeys.firstIndex(of: translation) else {
                clearTranslationSelection()
                clearVoiceSelection()
                showAudios()
                self.isTranslationsLoading = false
                return
            }
            translationName = translationNames[selectedIndex]
        }

        showAudios()
        self.isTranslationsLoading = false
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
        self.voiceMusics = []
        self.voiceDescriptions = []
        for translation in self.translationsResponse {
            if "\(translation.code)" == self.translation {
                for voice in translation.voices {
                    self.voiceKeys.append("\(voice.code)")
                    self.voiceTexts.append("\(voice.name)")
                    self.voiceMusics.append(voice.is_music)
                    self.voiceDescriptions.append(voice.description ?? "")
                }
                break
            }
        }

        if !voice.isEmpty {
            guard let selectedIndex = voiceKeys.firstIndex(of: voice) else {
                clearVoiceSelection()
                return
            }
            voiceName = voiceTexts[selectedIndex]
            voiceMusic = voiceMusics[selectedIndex]
        }
    }

    private func clearTranslationSelection() {
        translation = ""
        translationName = ""
        resetExamplePreview()
    }

    private func clearVoiceSelection() {
        voice = ""
        voiceName = ""
        voiceMusic = false
    }

    private func persistSelectionAfterVoiceChoice() {
        guard !language.isEmpty,
              let translationCode = Int(translation),
              let voiceCode = Int(voice) else {
            return
        }
        settingsManager.language = language
        settingsManager.translation = translationCode
        settingsManager.translationName = translationName
        settingsManager.voice = voiceCode
        settingsManager.voiceName = voiceName
        settingsManager.voiceMusic = voiceMusic
    }

    private func resetExamplePreview() {
        exampleVerses = []
        isExampleLoading = false
        exampleErrorText = ""
        exampleRefreshToken += 1
    }
    
    // MARK: Voice preview
    func toggleVoicePreview(index: Int) {
        // Stop if this voice is already playing
        if previewVoiceIndex == index {
            stopVoicePreview()
            return
        }
        
        // Stop previous playback
        stopVoicePreview()
        
        // Start playback for the new voice
        let voiceCode = Int(voiceKeys[index]) ?? 0
        
        Task {
            do {
                // Load audio for John chapter 1
                let (_, audioVerses, firstUrl, _, _) = try await getExcerptTextualVersesOnline(
                    excerpts: "jhn 1",
                    client: settingsManager.client,
                    translation: Int(self.translation) ?? settingsManager.translation,
                    voice: voiceCode
                )
                
                guard !firstUrl.isEmpty, let url = URL(string: firstUrl) else {
                    toast = FancyToast(type: .error, title: "error.title".localized, message: "error.audio.unavailable".localized)
                    return
                }
                
                // Create player
                let playerItem = AVPlayerItem(url: url)
                previewPlayer = AVPlayer(playerItem: playerItem)
                previewVoiceIndex = index
                
                // Seek to the beginning of the first verse
                if let firstVerse = audioVerses.first {
                    let startTime = CMTime(seconds: firstVerse.begin, preferredTimescale: 600)
                    await previewPlayer?.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
                }
                
                // Add observer to stop at the end of the third verse
                if audioVerses.count >= 3 {
                    let thirdVerseEndTime = CMTime(seconds: audioVerses[2].end, preferredTimescale: 600)
                    previewTimeObserver = previewPlayer?.addBoundaryTimeObserver(
                        forTimes: [NSValue(time: thirdVerseEndTime)],
                        queue: .main
                    ) {
                        self.stopVoicePreview()
                    }
                }
                
                // Start playback
                previewPlayer?.play()
                
            } catch {
                toast = FancyToast(type: .error, title: "error.title".localized, message: "error.loading.audio".localized)
            }
        }
    }
    
    func stopVoicePreview() {
        // Remove time observer
        if let observer = previewTimeObserver {
            previewPlayer?.removeTimeObserver(observer)
            previewTimeObserver = nil
        }
        
        previewPlayer?.pause()
        previewPlayer = nil
        previewVoiceIndex = nil
        previewTimer?.cancel()
        previewTimer = nil
    }
    
    // MARK: Interface Language
    @ViewBuilder private func ViewInterfaceLanguage() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            viewGroupHeader(text: "settings.language".localized)
            
            viewEnumPicker(title: localizationManager.currentLanguage.displayName, 
                          selection: $localizationManager.currentLanguage)
        }
        .padding(.bottom, 10)
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
