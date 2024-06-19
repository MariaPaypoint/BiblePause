//
//  PageContactsView.swift
//  BiblePause
//
//  Created by Maria Novikova on 15.06.2024.
//

import SwiftUI
import AVFoundation
import Combine

struct PageContactsView: View {
    
    @StateObject var audiopleer = PlayerModel()
    
    @ObservedObject var settingsManager = SettingsManager()
    
    @Binding var showMenu: Bool
    @Binding var selectedMenuItem: MenuItem
    @Binding var currentExcerpt: String
    @Binding var currentExcerptTitle: String
    @Binding var currentExcerptSubtitle: String
    @Binding var currentExcerptIsSingleChapter: Bool
    @Binding var currentBookId: Int
    @Binding var currentChapterId: Int
    
    @State private var currentTranslationIndex: Int = globalCurrentTranslationIndex
    
    @State private var showSelection = false
    @State private var showSetup = false
    
    //@State private var periodFrom: Double = 0
    //@State private var periodTo: Double = 0
    @State private var errorDescription: String = ""
    
    @State private var textVerses: [BibleTextVerseFull] = []
    @State private var audioVerses: [BibleAudioVerseFull] = []
    @State private var currentVerseId = 0
    
    @State private var showAudioPanel = true
    
    var body: some View {
        ScrollViewReader { proxy in
            ZStack {
                VStack(spacing: 0) {
                    
                    // MARK: Шапка
                    HStack(alignment: .center) {
                        MenuButtonView(
                            showMenu: $showMenu,
                            selectedMenuItem: $selectedMenuItem)
                        
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
                                Text(currentExcerptTitle)
                                    .fontWeight(.bold)
                                Text(currentExcerptSubtitle.uppercased())
                                    .foregroundColor(Color("Mustard"))
                                    .font(.footnote)
                                    .fontWeight(.bold)
                            }
                            .padding(.top, 6)
                        }
                        
                        Spacer()
                        
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
                MenuView(showMenu: $showMenu,
                         selectedMenuItem: $selectedMenuItem
                )
                .offset(x: showMenu ? 0 : -getRect().width)
            }
            .fullScreenCover(isPresented: $showSelection, onDismiss: {
                updateExcerpt(proxy: proxy)
            })
            {
                PageSelectView(showMenu: $showMenu,
                               selectedMenuItem: $selectedMenuItem,
                               showFromRead: $showSelection,
                               currentExcerpt: $currentExcerpt,
                               currentExcerptTitle: $currentExcerptTitle,
                               currentExcerptSubtitle: $currentExcerptSubtitle,
                               currentBookId: $currentBookId,
                               currentChapterId: $currentChapterId)
            }
            .fullScreenCover(isPresented: $showSetup, onDismiss: {
                //
            })
            {
                PageSetupView(showMenu: $showMenu,
                              selectedMenuItem: $selectedMenuItem,
                              showFromRead: $showSetup)
            }
            .onAppear {
                updateExcerpt(proxy: proxy)
                audiopleer.onEndVerse = onEndVerse
                audiopleer.onStartVerse = onStartVerse
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    func updateExcerpt(proxy: ScrollViewProxy) {
        (textVerses, currentExcerptIsSingleChapter) = getExcerptTextVerses(excerpts: currentExcerpt)
        
        let (audioVerses, err) = getExcerptAudioVerses(textVerses: textVerses)
        let (from, to) = getExcerptPeriod(audioVerses: audioVerses)
        
        self.audioVerses = audioVerses
        self.errorDescription = err
        
        // MARK: Audio URL
        let voice = globalBibleAudio.getCurrentVoice()
        let (book, chapter) = getExcerptBookChapterDigitCode(verses: textVerses)
        
        //let address = "https://500:3490205720348012725@assets.christedu.ru/data/translations/ru/\(voice.translation)/audio/\(voice.code)/\(book)/\(chapter).mp3"
        let address = "https://4bbl.ru/data/\(voice.translation)-\(voice.code)/\(book)/\(chapter).mp3"
        
        guard let url = URL(string: address) else {
            self.errorDescription = "URL not found: \(address)"
            return
        }
        
        let playerItem = AVPlayerItem(url: url)
        audiopleer.setItem(playerItem: playerItem, periodFrom: from, periodTo: to, audioVerses: audioVerses)
        
        // листание наверх
        withAnimation {
            proxy.scrollTo("top", anchor: .top)
        }
        
        currentBookId = textVerses[0].bookDigitCode
        currentChapterId = textVerses[0].chapterDigitCode
    }
    
    func onStartVerse(_ cur: Int) {
        self.currentVerseId = cur
    }
    
    func onEndVerse() {
        // если нужна пауза - сделать ее
        ///player.pause()
    }
    
    fileprivate func viewAudioPanel() -> some View {
        // MARK: Панель с плеером
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
            InfoView()
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
    
    @ViewBuilder
    fileprivate func viewAudioTimeline() -> some View {
        
        // MARK: Timeline
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
            if audiopleer.currentDuration > 0 {
                
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
    
    @ViewBuilder
    fileprivate func viewAudioButtons() -> some View {
        
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
            }
            Spacer()
            
            // Previos verse
            Button {
                audiopleer.previousVerse()
            } label: {
                Image(systemName: "arrowshape.turn.up.left.fill")
            }
            Spacer()
            
            // MARK: Play/Pause
            Button {
                audiopleer.doPlayOrPause()
            } label: {
                let buttonsColor = audiopleer.state == .buffering ? Color("localAccentColor").opacity(0.4) : Color("localAccentColor")
                
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
            }
            Spacer()
            
            // Speed
            Button {
                audiopleer.changeSpeed()
            } label: {
                Text(audiopleer.currentSpeed == 1 ? "x1" : String(format: "%.1f", audiopleer.currentSpeed))
                    .font(.system(size: 20))
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
        case buffering
        case playing
        case pausing
    }
    
    private let player: AVPlayer
    private let durationObserver: PlayerDurationObserver
    private let timeObserver: PlayerTimeObserver
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
    private var stopAtEnd = true //
    
    var onStartVerse: ((Int) -> Void)? // устанавливается снаружи, поэтому без private
    var onEndVerse: (() -> Void)? // устанавливается снаружи, поэтому без private
    
    
    init(onStartVerse: ((Int) -> Void)? = nil, onEndVerse: (() -> Void)? = nil) {
        self.player = AVPlayer()
        self.durationObserver = PlayerDurationObserver(player: self.player)
        self.timeObserver = PlayerTimeObserver(player: self.player)
        
        self.onStartVerse = onStartVerse
        self.onEndVerse = onEndVerse
        
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
                
                // остановка при достижении конца отрывка
                let endPosition = (self?.periodTo == 0 ? self?.currentDuration : self?.periodTo) ?? 0
                if time > Double(endPosition) && self?.stopAtEnd ?? false {
                    self?.state = .pausing
                    self?.player.pause()
                }
                
                // ищем стих, в который точно попадает текущее положение
                var cur = -1
                for (index, verse) in self!.audioVerses.enumerated() {
                    if time >= verse.begin && time < verse.end {
                        cur = index
                        self?.interverse = false
                        break
                    }
                }
                
                // стих не нашелся (например, в самом начале, или если один стих закончился, а другой еще не начался)
                if cur == -1 {
                    if !self!.interverse && self!.currentVerseIndex > 0 {
                        self?.interverse = true
                        self?.onEndVerse?()
                    }
                }
                else {
                    self?.setCurrentVerseIndex(cur)
                }
                 
                
            }
            .store(in: &cancellables)
    }
    
    // установка параметров новой композиции
    func setItem(playerItem: AVPlayerItem, periodFrom: Double, periodTo: Double, audioVerses: [BibleAudioVerseFull]) {
             
        self.player.replaceCurrentItem(with: playerItem)
        self.periodFrom = periodFrom
        self.periodTo = periodTo
        self.audioVerses = audioVerses
        self.interverse = false
    }
    
    // плавная пауза
    private func pauseSmoothly(duration: TimeInterval) {
        let initialVolume = player.volume
        let steps = 10
        let interval = duration / Double(steps)
        var currentStep = 0
        
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            if currentStep < steps {
                let newVolume = initialVolume * (1.0 - Float(currentStep) / Float(steps))
                self.player.volume = newVolume
                currentStep += 1
            } else {
                self.player.pause()
                self.player.volume = initialVolume // Reset volume to original after pausing
                self.state = .pausing
                timer.invalidate()
            }
        }
    }
    
    func doPlayOrPause() {
        if self.state == .playing {
            pauseSmoothly(duration: 0.5)
        } else {
            if self.currentTime >= Double(self.periodTo == 0 ? self.currentDuration : self.periodTo) {
                self.stopAtEnd = false
            }
            
            self.state = .playing
            self.player.play()
            self.player.rate = self.currentSpeed
        }
    }
    
    private func setCurrentVerseIndex(_ cur: Int) { //
        if cur != self.currentVerseIndex {
            self.currentVerseIndex = cur
            self.onStartVerse?(audioVerses[cur].id)
        }
    }
    
    func sliderEditingChanged(editingStarted: Bool) { // private
        /*
        if editingStarted {
            // Tell the PlayerTimeObserver to stop publishing updates while the user is interacting
            // with the slider (otherwise it would keep jumping from where they've moved it to, back
            // to where the player is currently at)
            timeObserver.pause(true)
        }
        else {
            // Editing finished, start the seek
            ///state = .buffering
            let targetTime = CMTime(seconds: currentTime, preferredTimescale: 600)
            player.seek(to: targetTime) { _ in
                // Now the (async) seek is completed, resume normal operation
                self.timeObserver.pause(false)
                ///self.state = .playing
            }
            if currentTime >= Double(periodTo == 0 ? currentDuration : periodTo) {
                self.stopAtEnd = false
            }
        }
         */
    }
    
    func restart() {
        self.stopAtEnd = true
        self.player.seek(to: CMTimeMake(value: Int64(periodFrom*100), timescale: 100))
        self.state = .playing
        self.player.play()
    }
    
    func previousVerse() {
        if currentVerseIndex > 0 {
            setCurrentVerseIndex(currentVerseIndex - 1)
            
            let begin = audioVerses[currentVerseIndex].begin
            self.player.seek(to: CMTimeMake(value: Int64(begin*100), timescale: 100))
            self.currentTime = begin
        }
    }
    
    func nextVerse() {
        if currentVerseIndex+1 < audioVerses.count {
            setCurrentVerseIndex(currentVerseIndex + 1)
            let begin = audioVerses[currentVerseIndex].begin
            self.player.seek(to: CMTimeMake(value: Int64(begin*100), timescale: 100))
            self.currentTime = begin
        }
    }
    
    func changeSpeed() {
        if state == .playing {
            if player.rate >= 2 || player.rate < 0.6 {
                player.rate = 0.6
            }
            else {
                player.rate += 0.2
            }
            currentSpeed = player.rate
        }
    }
}

// MARK: Preview
struct TestPageContactsView: View {
    
    @State private var showMenu: Bool = false
    @State private var selectedMenuItem: MenuItem = .read
    @State private var currentExcerpt = "mat 5:4-7"
    @State private var currentExcerptTitle: String = "Евангелие от Матфея"
    @State private var currentExcerptSubtitle: String = "Глава 5"
    @State private var currentExcerptIsSingleChapter: Bool = true
    @State private var currentBookId: Int = 0
    @State private var currentChapterId: Int = 0
    
    @AppStorage("fontIncreasePercent") private var fontIncreasePercent: Double = 100.0
    
    var body: some View {
        PageContactsView(showMenu: $showMenu,
                     selectedMenuItem: $selectedMenuItem,
                     currentExcerpt: $currentExcerpt,
                     currentExcerptTitle: $currentExcerptTitle,
                     currentExcerptSubtitle: $currentExcerptSubtitle,
                     currentExcerptIsSingleChapter: $currentExcerptIsSingleChapter,
                     currentBookId: $currentBookId,
                     currentChapterId: $currentChapterId)
    }
}

/*
#Preview {
    TestPageReadView()
}
*/


struct PageContactsView_Previews: PreviewProvider {
    static var previews: some View {
        TestPageContactsView()
        
    }
}
