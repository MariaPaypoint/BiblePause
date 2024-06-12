//
//  PageReadView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI
import AVFoundation

struct PageReadView: View {
    
    @Binding var showMenu: Bool
    @Binding var selectedMenuItem: MenuItem
    @Binding var currentExcerpt: String
    @Binding var currentExcerptTitle: String
    @Binding var currentExcerptSubtitle: String
    @Binding var currentExcerptIsSingleChapter: Bool
    
    @State private var currentTranslationIndex: Int = globalCurrentTranslationIndex
    
    @State private var showSelection = false
    
    let player = AVPlayer()
    @State private var periodFrom: Double = 0
    @State private var periodTo: Double = 0
    @State private var errorDescription: String = ""
    
    @State private var textVerses: [BibleTextVerseFull] = []
    @State private var audioVerses: [BibleAudioVerseFull] = []
    @State private var currentVerseId = 0
    
    @State private var showAudioPanel = true
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 0) {
                
                // MARK: шапка
                HStack(alignment: .center) {
                    MenuButtonView(
                        showMenu: $showMenu,
                        selectedMenuItem: $selectedMenuItem)
                    
                    Spacer()
                    
                    Button {
                        player.pause()
                        
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
                    
                    Image(systemName: "textformat.size")
                        .font(.system(size: 24))
                        //.padding(.top, 7)
                }
                .foregroundColor(.white)
                .padding(.horizontal, globalBasePadding)
                .padding(.bottom, 5)
                
                // MARK: Текст
                ScrollView() {
                    viewExcerpt(verses: textVerses, selectedId: currentVerseId)
                        .padding(.horizontal, globalBasePadding)
                        .padding(.vertical, 20)
                }
                .frame(maxHeight: .infinity)
                .mask(LinearGradient(gradient: Gradient(colors: [Color.black, Color.black, Color.black.opacity(0)]),
                                     startPoint: .init(x: 0.5, y: 0.9), // Начало градиента на 80% высоты
                                     endPoint: .init(x: 0.5, y: 1.0)) // Конец градиента в самом низу
                )
                Spacer()
                
                // MARK: Панель с плеером
                VStack {
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
                    
                    InfoView()
                        //.hidden(!showAudioPanel)
                        .frame(height: showAudioPanel ? nil : 0)
                        .opacity(showAudioPanel ? 1 : 0)
                    
                    AudioPlayerControlsView(player: player,
                                            timeObserver: PlayerTimeObserver(player: player),
                                            durationObserver: PlayerDurationObserver(player: player),
                                            itemObserver: PlayerItemObserver(player: player),
                                            localAccentColor: "localAccentColor",
                                            periodFrom: currentExcerptIsSingleChapter ? 0 : periodFrom,
                                            periodTo: currentExcerptIsSingleChapter ? 0 : periodTo,
                                            audioVerses: audioVerses,
                                            onChangeCurrentVerse: changeCurrentVerse)
                    //.padding(.bottom, 30)
                    //.hidden(!showAudioPanel)
                    .frame(maxHeight: showAudioPanel ? nil : 0)
                    .opacity(showAudioPanel ? 1 : 0)
                    
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
            
            // подложка
            .background(
                Color("DarkGreen")
                //LinearGradient(gradient: Gradient(colors: [Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen-light"), Color("DarkGreen-light")]), startPoint: .top, endPoint: .bottom)
            )
            
            // слой меню
            MenuView(showMenu: $showMenu,
                     selectedMenuItem: $selectedMenuItem
            )
            .offset(x: showMenu ? 0 : -getRect().width)
        }
        .fullScreenCover(isPresented: $showSelection, onDismiss: {updateExcerpt()} ) {
            PageSelectView(showMenu: $showMenu,
                           selectedMenuItem: $selectedMenuItem,
                           showFromRead: $showSelection,
                           currentExcerpt: $currentExcerpt,
                           currentExcerptTitle: $currentExcerptTitle,
                           currentExcerptSubtitle: $currentExcerptSubtitle)
        }
        .onAppear {
            updateExcerpt()
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    func updateExcerpt() {
        (textVerses, currentExcerptIsSingleChapter) = getExcerptTextVerses(excerpts: currentExcerpt)
        
        let (audioVerses, err) = getExcerptAudioVerses(textVerses: textVerses)
        let (from, to) = getExcerptPeriod(audioVerses: audioVerses)
        
        if audioVerses.count > 0 {
            self.currentVerseId = audioVerses[0].id
        }
        
        self.audioVerses = audioVerses
        self.periodFrom = from
        self.periodTo = to
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
        self.player.replaceCurrentItem(with: playerItem)
    }
    
    func changeCurrentVerse(_ cur: Int) {
        self.currentVerseId = cur
    }
}

// MARK: Audio Info&Setup
struct InfoView: View {
    var body: some View {
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
            Spacer()
            Image(systemName: "gearshape")
                .imageScale(.large)
                .foregroundStyle(Color("localAccentColor"))
        }
    }
}

// MARK: Audio Controls
struct AudioPlayerControlsView: View {
    
    private enum PlaybackState: Int {
        case waitingForSelection
        case waitingForPlay
        case buffering
        case playing
        case pausing
    }
    
    let player: AVPlayer
    let timeObserver: PlayerTimeObserver
    let durationObserver: PlayerDurationObserver
    let itemObserver: PlayerItemObserver
    let localAccentColor: String
    let periodFrom: Double
    let periodTo: Double // 0 означает отсутствие конца отрывка
    
    @State private var currentTime: TimeInterval = 0
    @State private var currentDuration: TimeInterval = 0
    @State private var state = PlaybackState.waitingForSelection
    @State private var lastRate: Float = 1.0
    
    @State private var stopAtEnd = true
    
    let audioVerses: [BibleAudioVerseFull]
    @State private var currentVerseIndex: Int = 0
    
    var onChangeCurrentVerse: ((Int) -> Void)
    
    var body: some View {
        
        VStack {
            
            // debug
            //if state == .waitingForSelection {
            //    let _ = print("Select a song below")
            //} else if state == .buffering {
            //    let _ = print("Buffering...")
            //} else if state == .waitingForPlay {
            //    let _ = print("You can play now...")
            //} else if state == .pausing {
            //    let _ = print("OK, we are waiting...")
            //} else {
            //    let _ = print("Great choice!")
            //}
            
            
            
            
            // MARK: Timeline
            ZStack {
                
                Slider(value: $currentTime, in: 0...currentDuration, onEditingChanged: sliderEditingChanged)
                    .accentColor(Color("localAccentColor"))
                    .onAppear {
                        let progressCircleConfig = UIImage.SymbolConfiguration(scale: .small)
                        UISlider.appearance()
                            .setThumbImage(UIImage(systemName: "circle.fill",
                                                   withConfiguration: progressCircleConfig), for: .normal)
                        
                    }
                    .disabled(state == .waitingForSelection || state == .buffering)
                    //.blendMode(.multiply)
                
                if currentDuration > 0 {
                    
                    // https://stackoverflow.com/a/62641399
                    let frameWidth: Double = UIScreen.main.bounds.size.width - globalBasePadding*2
                    let point: Double = frameWidth / currentDuration
                    
                    let pointStart: Double = Double(periodFrom) * point
                    let pointCenter: Double = currentTime * point
                    let pointEnd: Double = Double(periodTo == 0 ? currentDuration : periodTo) * point
                    
                    let circleLeftSpace: Double = 13 * currentTime / currentDuration
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
            
            // MARK: Times
            HStack {
                    Text("\(Utility.formatSecondsToHMS(currentTime))")
                        .font(.system(size: 13))
                        .foregroundColor(Color("localAccentColor"))
                        .multilineTextAlignment(.leading)
                
                    Spacer()
                    Text("\(Utility.formatSecondsToHMS(currentDuration))")
                        .font(.system(size: 13))
                        .foregroundColor(Color("localAccentColor"))
                
            }
            .padding(.bottom, 10)
            
            // MARK: Player buttons
            HStack(spacing: 0) {
                
                HStack{
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "backward.frame.fill")
                    }
                    
                    Spacer()
                    
                    // MARK: Restart
                    Button {
                        stopAtEnd = true
                        self.player.seek(to: CMTimeMake(value: Int64(periodFrom*100), timescale: 100))
                        self.state = .playing
                        self.player.play()
                    } label: {
                        //Image(systemName: "repeat")
                        Image(systemName: "gobackward")
                    }
                    
                    Spacer()
                    
                    // MARK: Previos verse
                    Button {
                        //self.player.seek(to: CMTimeMake(value: Int64((currentTime-15)*100), timescale: 100))
                        
                        if currentVerseIndex > 0 {
                            setCurrentVerseIndex(currentVerseIndex - 1)
                            
                            let begin = audioVerses[currentVerseIndex].begin
                            self.player.seek(to: CMTimeMake(value: Int64(begin*100), timescale: 100))
                            self.currentTime = begin
                        }
                    } label: {
                        Image(systemName: "arrowshape.turn.up.left.fill")
                    }
                    
                    Spacer()
                    
                    // MARK: Play/Pause
                    Button {
                        if state == .playing {
                            state = .pausing
                            player.pause()
                        } else {
                            if self.currentTime >= Double(periodTo == 0 ? currentDuration : periodTo) {
                                self.stopAtEnd = false
                            }
                            
                            state = .playing
                            player.play()
                            player.rate = lastRate
                        }
                    } label: {
                        let buttonsColor = state == .buffering ? Color("localAccentColor").opacity(0.4) : Color("localAccentColor")
                        
                        Image(systemName: state != .playing ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 55))
                            .foregroundColor(buttonsColor)
                    }
                    
                    Spacer()
                    
                    // MARK: Next verse
                    Button {
                        //self.player.seek(to: CMTimeMake(value: Int64((currentTime+15)*100), timescale: 100))
                        if currentVerseIndex+1 < audioVerses.count {
                            setCurrentVerseIndex(currentVerseIndex + 1)
                            let begin = audioVerses[currentVerseIndex].begin
                            self.player.seek(to: CMTimeMake(value: Int64(begin*100), timescale: 100))
                            self.currentTime = begin
                        }
                    } label: {
                        Image(systemName: "arrowshape.turn.up.right.fill")
                    }
                    
                    Spacer()
                    
                    // MARK: Speed
                    Button {
                        if self.state == .playing {
                            if self.player.rate >= 2 || self.player.rate < 0.6 {
                                self.player.rate = 0.6
                            }
                            else {
                                self.player.rate += 0.2
                            }
                            lastRate = self.player.rate
                        }
                    } label: {
                        Text(lastRate == 1 ? "x1" : String(format: "%.1f", lastRate))
                            .font(.system(size: 20))
                        
                    }
                    
                    Spacer()
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "forward.frame.fill")
                    }
                    
                }
                .foregroundColor(Color("localAccentColor"))
                
                
            }
            .padding(.top, 5)
            .padding(.bottom, 5)
            .font(.system(size: 22))
            
            //Slider(value: $currentTime,
            //       in: 0...currentDuration,
            //       onEditingChanged: sliderEditingChanged,
            //       minimumValueLabel: Text("\(Utility.formatSecondsToHMS(currentTime))"),
            //       maximumValueLabel: Text("\(Utility.formatSecondsToHMS(currentDuration))")) {
            //        // I have no idea in what scenario this View is shown...
            //        Text("seek/progress slider")
            //}
            //.disabled(state != .playing)
            
        }
        
        .onAppear() {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        }
        
        // MARK: Observers
        
        // Listen out for the time observer publishing changes to the player's time
        .onReceive(timeObserver.publisher) { time in
            // Update the local var
            
            self.currentTime = time
            // And flag that we've started playback
            ///if time > 0 {
            ///    self.state = .playing
            ///}
            
            if time > Double(periodTo == 0 ? currentDuration : periodTo) && self.stopAtEnd {
                self.state = .pausing
                self.player.pause()
            }
            
            var cur = currentVerseIndex
            for (index, verse) in audioVerses.enumerated() {
                if time >= verse.begin && time < verse.end {
                    cur = index
                    break
                }
            }
            setCurrentVerseIndex(cur)
            
        }
        // Listen out for the duration observer publishing changes to the player's item duration
        .onReceive(durationObserver.publisher) { duration in
            // Update the local var
            //print("duration: \(duration)")
            self.currentDuration = duration
            if self.state == .buffering {
                self.state = .waitingForPlay
                self.player.seek(to: CMTimeMake(value: Int64(periodFrom*100), timescale: 100))
                //self.currentTime = periodFrom
            }
        }
        // Listen out for the item observer publishing a change to whether the player has an item
        .onReceive(itemObserver.publisher) { hasItem in
            //print("state: \(self.state)")
            self.state = hasItem ? .buffering : .waitingForSelection
            self.currentTime = 0
            self.currentDuration = 0
        }
        // TODO the below could replace the above but causes a crash
//        // Listen out for the player's item changing
//        .onReceive(player.publisher(for: \.currentItem)) { item in
//            self.state = item != nil ? .buffering : .waitingForSelection
//            self.currentTime = 0
//            self.currentDuration = 0
//        }
    }
    
    private func setCurrentVerseIndex(_ cur: Int) {
        if cur != currentVerseIndex {
            currentVerseIndex = cur
            onChangeCurrentVerse(audioVerses[cur].id)
        }
    }
    
    // MARK: Private functions
    private func sliderEditingChanged(editingStarted: Bool) {
        
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
    }
}

// MARK: Preview
struct TestPageReadView: View {
    
    @State private var showMenu: Bool = false
    @State private var selectedMenuItem: MenuItem = .read
    @State private var currentExcerpt = "mat 2"
    @State private var currentExcerptTitle: String = "Евангелие от Матфея"
    @State private var currentExcerptSubtitle: String = "Глава 2"
    @State private var currentExcerptIsSingleChapter: Bool = true
    
    var body: some View {
        PageReadView(showMenu: $showMenu,
                     selectedMenuItem: $selectedMenuItem,
                     currentExcerpt: $currentExcerpt,
                     currentExcerptTitle: $currentExcerptTitle,
                     currentExcerptSubtitle: $currentExcerptSubtitle,
                     currentExcerptIsSingleChapter: $currentExcerptIsSingleChapter)
    }
}

/*
#Preview {
    TestPageReadView()
}
*/


struct PageReadView_Previews: PreviewProvider {
    static var previews: some View {
        TestPageReadView()
        
    }
}

