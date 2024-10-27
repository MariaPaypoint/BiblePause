//
//  PageReadView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI
import AVFoundation
import Combine
import OpenAPIRuntime

struct PageReadView: View {
    
    @EnvironmentObject var settingsManager: SettingsManager
    
    @StateObject var audiopleer = PlayerModel()
    
    @State private var showSelection = false
    @State private var showSetup = false
    
    //@State private var errorDescription: String = ""
    
    @State private var textVerses: [BibleTextualVerseFull] = []
    //@State private var audioVerses: [BibleAudioVerseFull] = []
    @State private var currentVerseNumber: Int? // = 0
    
    @State private var showAudioPanel = true
    
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    
    @State private var isTextLoading: Bool = true
    @State private var toast: FancyToast? = nil
    
    @State var scrollToVerseId: Int?
    
    @State var oldExcerpt: String = "" // значение до клика на выбор
    @State var oldTranslation: Int = 0
    @State var oldFontIncreasePercent: Double = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                VStack(spacing: 0) {
                    
                    // MARK: Шапка
                    HStack(alignment: .center) {
                        MenuButtonView()
                            .environmentObject(settingsManager)
                        
                        Spacer()
                        
                        // заголовок, который ведет на выбор главы
                        Button {
                            ///player.pause()
                            
                            withAnimation(Animation.easeInOut(duration: 1)) {
                                //selectedMenuItem = .select
                                oldExcerpt = settingsManager.currentExcerpt
                                showSelection = true
                            }
                        } label: {
                            VStack(spacing: 0) {
                                Text(settingsManager.currentExcerptTitle)
                                    .fontWeight(.bold)
                                Text(settingsManager.currentExcerptSubtitle.uppercased())
                                    .foregroundColor(Color("Mustard"))
                                    .font(.footnote)
                                    .fontWeight(.bold)
                            }
                            .padding(.top, 6)
                        }
                        
                        Spacer()
                        
                        // кнопка настроек
                        Button {
                            withAnimation(Animation.easeInOut(duration: 1)) {
                                oldTranslation = settingsManager.translation
                                oldFontIncreasePercent = settingsManager.fontIncreasePercent
                                showSetup = true
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 26))
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, globalBasePadding)
                    .padding(.bottom, 5)
                    
                    // MARK: Текст
                    
                    if isTextLoading {
                        Spacer()
                        Text("Текст загружается...")
                            .foregroundColor(.white)
                        Spacer()
                    }
                    else {
                        HTMLTextView(htmlContent: generateHTMLContent(verses: textVerses, fontIncreasePercent: settingsManager.fontIncreasePercent),
                                     scrollToVerse: $currentVerseNumber)
                        .mask(LinearGradient(gradient: Gradient(colors: [Color.black, Color.black, Color.black.opacity(0)]),
                                             startPoint: .init(x: 0.5, y: 0.9), // Начало градиента на 90% высоты
                                             endPoint: .init(x: 0.5, y: 1.0)) // Конец градиента в самом низу
                        )
                        .padding(12)
                    }
                    
                    // MARK: Аудио-панель
                    viewAudioPanel()
                    
                }
                
                // подложка
                .background(
                    Color("DarkGreen")
                )
                
                // слой меню
                MenuView()
                    .environmentObject(settingsManager)
                    .offset(x: settingsManager.showMenu ? 0 : -getRect().width)
            }
            .toastView(toast: $toast)
            
            .fullScreenCover(isPresented: $showSelection, onDismiss: {
                Task {
                    if oldExcerpt != settingsManager.currentExcerpt {
                        await updateExcerpt(proxy: proxy)
                    }
                }
            })
            {
                PageSelectView(showFromRead: $showSelection)
                    .environmentObject(settingsManager)
            }
            
            .fullScreenCover(isPresented: $showSetup, onDismiss: {
                Task {
                    if oldTranslation != settingsManager.translation || oldFontIncreasePercent != settingsManager.fontIncreasePercent {
                        await updateExcerpt(proxy: proxy)
                    }
                }
            })
            {
                PageSetupView(showFromRead: $showSetup)
                    .environmentObject(settingsManager)
            }
            
            .onAppear {
                Task {
                    await updateExcerpt(proxy: proxy)
                    audiopleer.onEndVerse = onEndVerse
                    audiopleer.onStartVerse = onStartVerse
                    audiopleer.setSpeed(speed: Float(self.settingsManager.currentSpeed))
                    self.scrollViewProxy = proxy
                }
                
                scrollToVerseId = nil
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // MARK: После выбора
    func updateExcerpt(proxy: ScrollViewProxy) async {
        do {
            self.isTextLoading = true
            
            //let (thistextVerses, isSingleChapter) = getExcerptTextualVerses(excerpts: settingsManager.currentExcerpt)
            // textVerses = thistextVerses
            //let (audioVerses, err) = getExcerptAudioVerses(textVerses: textVerses)
            ///self.audioVerses = audioVerses
            //self.errorDescription = err
            //let voice = globalBibleAudio.getCurrentVoice()
            //let (book, chapter) = getExcerptBookChapterDigitCode(verses: textVerses)
            //let address = "https://500:3490205720348012725@assets.christedu.ru/data/translations/ru/\(voice.translation)/audio/\(voice.code)/\(book)/\(chapter).mp3"
            //let address = "http://500:3490205720348012725@192.168.130.169:8055/data/translations/ru/\(voice.translation)/audio/\(voice.code)/\(book)/\(chapter).mp3"
            //let address = "https://4bbl.ru/data/\(voice.translation)-\(voice.code)/\(book)/\(chapter).mp3"
            
            //guard let url = URL(string: address) else {
            //    self.errorDescription = "URL not found: \(address)"
            //    return
            //}
            //let url = try URL(string: address)
            
            let (thisTextVerses, audioVerses, firstUrl, isSingleChapter) = try await getExcerptTextualVersesOnline(excerpts: settingsManager.currentExcerpt, client: settingsManager.client, translation: settingsManager.translation, voice: settingsManager.voice)
            textVerses = thisTextVerses
            //print(isSingleChapter)
            let (from, to) = getExcerptPeriod(audioVerses: audioVerses)
            
            guard let url = URL(string: firstUrl) else {
                throw NSError(domain: "", code: 404, userInfo: [NSLocalizedDescriptionKey: "URL not found: \(firstUrl)"])
            }
            
            let playerItem = AVPlayerItem(url: url)
            audiopleer.setItem(playerItem: playerItem, periodFrom: isSingleChapter ? 0 : from, periodTo: isSingleChapter ? 0 : to, audioVerses: audioVerses)
            
            // листание наверх
            withAnimation {
                proxy.scrollTo("top", anchor: .top)
            }
            
            settingsManager.currentBookId = textVerses[0].bookDigitCode
            settingsManager.currentChapterId = textVerses[0].chapterDigitCode
            
            self.currentVerseNumber = -1
        } catch {
            print("Ошибка: \(error)")
            toast = FancyToast(type: .error, title: "Ошибка загрузки данных", message: error.localizedDescription)
        }
        self.isTextLoading = false
    }
    
    // MARK: Обработчики
    func onStartVerse(_ cur: Int) {
        //print(cur)
        
        //guard let proxy = scrollViewProxy else {
        //    return
        //}
        // прокрутка до текущего стиха
        //withAnimation {
            //proxy.scrollTo("verse_number_\(cur)", anchor: .top)
        //}
        
        if settingsManager.pauseBlock == .paragraph {
            if settingsManager.pauseType == .time {
                if textVerses[cur].startParagraph && cur > 0 {
                    audiopleer.breakForSeconds(settingsManager.pauseLength)
                    DispatchQueue.main.asyncAfter(deadline: .now() + settingsManager.pauseLength) {
                        self.currentVerseNumber = textVerses[cur].number
                    }
                    return
                }
            }
            else if settingsManager.pauseType == .full {
                audiopleer.doPlayOrPause()
                return
            }
        }
        
        self.currentVerseNumber = textVerses[cur].number
        
    }
    
    func onEndVerse() {
        // если нужна пауза - сделать ее (это событие не вызывается после последнего стиха и полной остановки)
        if settingsManager.pauseBlock == .verse {
            if settingsManager.pauseType == .time {
                audiopleer.breakForSeconds(settingsManager.pauseLength)
            }
            else if settingsManager.pauseType == .full {
                audiopleer.doPlayOrPause()
            }
        }
        
        
    }
    
    // MARK: Панель с плеером
    @ViewBuilder private func viewAudioPanel() -> some View {
        
        VStack(spacing: 0) {
            viewAudioHide()
            
            VStack {
                viewAudioInfo()
                viewAudioTimeline()
                viewAudioButtons()
            }
            .frame(height: showAudioPanel ? nil : 0)
            .opacity(showAudioPanel ? 1 : 0)
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: showAudioPanel ? 240 : 45)
        .padding(.horizontal, globalBasePadding)
        .background(Color("DarkGreen-light"))
        .clipShape(
            .rect(
                topLeadingRadius: 25,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 25
            )
        )
    }
    
    // MARK: Панель - сворачивание/разворачивание
    @ViewBuilder private func viewAudioHide() -> some View {
        Button {
            withAnimation {
                showAudioPanel.toggle()
            }
        } label: {
            VStack {
                Image(systemName: showAudioPanel ? "chevron.compact.down" : "chevron.compact.up")
                    .font(.system(size: 36))
                    .padding(.top, 7)
                    .padding(.bottom, 7)
                    .foregroundColor(Color("DarkGreen"))
            }
            .frame(maxWidth: .infinity)
        }
        
    }
    
    // MARK: Панель - информация
    @ViewBuilder private func viewAudioInfo() -> some View {
        HStack {
            Text(settingsManager.translationName)
                .foregroundColor(Color("DarkGreen"))
                .font(.footnote)
                .padding(4)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color("localAccentColor"))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("ЧИТАЕТ:")
                    .foregroundStyle(Color("localAccentColor").opacity(0.5))
                    .font(.caption2)
                Text(settingsManager.voiceName)
                    .foregroundStyle(Color("localAccentColor"))
                    .font(.footnote)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("ПАУЗА:")
                    .foregroundStyle(Color("localAccentColor").opacity(0.5))
                    .font(.caption2)
                Text("\(String(format: "%g", settingsManager.pauseLength)) сек./\(settingsManager.pauseBlock.shortName)")
                    .foregroundStyle(Color("localAccentColor"))
                    .font(.footnote)
            }
            //Spacer()
            //Image(systemName: "gearshape.fill")
            //    .imageScale(.large)
            //    .foregroundStyle(Color("localAccentColor"))
        }
    }
    
    // MARK: Панель - Timeline
    @ViewBuilder private func viewAudioTimeline() -> some View {
        VStack(spacing: 0) {
            ZStack {
                Slider(value: $audiopleer.currentTime, in: 0...audiopleer.currentDuration, onEditingChanged: audiopleer.sliderEditingChanged)
                    .accentColor(Color("localAccentColor"))
                    .onAppear {
                        let progressCircleConfig = UIImage.SymbolConfiguration(scale: .small)
                        UISlider.appearance()
                            .setThumbImage(UIImage(systemName: "circle.fill",
                                                   withConfiguration: progressCircleConfig), for: .normal)
                        
                    }
                    .disabled(audiopleer.state == .waitingForSelection || audiopleer.state == .buffering)
                
                // подсветка текущего отрывка
                if audiopleer.periodTo > 0 {
                    
                    // https://stackoverflow.com/a/62641399
                    let frameWidth: Double = UIScreen.main.bounds.size.width - globalBasePadding*2
                    let point: Double = frameWidth / audiopleer.currentDuration
                    
                    let pointStart: Double = Double(audiopleer.periodFrom) * point
                    let pointCenter: Double = audiopleer.currentTime * point
                    let pointEnd: Double = Double(audiopleer.periodTo == 0 ? audiopleer.currentDuration : audiopleer.periodTo) * point
                    
                    let circleLeftSpace: Double = 13 * audiopleer.currentTime / audiopleer.currentDuration
                    let circleRightSpace: Double = 13 - circleLeftSpace
                    
                    let firstLeading: Double = pointStart
                    let firstTrailing: Double = frameWidth - (pointEnd > pointCenter - circleLeftSpace ? pointCenter - circleLeftSpace : pointEnd)
                    
                    let secondLeading: Double = (pointCenter + circleRightSpace > pointStart ? pointCenter + circleRightSpace : pointStart)
                    let secondTrailing: Double = frameWidth - pointEnd
                    
                    if pointCenter > pointStart {
                        Rectangle()
                            .fill(Color("localAccentColor"))
                            .padding(.leading, firstLeading)
                            .padding(.trailing, firstTrailing)
                            .frame(width: frameWidth, height: 4)
                            .padding(.top, -0.9)
                        //.blendMode(.multiply)
                    }
                    
                    if pointEnd > pointCenter {
                        Rectangle()
                            .fill(Color("localAccentColor").opacity(0.2))
                            .padding(.leading, secondLeading)
                            .padding(.trailing, secondTrailing)
                            .frame(width: frameWidth, height: 4)
                            .padding(.top, -0.9)
                        //.blendMode(.multiply)
                    }
                }
            }
            HStack {
                // время
                Text("\(formatTime(audiopleer.currentTime))")
                    .foregroundStyle(Color("Mustard"))
                Spacer()
                Text("\(formatTime(audiopleer.currentDuration))")
                    .foregroundStyle(Color("localAccentColor").opacity(0.4))
            }
            .font(.subheadline)
        }
        .padding(.top, globalBasePadding)
        
    }
    
    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: Панель - AudioButtons
    @ViewBuilder fileprivate func viewAudioButtons() -> some View {
        
        let buttonsColor = audiopleer.state == .buffering ? Color("localAccentColor").opacity(0.4) : Color("localAccentColor")
        
        HStack {
            
            // Previous chapter
            Button {
                
            } label: {
                Image(systemName: "backward.frame.fill")
            }
            Spacer()
            
            // Restart отрывка
            Button {
                audiopleer.restart()
            } label: {
                Image(systemName: "gobackward")
                    .foregroundColor(buttonsColor)
            }
            Spacer()
            
            // Previos verse
            Button {
                audiopleer.previousVerse()
            } label: {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .foregroundColor(buttonsColor)
            }
            Spacer()
            
            // Play/Pause
            Button {
                audiopleer.doPlayOrPause()
            } label: {
                
                HStack {
                    switch audiopleer.state {
                    case .playing:
                        Image(systemName: "pause.circle.fill")
                    case .autopausing:
                        Image(systemName: "hourglass.circle.fill")
                    default:
                        Image(systemName: "play.circle.fill")
                    }
                }
                    .font(.system(size: 55))
                    .foregroundColor(buttonsColor)
            }
            Spacer()
            
            // Next verse
            Button {
                audiopleer.nextVerse()
            } label: {
                Image(systemName: "arrowshape.turn.up.right.fill")
                    .foregroundColor(buttonsColor)
            }
            Spacer()
            
            // Speed
            Button {
                audiopleer.changeSpeed()
                settingsManager.currentSpeed = Double(audiopleer.currentSpeed)
            } label: {
                Text(audiopleer.currentSpeed == 1 ? "x1" : String(format: "%.1f", audiopleer.currentSpeed))
                    .font(.system(size: 20))
                    .foregroundColor(buttonsColor)
            }
            Spacer()
            
            // Next chapter
            Button {
                
            } label: {
                Image(systemName: "forward.frame.fill")
            }
            
        }
        .foregroundColor(Color("localAccentColor"))
    }
}

// MARK: Preview

struct TestPageReadView: View {
    
    var body: some View {
        PageReadView()
            .environmentObject(SettingsManager())
    }
}

#Preview {
    TestPageReadView()
}

