//
//  PageReadView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI
import AVFoundation
import Combine

struct PageReadView: View {
    
    @ObservedObject var windowsDataManager: WindowsDataManager
    
    @StateObject var audiopleer = PlayerModel()
    @ObservedObject var settingsManager = SettingsManager()
    
    @State private var currentTranslationIndex: Int = globalCurrentTranslationIndex
    
    @State private var showSelection = false
    @State private var showSetup = false
    
    @State private var errorDescription: String = ""
    
    @State private var textVerses: [BibleTextVerseFull] = []
    //@State private var audioVerses: [BibleAudioVerseFull] = []
    @State private var currentVerseId = 0
    
    @State private var showAudioPanel = true
    
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                VStack(spacing: 0) {
                    
                    // MARK: Шапка
                    HStack(alignment: .center) {
                        MenuButtonView(windowsDataManager: windowsDataManager)
                        
                        Spacer()
                        
                        // заголовок, который ведет на выбор главы
                        Button {
                            ///player.pause()
                            
                            withAnimation(Animation.easeInOut(duration: 1)) {
                                //selectedMenuItem = .select
                                showSelection = true
                            }
                        } label: {
                            VStack(spacing: 0) {
                                Text(windowsDataManager.currentExcerptTitle)
                                    .fontWeight(.bold)
                                Text(windowsDataManager.currentExcerptSubtitle.uppercased())
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
                    ScrollView() {
                        viewExcerpt(verses: textVerses, fontIncreasePercent: settingsManager.fontIncreasePercent, selectedId: currentVerseId)
                            .padding(.horizontal, globalBasePadding)
                            .padding(.vertical, 20)
                            .id("top")
                    }
                    .frame(maxHeight: .infinity)
                    .mask(LinearGradient(gradient: Gradient(colors: [Color.black, Color.black, Color.black.opacity(0)]),
                                         startPoint: .init(x: 0.5, y: 0.9), // Начало градиента на 80% высоты
                                         endPoint: .init(x: 0.5, y: 1.0)) // Конец градиента в самом низу
                    )
                    Spacer()
                    
                    viewAudioPanel()
                }
                
                // подложка
                .background(
                    Color("DarkGreen")
                )
                
                // слой меню
                MenuView(windowsDataManager: windowsDataManager)
                    .offset(x: windowsDataManager.showMenu ? 0 : -getRect().width)
            }
            .fullScreenCover(isPresented: $showSelection, onDismiss: {
                updateExcerpt(proxy: proxy)
            })
            {
                PageSelectView(windowsDataManager: windowsDataManager, showFromRead: $showSelection)
            }
            .fullScreenCover(isPresented: $showSetup, onDismiss: {
                //
            })
            {
                PageSetupView(windowsDataManager: windowsDataManager, showFromRead: $showSetup)
            }
            .onAppear {
                updateExcerpt(proxy: proxy)
                audiopleer.onEndVerse = onEndVerse
                audiopleer.onStartVerse = onStartVerse
                self.scrollViewProxy = proxy
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    // MARK: После выбора
    func updateExcerpt(proxy: ScrollViewProxy) {
        let (thistextVerses, isSingleChapter) = getExcerptTextVerses(excerpts: windowsDataManager.currentExcerpt)
        
        textVerses = thistextVerses
        
        let (audioVerses, err) = getExcerptAudioVerses(textVerses: textVerses)
        let (from, to) = getExcerptPeriod(audioVerses: audioVerses)
        
        
        ///self.audioVerses = audioVerses
        self.errorDescription = err
        
        let voice = globalBibleAudio.getCurrentVoice()
        let (book, chapter) = getExcerptBookChapterDigitCode(verses: textVerses)
        
        //let address = "https://500:3490205720348012725@assets.christedu.ru/data/translations/ru/\(voice.translation)/audio/\(voice.code)/\(book)/\(chapter).mp3"
        let address = "https://4bbl.ru/data/\(voice.translation)-\(voice.code)/\(book)/\(chapter).mp3"
        
        guard let url = URL(string: address) else {
            self.errorDescription = "URL not found: \(address)"
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        audiopleer.setItem(playerItem: playerItem, periodFrom: isSingleChapter ? 0 : from, periodTo: isSingleChapter ? 0 : to, audioVerses: audioVerses)
        
        // листание наверх
        withAnimation {
            proxy.scrollTo("top", anchor: .top)
        }
        
        windowsDataManager.currentBookId = textVerses[0].bookDigitCode
        windowsDataManager.currentChapterId = textVerses[0].chapterDigitCode
        
        self.currentVerseId = -1
    }
    
    func onStartVerse(_ cur: Int) {
        self.currentVerseId = cur
        
        //guard let proxy = scrollViewProxy else {
        //    return
        //}
        // прокрутка до текущего стиха
        withAnimation {
            //proxy.scrollTo("verse_number_\(cur)", anchor: .top)
        }
        
    }
    
    func onEndVerse() {
        // если нужна пауза - сделать ее
        ///player.pause()
        //if settingsManager.pauseType == .time {
        //    audiopleer.breakForSeconds(settingsManager.pauseLength)
        //}
    }
    
    // MARK: Панель с плеером
    @ViewBuilder private func viewAudioPanel() -> some View {
        
        VStack {
            // сворачивание/разворачивание панельки
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
            
            // информация
            viewAudioInfo()
                .frame(height: showAudioPanel ? nil : 0)
                .opacity(showAudioPanel ? 1 : 0)
            
            viewAudioTimeline()
            
            viewAudioButtons()
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(height: showAudioPanel ? 265 : 45)
        //.padding(.top, globalBasePadding)
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
    
    // MARK: Панель - информация
    @ViewBuilder private func viewAudioInfo() -> some View {
        HStack {
            Text("SYNO")
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
                Text("Александр Бондаренко")
                    .foregroundStyle(Color("localAccentColor"))
                    .font(.footnote)
            }
            Spacer()
            VStack(alignment: .leading, spacing: 0) {
                Text("ПАУЗА:")
                    .foregroundStyle(Color("localAccentColor").opacity(0.5))
                    .font(.caption2)
                Text("3 сек./стих")
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
        .padding(.top, globalBasePadding)
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
                Image(systemName: audiopleer.state != .playing ? "play.circle.fill" : "pause.circle.fill")
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

// MARK: PlayerModel

class PlayerModel: ObservableObject {
    
    enum PlaybackState: Int { // private
        case waitingForSelection
        case waitingForPlay
        case waitingForPause
        case buffering
        case playing
        case pausing
    }
    
    private let player: AVPlayer
    private let durationObserver: PlayerDurationObserver
    private var timeObserver: PlayerTimeObserver
    private var boundaryObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var state = PlaybackState.waitingForSelection
    @Published var periodFrom: Double = 0
    @Published var periodTo: Double = 0 // 0 означает отсутствие конца отрывка, но оно потом перекроется
    @Published var currentDuration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    @Published var currentSpeed: Float = 1.0
    
    private var audioVerses: [BibleAudioVerseFull] = []
    private var currentVerseIndex: Int = -1
    private var interverse: Bool = false // между стихами
    private var stopAtEnd = true
    
    var onStartVerse: ((Int) -> Void)? // устанавливается снаружи, поэтому без private
    var onEndVerse: (() -> Void)? // устанавливается снаружи, поэтому без private
    
    private var pauseTimer: Timer?
    
    init(onStartVerse: ((Int) -> Void)? = nil, onEndVerse: (() -> Void)? = nil) {
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        
        self.player = AVPlayer()
        self.durationObserver = PlayerDurationObserver(player: self.player)
        self.timeObserver = PlayerTimeObserver(player: self.player)
        
        self.onStartVerse = onStartVerse
        self.onEndVerse = onEndVerse
        
        //self.player.automaticallyWaitsToMinimizeStalling = false

        // наблюдаем, когда подгрузится песня и определится ее длина
        durationObserver.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                self?.currentDuration = duration
                
                if self?.state == .buffering {
                    self?.state = .waitingForPlay
                    self?.player.seek(to: CMTimeMake(value: Int64(self!.periodFrom*100), timescale: 100))
                }
                
            }
            .store(in: &cancellables)
        
        
        // наблюдаем за изменением позиции
        timeObserver.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.currentTime = time
                print("time", time)
         /*
                // остановка при достижении конца отрывка
                if self!.periodTo > 0 && time > Double(self!.periodTo) && self!.stopAtEnd {
                    self?.state = .pausing
                    self?.player.pause()
                }
                
                // ищем стих, в который точно попадает текущее положение
                var cur = -1
                for (index, verse) in self!.audioVerses.enumerated() {
                    if time >= verse.begin && time < verse.end {
                        if index != self!.currentVerseIndex { print("cur changed from", self!.currentVerseIndex, "to", index) }
                        cur = index
                        self?.interverse = false
                        
                        break
                    }
                }
                
                // стих не нашелся (например, в самом начале, или если один стих закончился, а другой еще не начался,
                // или проигрывается за пределами отрывка)
                if cur == -1 {
                    if !self!.interverse && self!.currentVerseIndex >= 0 {
                        self?.interverse = true
                        print("onEndVerse")
                        self?.onEndVerse?()
                    }
                }
                else {
                    self?.setCurrentVerseIndex(cur)
                }
          */
            }
            .store(in: &cancellables)
        
    }
    
    private func setCurrentVerseIndex(_ cur: Int) { //
        if cur != self.currentVerseIndex {
            self.currentVerseIndex = cur
            self.onStartVerse?(audioVerses[cur].id)
        }
    }
    
    // MARK: установка параметров новой композиции
    func setItem(playerItem: AVPlayerItem, periodFrom: Double, periodTo: Double, audioVerses: [BibleAudioVerseFull]) {
             
        self.periodFrom = periodFrom
        self.periodTo = periodTo
        
        self.audioVerses = audioVerses
        self.interverse = false
        self.currentVerseIndex = -1
        
        self.state = .buffering
        self.currentTime = 0
        self.currentDuration = 0
        
        self.player.replaceCurrentItem(with: playerItem)
        
        
        var times: [NSValue] = []
        for verse in audioVerses {
            let verseEndTime = CMTime(seconds: verse.end, preferredTimescale: 10)
            times.append(NSValue(time: verseEndTime))
        }
        // Удаление предыдущего наблюдателя, если он существует
        if let boundaryObserver = boundaryObserver {
            player.removeTimeObserver(boundaryObserver)
            self.boundaryObserver = nil
        }
        boundaryObserver = player.addBoundaryTimeObserver(forTimes: times, queue: .main) {
            print("Reached verse end time")
            
            
            self.player.pause()
            //self.pauseSimple()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.player.play()
                self.player.automaticallyWaitsToMinimizeStalling = false
                self.player.setRate(self.currentSpeed, time: .invalid, atHostTime: .invalid)
                //self.player.rate = self.currentSpeed
                //self.playSimple()
            }
            
            //self.breakForSeconds(3)
        }
    }
    
    // MARK: воспр/пауза
    func doPlayOrPause() {
        if self.state == .playing {
            pauseSmoothly(duration: 0.3)
        }
        else if state == .buffering {
            // ничего не делать
        }
        else {
            // если воспроизведение запущено после конца отрывка, то уже не стопаться
            if self.currentTime >= self.periodTo {
                self.stopAtEnd = false
            }
            self.playSimple()
        }
    }
    
    private func playSimple() {
        self.state = .playing
        self.player.play()
        //self.player.rate = self.currentSpeed
        //self.timeObserver.pause(false)
        
        self.player.automaticallyWaitsToMinimizeStalling = false
        self.player.setRate(self.currentSpeed, time: .invalid, atHostTime: .invalid)
    }
    
    private func pauseSimple() {
        //self.timeObserver.pause(true)
        self.player.pause()
        self.state = .pausing
    }
    
    private func pauseSmoothly(duration: TimeInterval) {
        let initialVolume = player.volume
        let steps = 10
        let interval = duration / Double(steps)
        var currentStep = 0
        
        self.state = .waitingForPause
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if currentStep < steps {
                let newVolume = initialVolume * (1.0 - Float(currentStep) / Float(steps))
                self.player.volume = newVolume
                currentStep += 1
            } else {
                self.player.volume = initialVolume // Reset volume to original after pausing
                timer.invalidate()
                self.pauseSimple()
            }
        }
    }
    
    func breakForSeconds(_ seconds: Double) {
        
        //pauseSimple()
        /*
        // Использование DispatchQueue для задержки
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            self.playSimple()
        }
        */
        
        //pauseTimer?.invalidate()
        //pauseTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
        //    self?.playSimple()
        //}
        
        self.pauseSimple()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.playSimple()
        }
    }
    
    // юзер перематывает таймлайном
    func sliderEditingChanged(editingStarted: Bool) { // private
        
        if editingStarted {
            // Tell the PlayerTimeObserver to stop publishing updates while the user is interacting with the slider
            // (otherwise it would keep jumping from where they've moved it to, back to where the player is currently at)
            self.timeObserver.pause(true)
        }
        else {
            // Editing finished, start the seek
            let targetTime = CMTime(seconds: currentTime, preferredTimescale: 600)
            player.seek(to: targetTime) { _ in
                // Now the (async) seek is completed, resume normal operation
                self.timeObserver.pause(false)
            }
            if currentTime >= Double(periodTo == 0 ? currentDuration : periodTo) {
                stopAtEnd = false
            }
        }
    }
    
    func restart() {
        if state == .playing || state == .pausing {
            stopAtEnd = true
            player.seek(to: CMTimeMake(value: Int64(periodFrom*100), timescale: 100))
        }
    }
    
    func previousVerse() {
        if state == .playing && currentVerseIndex > 0 {
            setCurrentVerseIndex(currentVerseIndex - 1)
            
            let begin = audioVerses[currentVerseIndex].begin
            player.seek(to: CMTimeMake(value: Int64(begin*100), timescale: 100))
            currentTime = begin
        }
    }
    
    func nextVerse() {
        if state == .playing && currentVerseIndex+1 < audioVerses.count {
            setCurrentVerseIndex(currentVerseIndex + 1)
            let begin = audioVerses[currentVerseIndex].begin
            player.seek(to: CMTimeMake(value: Int64(begin*100), timescale: 100))
            currentTime = begin
        }
    }
    
    func changeSpeed() {
        if currentSpeed >= 2 || currentSpeed < 0.6 {
            currentSpeed = 0.6
        }
        else {
            currentSpeed += 0.2
        }
        
        if state == .playing {
            //player.rate = currentSpeed
            player.setRate(currentSpeed, time: .invalid, atHostTime: .invalid)
        }
    }
    
}

// MARK: Preview

struct TestPageReadView: View {
    
    @StateObject var windowsDataManager = WindowsDataManager()
    
    var body: some View {
        PageReadView(windowsDataManager: windowsDataManager)
    }
}

#Preview {
    TestPageReadView()
}

