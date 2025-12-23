import SwiftUI
import AVFoundation
import Combine

struct PageMultilingualConfigView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var settingsManager: SettingsManager
    
    @State var step: MultilingualStep
    private let initialStep: MultilingualStep
    var onSave: (MultilingualStep) -> Void
    
    init(step: MultilingualStep, onSave: @escaping (MultilingualStep) -> Void) {
        self.initialStep = step
        self._step = State(initialValue: step)
        self.onSave = onSave
    }
    
    // MARK: Languages and translations state
    @State private var isLanguagesLoading: Bool = true
    @State private var languageTexts: [String] = []
    @State private var languageKeys: [String]  = []
    
    @State private var translationsResponse: [Components.Schemas.TranslationModel] = []
    @State private var isTranslationsLoading: Bool = true
    @State private var translationKeys: [String]  = []
    @State private var translationTexts: [String] = []
    @State private var translationNames: [String] = []
    
    @State private var voiceTexts: [String] = []
    @State private var voiceKeys: [String]  = []
    @State private var voiceMusics: [Bool]  = []
    @State private var voiceDescriptions: [String] = []
    
    @State private var toast: FancyToast? = nil
    
    // Temporary selections
    @State private var selectedLanguage: String = ""
    @State private var selectedTranslation: String = ""
    @State private var selectedTranslationName: String = ""
    @State private var selectedVoice: String = ""
    @State private var selectedVoiceName: String = ""
    @State private var selectedVoiceMusic: Bool = false
    
    // Preview
    @State private var previewPlayer: AVPlayer?
    @State private var previewVoiceIndex: Int? = nil
    @State private var previewTimer: AnyCancellable? = nil
    @State private var previewTimeObserver: Any? = nil

    var body: some View {
        ZStack {
            Color("DarkGreen")
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button("settings.cancel_choice".localized) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("multilingual.config.title".localized) // Localized
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button("settings.save_choice".localized) {
                        saveStep()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(canSave ? Color("Mustard") : Color.gray)
                    .disabled(!canSave)
                }
                .padding()
                .background(Color("DarkGreen").brightness(0.05))
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // Language
                        viewGroupHeader(text: "settings.bible_language".localized)
                        if isLanguagesLoading {
                            ProgressView().tint(.white)
                        } else {
                            viewSelectList(texts: languageTexts,
                                           keys: languageKeys,
                                           selectedKey: $selectedLanguage,
                                           onSelect: { index in
                                stopVoicePreview()
                                selectedLanguage = languageKeys[index]
                                selectedTranslation = ""
                                selectedVoice = ""
                                fetchTranslations()
                            })
                        }
                        
                        // Translation
                        if !selectedLanguage.isEmpty {
                            viewGroupHeader(text: "settings.translation".localized)
                            if isTranslationsLoading {
                                ProgressView().tint(.white)
                            } else {
                                viewSelectList(texts: translationTexts,
                                               keys: translationKeys,
                                               selectedKey: $selectedTranslation,
                                               onSelect: { index in
                                    stopVoicePreview()
                                    selectedTranslation = translationKeys[index]
                                    selectedTranslationName = translationNames[index]
                                    selectedVoice = ""
                                    showAudios()
                                })
                            }
                        }
                        
                        // Voice
                        if !selectedTranslation.isEmpty {
                            viewGroupHeader(text: "settings.reader".localized)
                            viewSelectListWithPreview(texts: voiceTexts,
                                           keys: voiceKeys,
                                           selectedKey: $selectedVoice,
                                           descriptions: voiceDescriptions,
                                           onSelect: { index in
                                                selectedVoice = voiceKeys[index]
                                                selectedVoiceName = voiceTexts[index]
                                                selectedVoiceMusic = voiceMusics[index]
                                           },
                                           onPreview: { index in
                                                toggleVoicePreview(index: index)
                                           },
                                           isPlaying: { index in
                                                return previewVoiceIndex == index
                                           }
                            )
                        }
                        
                        // Speed Settings
                        viewGroupHeader(text: "settings.speed".localized)
                        HStack(spacing: 0) {
                            Button(action: {
                                if step.playbackSpeed > 0.5 {
                                    step.playbackSpeed -= 0.1
                                }
                            }) {
                                Image(systemName: "minus")
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.clear)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 50, height: 40)
                            
                            Divider().background(Color.white)
                            
                            Text(String(format: "%.1fx", step.playbackSpeed))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: 40)
                            
                            Divider().background(Color.white)
                            
                            Button(action: {
                                if step.playbackSpeed < 2.5 {
                                    step.playbackSpeed += 0.1
                                }
                            }) {
                                Image(systemName: "plus")
                                    .font(.title3)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.clear)
                                    .foregroundColor(.white)
                            }
                            .frame(width: 50, height: 40)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.white, lineWidth: 1)
                        )
                        .padding(.horizontal, 3)

                        // Font Settings
                        viewGroupHeader(text: "settings.font".localized)
                        HStack {
                            Text("\(Int(step.fontIncreasePercent))%")
                                .foregroundColor(.white)
                                .frame(width: 70)
                            
                            Spacer()
                            
                            HStack(spacing: 0) {
                                Button(action: {
                                    if step.fontIncreasePercent > 10 {
                                        step.fontIncreasePercent -= 10
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
                                    if step.fontIncreasePercent < 500 {
                                        step.fontIncreasePercent += 10
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
                            .frame(maxWidth: 200)
                            .frame(maxHeight: 42)
                            
                            Spacer()
                            
                            Button {
                                step.fontIncreasePercent = 100.0
                            } label: {
                                Text("settings.font.reset".localized)
                                    .foregroundColor(Color("Mustard"))
                                    .frame(width: 70)
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
        }
        .toastView(toast: $toast)
        .onAppear {
            initializeState()
        }
        .onDisappear {
            stopVoicePreview()
        }
    }
    
    var canSave: Bool {
        return !selectedLanguage.isEmpty && !selectedTranslation.isEmpty && !selectedVoice.isEmpty
    }
    
    func initializeState() {
        // Force update state from init parameter (fix for sticky state issues in sheets)
        self.step = self.initialStep
        
        // Prepare initial state from step
        if !step.languageCode.isEmpty {
            selectedLanguage = step.languageCode
             selectedTranslation = String(step.translationCode)
             selectedTranslationName = step.translationName
            selectedVoice = String(step.voiceCode)
            selectedVoiceName = step.voiceName
            selectedVoiceMusic = step.voiceMusic
        } else {
            // Default to current settings if new step
            selectedLanguage = settingsManager.language
            // Don't auto-set translation/voice for new step to force choice? 
            // Or better, set defaults.
            // Let's set defaults.
             selectedTranslation = String(settingsManager.translation)
             selectedTranslationName = settingsManager.translationName
             selectedVoice = String(settingsManager.voice)
             selectedVoiceName = settingsManager.voiceName
             selectedVoiceMusic = settingsManager.voiceMusic
             
             // Initialize font and speed from global settings / defaults
             step.fontIncreasePercent = settingsManager.fontIncreasePercent
             step.playbackSpeed = 1.0
        }
        
        fetchLanguages()
    }
    
    func saveStep() {
        step.languageCode = selectedLanguage
        step.translationCode = Int(selectedTranslation) ?? 0
        step.translationName = selectedTranslationName
        step.voiceCode = Int(selectedVoice) ?? 0
        step.voiceName = selectedVoiceName
        step.voiceMusic = selectedVoiceMusic
        // fontIncreasePercent is already bound to step
        
        // Find language name
        if let idx = languageKeys.firstIndex(of: selectedLanguage) {
             // Extract English name from "National (En)"
             // The format in fetchLanguages is "\(language.name_national) (\(language.name_en))"
             // I'll just store the text I have.
             // Ideally step should have languageName.
            step.languageName = languageTexts[idx]
        }
        
        onSave(step)
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: API Reused Logic
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
                
                // If selected language not in list, fallback
                if !languageKeys.contains(selectedLanguage), let first = languageKeys.first {
                    selectedLanguage = first
                }
                
                fetchTranslations()
                self.isLanguagesLoading = false
            } catch {
                self.isLanguagesLoading = false
                toast = FancyToast(type: .error, title: "error.title".localized, message: error.localizedDescription)
            }
        }
    }
    
    func fetchTranslations() {
        Task {
            do {
                self.isTranslationsLoading = true
                
                let response = try await settingsManager.client.get_translations(query: .init(language: self.selectedLanguage))
                self.translationsResponse = try response.ok.body.json
                
                self.translationKeys = []
                self.translationTexts = []
                self.translationNames = []
                for translation in self.translationsResponse {
                    self.translationKeys.append("\(translation.code)")
                    self.translationTexts.append("\(translation.description ?? translation.name) (\(translation.name))")
                    self.translationNames.append(translation.name)
                }
                
                // If selected translation not in list, select first
                if !translationKeys.contains(selectedTranslation), let firstReference = translationKeys.first, let firstName = translationNames.first {
                    selectedTranslation = firstReference
                    selectedTranslationName = firstName
                    // Also reset voice
                    selectedVoice = ""
                }
                
                showAudios()
                self.isTranslationsLoading = false
            } catch {
                self.isTranslationsLoading = false
                toast = FancyToast(type: .error, title: "error.title".localized, message: error.localizedDescription)
            }
        }
    }
    
    func showAudios() {
        self.voiceKeys = []
        self.voiceTexts = []
        self.voiceMusics = []
        self.voiceDescriptions = []
        
        if let translation = self.translationsResponse.first(where: { "\($0.code)" == self.selectedTranslation }) {
             for voice in translation.voices {
                self.voiceKeys.append("\(voice.code)")
                self.voiceTexts.append("\(voice.name)")
                self.voiceMusics.append(voice.is_music)
                self.voiceDescriptions.append(voice.description ?? "")
            }
        }
        
        // If selected voice not in list, select first
        if (!voiceKeys.contains(selectedVoice) || selectedVoice.isEmpty), let firstVoiceKey = voiceKeys.first {
            selectedVoice = firstVoiceKey
            if !voiceTexts.isEmpty {
                selectedVoiceName = voiceTexts[0]
                selectedVoiceMusic = voiceMusics[0]
            }
        }
    }
    
    // MARK: Voice preview
    func toggleVoicePreview(index: Int) {
        if previewVoiceIndex == index {
            stopVoicePreview()
            return
        }
        stopVoicePreview()
        
        let voiceCode = Int(voiceKeys[index]) ?? 0
        let translationCode = Int(selectedTranslation) ?? 0

        Task {
            do {
                let (_, audioVerses, firstUrl, _, _) = try await getExcerptTextualVersesOnline(
                    excerpts: "jhn 1",
                    client: settingsManager.client,
                    translation: translationCode,
                    voice: voiceCode
                )
                
                guard !firstUrl.isEmpty, let url = URL(string: firstUrl) else {
                    toast = FancyToast(type: .error, title: "error.title".localized, message: "error.audio.unavailable".localized)
                    return
                }
                
                let playerItem = AVPlayerItem(url: url)
                previewPlayer = AVPlayer(playerItem: playerItem)
                previewVoiceIndex = index
                
                if let firstVerse = audioVerses.first {
                    let startTime = CMTime(seconds: firstVerse.begin, preferredTimescale: 600)
                    await previewPlayer?.seek(to: startTime, toleranceBefore: .zero, toleranceAfter: .zero)
                }
                
                if audioVerses.count >= 3 {
                    let thirdVerseEndTime = CMTime(seconds: audioVerses[2].end, preferredTimescale: 600)
                    previewTimeObserver = previewPlayer?.addBoundaryTimeObserver(
                        forTimes: [NSValue(time: thirdVerseEndTime)],
                        queue: .main
                    ) {
                        self.stopVoicePreview()
                    }
                }
                
                previewPlayer?.play()
                
            } catch {
                toast = FancyToast(type: .error, title: "error.title".localized, message: "error.loading.audio".localized)
            }
        }
    }
    
    func stopVoicePreview() {
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
}
