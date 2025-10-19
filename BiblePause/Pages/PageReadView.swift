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
    
    // Переменная для наблюдения за завершением аудио
    @State private var audioStateObserver: AnyCancellable?

    @State private var showSelection = false
    @State private var showSetup = false

    @State private var errorDescription: String = ""

    @State private var textVerses: [BibleTextualVerseFull] = []
    //@State private var audioVerses: [BibleAudioVerseFull] = []
    @State private var currentVerseNumber: Int? // = 0
    @State private var prevExcerpt: String = ""
    @State private var nextExcerpt: String = ""

    @State private var showAudioPanel = true

    @State private var scrollViewProxy: ScrollViewProxy? = nil

    @State private var isTextLoading: Bool = true
    @State private var toast: FancyToast? = nil
    @State private var hasAudio: Bool = true
    @State private var hasText: Bool = true

    @State var scrollToVerseId: Int?

    @State var oldExcerpt: String = "" // значение до клика на выбор
    @State var oldTranslation: Int = 0
    @State var oldVoice: Int = 0
    @State var oldFontIncreasePercent: Double = 0

    //@State var currentExcerptTitle: String = ""
    //@State var currentExcerptSubtitle: String = ""

    @State var skipOnePause: Bool = false

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
                                oldVoice = settingsManager.voice
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
                    }
                    else if textVerses.isEmpty && self.errorDescription != "" {
                        // Показываем только ошибку, если текст не загружен
                        ScrollView {
                            VStack {
                                Spacer()
                                Text(self.errorDescription)
                                    .foregroundColor(.pink)
                                    .padding(globalBasePadding)
                                Spacer()
                            }
                        }
                        .refreshable {
                            Task {
                               await updateExcerpt(proxy: proxy)
                            }
                        }
                    }
                    else {
                        // Показываем текст (с предупреждением об отсутствии аудио, если есть)
                        VStack(spacing: 0) {
                            if self.errorDescription != "" && !hasText {
                                Text("⚠️ " + self.errorDescription)
                                    .foregroundColor(Color("Mustard"))
                                    .font(.footnote)
                                    .padding(.horizontal, globalBasePadding)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(Color("DarkGreen-light"))
                            }
                            
                        HTMLTextView(htmlContent: generateHTMLContent(verses: textVerses, fontIncreasePercent: settingsManager.fontIncreasePercent), scrollToVerse: $currentVerseNumber)
                            .mask(LinearGradient(
                                gradient: Gradient(colors: [Color.black, Color.black, Color.black.opacity(0)]),
                                startPoint: .init(x: 0.5, y: 0.9), // Начало градиента на 90% высоты
                                endPoint: .init(x: 0.5, y: 1.0)  // Конец градиента в самом низу
                            )
                        )
                        .padding(12)
                    }
                    }
                    // MARK: Аудио-панель
                    viewAudioPanel(proxy: proxy)

                }

                // подложка
                .background(
                    Color("DarkGreen")
                )

                // слой меню
                MenuView()
                    .environmentObject(settingsManager)
                    .offset(x: settingsManager.showMenu ? 0 : -getRect().width)

                if !showAudioPanel {
                    VStack {
                        Spacer()
                        HStack {
                            Button {
                                if prevExcerpt != "" {
                                    Task {
                                        settingsManager.currentExcerpt = prevExcerpt
                                        await updateExcerpt(proxy: proxy)
                                    }
                                }
                            }
                            label: {
                                let prevColor =  prevExcerpt == "" ? Color("localAccentColor").opacity(0.4) : Color("localAccentColor")
                                Image(systemName: "chevron.backward.2")
                                    .font(.system(size: 18))
                                    .foregroundColor(prevColor)
                                    .padding(10)
                            }
                            Spacer()
                            Button {
                                if nextExcerpt != "" {
                                    Task {
                                        settingsManager.currentExcerpt = nextExcerpt
                                        await updateExcerpt(proxy: proxy)
                                    }
                                }
                            }
                            label: {
                                let nextColor =  nextExcerpt == "" ? Color("localAccentColor").opacity(0.4) : Color("localAccentColor")
                                Image(systemName: "chevron.forward.2")
                                    .font(.system(size: 18))
                                    .foregroundColor(nextColor)
                                    .padding(10)
                            }
                        }
                        .padding(10)
                    }
                }
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
                    if oldTranslation != settingsManager.translation || oldVoice != settingsManager.voice || oldFontIncreasePercent != settingsManager.fontIncreasePercent {
                        await updateExcerpt(proxy: proxy)
                    }
                }
            })
            {
                PageSetupView(showFromRead: $showSetup)
                    .environmentObject(settingsManager)
            }

            .edgesIgnoringSafeArea(.bottom)

            .onAppear {
                //settingsManager.currentExcerptTitle = settingsManager.currentExcerptTitle
                //settingsManager.currentExcerptSubtitle = settingsManager.currentExcerptSubtitle
                UIRefreshControl.appearance().tintColor = UIColor(Color("localAccentColor"))

                Task {
                    await updateExcerpt(proxy: proxy)
                    audiopleer.onEndVerse = onEndVerse
                    audiopleer.onStartVerse = onStartVerse
                    audiopleer.smoothPauseLength = settingsManager.voiceMusic ? 0.3 : 0
                    audiopleer.setSpeed(speed: Float(self.settingsManager.currentSpeed))
                    self.scrollViewProxy = proxy
                    
                    // Настройка наблюдения за завершением аудио для автоматического перехода к следующей главе
                    setupAudioCompletionObserver(proxy: proxy)
                }

                scrollToVerseId = nil
            }
            .onDisappear {
                // Очистка наблюдателя для предотвращения утечек памяти
                audioStateObserver?.cancel()
                audioStateObserver = nil
            }
        }
    }

    // MARK: После выбора784/
    func updateExcerpt(proxy: ScrollViewProxy) async {
        do {
            //withAnimation(.easeOut(duration: 0.1)) {
                self.isTextLoading = true
                self.errorDescription = ""
                self.hasText = false
            //}

            let (thisTextVerses, audioVerses, firstUrl, isSingleChapter, part) = try await getExcerptTextualVersesOnline(excerpts: settingsManager.currentExcerpt, client: settingsManager.client, translation: settingsManager.translation, voice: settingsManager.voice)

            textVerses = thisTextVerses
            self.hasText = true
            
            // Обновляем информацию о книге и главе
            settingsManager.currentBookId = textVerses[0].bookDigitCode
            settingsManager.currentChapterId = textVerses[0].chapterDigitCode
            
            self.currentVerseNumber = -1
            if (part != nil) {
                self.prevExcerpt = part!.prev_excerpt
                self.nextExcerpt = part!.next_excerpt
                withAnimation() {
                    settingsManager.currentExcerptTitle = part!.book.name
                    settingsManager.currentExcerptSubtitle = "Глава \(part!.chapter_number)"
                    settingsManager.currentBookId = part!.book.number
                    settingsManager.currentChapterId = part!.chapter_number
                }
            }
            
            // листание наверх
            withAnimation {
                proxy.scrollTo("top", anchor: .top)
            }
            
            // Проверяем наличие аудио
            if firstUrl.isEmpty {
                self.hasAudio = false
                self.errorDescription = "Аудиофайл для этой главы отсутствует"
            } else if let url = URL(string: firstUrl) {
                //print(isSingleChapter)
                let (from, to) = getExcerptPeriod(audioVerses: audioVerses)
                //print("url: \(url)")
                
                let playerItem = AVPlayerItem(url: url)
                audiopleer.setItem(playerItem: playerItem, periodFrom: isSingleChapter ? 0 : from, periodTo: isSingleChapter ? 0 : to, audioVerses: audioVerses, itemTitle: settingsManager.currentExcerptTitle, itemSubtitle: settingsManager.currentExcerptSubtitle)
                
                self.hasAudio = true
                self.errorDescription = ""
            } else {
                self.hasAudio = false
                self.errorDescription = "Некорректный URL аудиофайла"
            }
        } catch {
            self.errorDescription = "Ошибка: \(error)"
            //print("Ошибка: \(error)")
            //toast = FancyToast(type: .error, title: "Ошибка загрузки данных", message: error.localizedDescription)
        }
        withAnimation(.easeOut(duration: 0.8)) {
            self.isTextLoading = false
        }
    }

    // MARK: Обработчики изменения стиха
    func onStartVerse(_ cur: Int) {
        //print("onStartVerse \(cur) - \(cur >= 0 ? textVerses[cur].html : "")")

        if skipOnePause {
            skipOnePause = false
        }
        else if cur < 0 {
            self.currentVerseNumber = 0
            return
        }
        else if cur > 0 && (settingsManager.pauseBlock == .paragraph || settingsManager.pauseBlock == .fragment) {
            if settingsManager.pauseType == .time {
                if (settingsManager.pauseBlock == .paragraph && textVerses[cur].startParagraph) ||
                   (settingsManager.pauseBlock == .fragment  && textVerses[cur].beforeTitle != nil)
                {
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
        //print("onEndVerse")

        if skipOnePause {
            skipOnePause = false
            return
        }

        // если нужна пауза - сделать ее
        // (это событие не вызывается после последнего стиха и полной остановки)
        if settingsManager.pauseBlock == .verse {
            if settingsManager.pauseType == .time {
                audiopleer.breakForSeconds(settingsManager.pauseLength)
            }
            else if settingsManager.pauseType == .full {
                audiopleer.doPlayOrPause()
            }
        }
    }

    // MARK: Настройка наблюдения за завершением аудио
    private func setupAudioCompletionObserver(proxy: ScrollViewProxy) {
        audioStateObserver = audiopleer.$state
            .receive(on: DispatchQueue.main)
            .sink { newState in
                // Автоматический переход к следующей главе при завершении аудио
                if newState == .finished {
                    // Отмечаем текущую главу как прочитанную
                    if let firstVerse = self.textVerses.first {
                        let bookAlias = self.settingsManager.getBookAlias(bookNumber: firstVerse.bookDigitCode)
                        if !bookAlias.isEmpty {
                            self.settingsManager.markChapterAsRead(book: bookAlias, chapter: firstVerse.chapterDigitCode)
                        }
                    }
                    
                    if self.settingsManager.autoNextChapter && !self.nextExcerpt.isEmpty {
                        // Небольшая задержка для лучшего UX
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            Task {
                                self.settingsManager.currentExcerpt = self.nextExcerpt
                                await self.updateExcerpt(proxy: proxy)
                                
                                // Определяем нужна ли пауза между главами и должно ли начаться воспроизведение
                                let (pauseDelay, shouldAutoPlay) = self.calculateChapterTransitionPause()
                                
                                // Если есть пауза, показываем состояние autopausing
                                if pauseDelay > 0.3 && shouldAutoPlay {
                                    self.audiopleer.state = .autopausing
                                }
                                
                                // Автоматический старт воспроизведения после паузы (если нужно)
                                if shouldAutoPlay {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + pauseDelay) {
                                        self.audiopleer.doPlayOrPause()
                                    }
                                }
                            }
                        }
                    }
                }
            }
    }
    
    // MARK: Вычисление паузы при переходе между главами
    private func calculateChapterTransitionPause() -> (delay: Double, shouldAutoPlay: Bool) {
        // Если паузы отключены
        guard settingsManager.pauseType != .none else {
            return (0.3, true) // минимальная техническая задержка, автовоспроизведение
        }
        
        // Новая глава всегда считается новым стихом и новым абзацем
        // Проверяем, является ли она новым отрывком (есть ли заголовок перед первым стихом)
        let isNewFragment = textVerses.first?.beforeTitle != nil
        
        // Определяем нужна ли пауза в зависимости от настроек
        let shouldPause: Bool
        switch settingsManager.pauseBlock {
        case .verse:
            shouldPause = true // новая глава = новый стих
        case .paragraph:
            shouldPause = true // новая глава = новый абзац
        case .fragment:
            shouldPause = isNewFragment // новая глава = новый отрывок только если есть заголовок
        }
        
        guard shouldPause else {
            return (0.3, true) // минимальная техническая задержка, автовоспроизведение
        }
        
        // Возвращаем длительность паузы и флаг автовоспроизведения в зависимости от типа
        if settingsManager.pauseType == .time {
            return (settingsManager.pauseLength, true)
        } else {
            // Для .full паузы воспроизведение не должно начаться автоматически
            return (0.3, false)
        }
    }

    // MARK: Панель с плеером
    @ViewBuilder private func viewAudioPanel(proxy: ScrollViewProxy) -> some View {

        VStack(spacing: 0) {
            viewAudioHide()

            VStack {
                viewAudioInfo()
                
                // Предупреждение об отсутствии аудио
                if !hasAudio && hasText && self.errorDescription != "" {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(Color("Mustard"))
                            .font(.footnote)
                        Text(self.errorDescription)
                            .foregroundColor(Color("Mustard"))
                            .font(.footnote)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color("DarkGreen").opacity(0.5))
                    .cornerRadius(8)
                    .padding(.top, 8)
                }
                
                viewAudioTimeline()
                viewAudioButtons(proxy: proxy)
            }
            .frame(height: showAudioPanel ? nil : 0)
            .opacity(showAudioPanel ? 1 : 0)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: showAudioPanel ? (!hasAudio && hasText ? 260 : 220) : 45)
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
        .gesture(DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.height > 50 {
                    withAnimation {
                        showAudioPanel = false
                    }
                } else if value.translation.height < -50 {
                    withAnimation {
                        showAudioPanel = true
                    }
                }
            }
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
            //.background(.red)
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
            if settingsManager.pauseType == .none {
                Text("").padding(.horizontal, 2)
            } else {
                Spacer()
            }
            VStack(alignment: .leading, spacing: 0) {
                Text("ЧИТАЕТ:")
                    .foregroundStyle(Color("localAccentColor").opacity(0.5))
                    .font(.caption2)
                Text(settingsManager.voiceName)
                    .foregroundStyle(Color("localAccentColor"))
                    .font(.footnote)
            }
            Spacer()
            if settingsManager.pauseType != .none {
                VStack(alignment: .leading, spacing: 0) {
                    Text("ПАУЗА:")
                        .foregroundStyle(Color("localAccentColor").opacity(0.5))
                        .font(.caption2)
                    Text("\(settingsManager.pauseBlock.shortName) / \(settingsManager.pauseType == .time ? String(format: "%g сек.", settingsManager.pauseLength) : "стоп")")
                        .foregroundStyle(Color("localAccentColor"))
                        .font(.footnote)
                }
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
                //Text("\(audiopleer.state)")
                    //.foregroundStyle(Color("localAccentColor").opacity(0.1))
                Spacer()
                Text("\(formatTime(audiopleer.currentDuration))")
                    .foregroundStyle(Color("localAccentColor").opacity(0.4))
            }
            .font(.subheadline)
        }
        .padding(.top, 2)

    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MARK: Панель - AudioButtons
    @ViewBuilder fileprivate func viewAudioButtons(proxy: ScrollViewProxy) -> some View {

        let buttonsColor = (!hasAudio || audiopleer.state == .buffering) ? Color("localAccentColor").opacity(0.4) : Color("localAccentColor")
        let prevColor =  prevExcerpt == "" ? Color("localAccentColor").opacity(0.4) : Color("localAccentColor")
        let nextColor =  nextExcerpt == "" ? Color("localAccentColor").opacity(0.4) : Color("localAccentColor")
        let verseGoColor = (hasAudio && audiopleer.state == .playing) ? Color("localAccentColor") : Color("localAccentColor").opacity(0.4)

        HStack {

            // Previous chapter
            Button {
                if prevExcerpt != "" {
                    Task {
                        settingsManager.currentExcerpt = prevExcerpt
                        await updateExcerpt(proxy: proxy)
                    }
                }
            } label: {
                Image(systemName: "chevron.backward.2")
                    .foregroundColor(prevColor)
            }
            Spacer()

            // Restart отрывка
            Button {
                audiopleer.restart()
            } label: {
                Image(systemName: "gobackward")
                    .foregroundColor(buttonsColor)
            }
            .disabled(!hasAudio)
            Spacer()

            // Previos verse
            Button {
                self.skipOnePause = true
                audiopleer.previousVerse()
            } label: {
                Image(systemName: "arrow.turn.left.up")
                    .foregroundColor(verseGoColor)
            }
            .disabled(!hasAudio)
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
            .disabled(!hasAudio)
            Spacer()

            // Next verse
            Button {
                self.skipOnePause = true
                audiopleer.nextVerse()
            } label: {
                Image(systemName: "arrow.turn.right.down")
                    .foregroundColor(verseGoColor)
            }
            .disabled(!hasAudio)
            Spacer()

            // Speed
            Button {
                audiopleer.changeSpeed()
                settingsManager.currentSpeed = Double(audiopleer.currentSpeed)
            } label: {
                Text(audiopleer.currentSpeed == 1 ? "x1" : String(format: "%.1f", audiopleer.currentSpeed))
                    .font(.system(size: 18))
                    .foregroundColor(buttonsColor)
            }
            .disabled(!hasAudio)
            Spacer()

            // Next chapter
            Button {
                if nextExcerpt != "" {
                    Task {
                        settingsManager.currentExcerpt = nextExcerpt
                        await updateExcerpt(proxy: proxy)
                    }
                }
            } label: {
                Image(systemName: "chevron.forward.2")
                    .foregroundColor(nextColor)
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

