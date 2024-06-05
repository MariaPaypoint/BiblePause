//
//  PageReadView.swift
//  BiblePause
//
//  Created by  Mac on 10.05.2024.
//

import SwiftUI
import AVFoundation


let periodFrom: Double = 18.0
let periodTo: Double = 248.5 // 248

struct PageReadView: View {
    
    @Binding var showMenu: Bool
    @Binding var menuItem: MenuItem
    
    @State var currentTranslationIndex: Int = globalCurrentTranslationIndex
    @State private var currentPosition = 0.0
    
    let player = AVPlayer()
    
    var body: some View {
        
        ZStack {
            VStack(spacing: 0) {
                
                VStack(spacing: 0) {
                    // шапка
                    HStack {
                        MenuButtonView(
                            showMenu: $showMenu,
                            menuItem: $menuItem)
                        
                        Spacer()
                        
                        Text("Название книги")
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        
                        Spacer()
                        
                        Image(systemName: "textformat.size")
                            .font(.title2)
                    }
                    .foregroundColor(.white)
                    
                    Text("Глава X")
                        .foregroundColor(Color("Mustard"))
                        .font(.title3)
                }
                .padding(.horizontal, basePadding)
                .padding(.top, basePadding)
                
                ScrollView() {
                    viewExcerpt(translationIndex: currentTranslationIndex, excerpts: "mf 13:3-23", selectedId: 7)
                }
                .frame(maxHeight: .infinity)
                .mask(
                            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black, Color.black.opacity(0)]),
                                           startPoint: .init(x: 0.5, y: 0.8), // Начало градиента на 80% высоты
                                           endPoint: .init(x: 0.5, y: 1.0)) // Конец градиента в самом низу
                        )
                Spacer()
                
                // MARK: Панель с плеером
                VStack {
                    InfoView()
                    
                    AudioPlayerControlsView(player: player,
                                            timeObserver: PlayerTimeObserver(player: player),
                                            durationObserver: PlayerDurationObserver(player: player),
                                            itemObserver: PlayerItemObserver(player: player), localAccentColor: "localAccentColor")
                }
                .padding(.top, basePadding)
                .padding(.horizontal, basePadding)
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
            //.padding(20)
            // подложка
            .background(
                //Color("DarkGreen")
                LinearGradient(gradient: Gradient(colors: [Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen"), Color("DarkGreen-light"), Color("DarkGreen-light")]), startPoint: .top, endPoint: .bottom)
            )
            
            // слой меню
            MenuView(showMenu: $showMenu,
                     menuItem: $menuItem
            )
            .offset(x: showMenu ? 0 : -getRect().width)
        }
        
        .onAppear {
            guard let url = URL(string: "https://4bbl.ru/data/syn-bondarenko/40/13.mp3") else {
                return
            }
            let playerItem = AVPlayerItem(url: url)
            self.player.replaceCurrentItem(with: playerItem)
            
            //self.player.seek(to: CMTimeMake(value: Int64(periodFrom*100), timescale: 100))
        }
        //.ignoresSafeArea()
    }
}

struct InfoView: View {
    var body: some View {
        HStack {
            Text("SYNO")
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
    
    @State private var currentTime: TimeInterval = 0
    @State private var currentDuration: TimeInterval = 0
    @State private var state = PlaybackState.waitingForSelection
    @State private var lastRate: Float = 1.0
    
    @State private var stopAtEnd = true
    
    var body: some View {
        VStack(spacing: 0) {
            
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
                    let frameWidth: Double = UIScreen.main.bounds.size.width - basePadding*2
                    let point: Double = frameWidth / currentDuration
                    
                    let pointStart: Double = Double(periodFrom) * point
                    let pointCenter: Double = currentTime * point
                    let pointEnd: Double = Double(periodTo) * point
                    
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
                            .fill(Color("localAccentColor"))
                            .padding(.leading, secondLeading)
                            .padding(.trailing, secondTrailing)
                            .frame(width: frameWidth, height: 4)
                            .padding(.top, -0.9)
                            //.blendMode(.multiply)
                    }
                }
            }
            .padding(.top, basePadding)
            
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
                        //Image(systemName: "repeat")
                        Image(systemName: "backward.fill")
                    }
                    
                    Spacer()
                    
                    Button {
                        stopAtEnd = true
                        self.player.seek(to: CMTimeMake(value: Int64(periodFrom*100), timescale: 100))
                        self.state = .playing
                        self.player.play()
                    } label: {
                        //Image(systemName: "repeat")
                        Image(systemName: "backward.end")
                    }
                    
                    Spacer()
                    
                    Button {
                        self.player.seek(to: CMTimeMake(value: Int64((currentTime-15)*100), timescale: 100))
                    } label: {
                        Image(systemName: "gobackward.15")
                    }
                    
                    Spacer()
                    
                    Button {
                        if state == .playing {
                            state = .pausing
                            player.pause()
                        } else {
                            if self.currentTime >= Double(periodTo) {
                                self.stopAtEnd = false
                            }
                            
                            state = .playing
                            player.play()
                            player.rate = lastRate
                        }
                    } label: {
                        Image(systemName: state != .playing ? "play.circle.fill" : "pause.circle.fill")
                            .font(.system(size: 55))
                            .foregroundColor(Color(state == .buffering ? "Marigold" : "localAccentColor"))
                    }
                    
                    Spacer()
                    
                    Button {
                        self.player.seek(to: CMTimeMake(value: Int64((currentTime+15)*100), timescale: 100))
                    } label: {
                        Image(systemName: "goforward.15")
                    }
                    
                    Spacer()
                    
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
                        Text(lastRate == 1 ? "1x" : String(format: "%.1f", lastRate))
                            .font(.system(size: 18))
                        
                    }
                    
                    Spacer()
                    
                    
                    Button {
                        
                    } label: {
                        Image(systemName: "forward.fill")
                    }
                    
                }
                .foregroundColor(Color("localAccentColor"))
                
                
            }
            .padding(.top, 5)
            .padding(.bottom, 5)
            .font(.system(size: 22))
            
            
        }
        
        // MARK: Observers
        
        // Listen out for the time observer publishing changes to the player's time
        .onReceive(timeObserver.publisher) { time in
            // Update the local var
            //print("time: \(time)")
            self.currentTime = time
            // And flag that we've started playback
            ///if time > 0 {
            ///    self.state = .playing
            ///}
            
            if time > Double(periodTo) && self.stopAtEnd {
                self.state = .pausing
                self.player.pause()
            }
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
            if currentTime >= Double(periodTo) {
                self.stopAtEnd = false
            }
        }
    }
}



struct TestPageReadView: View {
    
    @State var showMenu: Bool = false
    @State var menuItem: MenuItem = .read
    
    var body: some View {
        PageReadView(showMenu: $showMenu,
                     menuItem: $menuItem)
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

