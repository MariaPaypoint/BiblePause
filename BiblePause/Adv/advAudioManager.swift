//
//  advAudioManager.swift
//  cep
//
//  Created by Maria Novikova on 27.08.2022.
//

import AVFoundation
import Combine
import MediaPlayer

// MARK: PlayerTimeObserver

class PlayerTimeObserver {
    let publisher = PassthroughSubject<TimeInterval, Never>()
    private weak var player: AVPlayer?
    private var timeObservation: Any?
    private var paused = false
    
    init(player: AVPlayer) {
        self.player = player
        
        // Periodically observe the player's current time, whilst playing
        timeObservation = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.2, preferredTimescale: 600), queue: nil) { [weak self] time in
            guard let self = self else { return }
            // If we've not been told to pause our updates
            guard !self.paused else { return }
            // Publish the new player time
            self.publisher.send(time.seconds)
        }
    }
    
    deinit {
        if let player = player,
            let observer = timeObservation {
            player.removeTimeObserver(observer)
        }
    }
    
    func pause(_ pause: Bool) {
        paused = pause
    }
    
    
}

// MARK: PlayerDurationObserver

class PlayerDurationObserver {
   let publisher = PassthroughSubject<TimeInterval, Never>()
   private var cancellable: AnyCancellable?
   
   init(player: AVPlayer) {
       let durationKeyPath: KeyPath<AVPlayer, CMTime?> = \.currentItem?.duration
       cancellable = player.publisher(for: durationKeyPath).sink { duration in
           guard let duration = duration else { return }
           guard duration.isNumeric else { return }
           self.publisher.send(duration.seconds)
       }
   }
   
   deinit {
       cancellable?.cancel()
   }
}


/*
// в отрефакторенной версии не нужно
class PlayerItemObserver {
    let publisher = PassthroughSubject<Bool, Never>()
    private var itemObservation: NSKeyValueObservation?
    
    init(player: AVPlayer) {
        // Observe the current item changing
        itemObservation = player.observe(\.currentItem) { [weak self] player, change in
            guard let self = self else { return }
            // Publish whether the player has an item or not
            self.publisher.send(player.currentItem != nil)
        }
    }
    
    deinit {
        if let observer = itemObservation {
            observer.invalidate()
        }
    }
}
*/
 
// MARK: PlayerModel

class PlayerModel: ObservableObject {
    
    enum PlaybackState: Int { // private
        case waitingForSelection
        case waitingForPlay
        case waitingForPause
        case buffering
        case playing
        case pausing
        case autopausing
        case finished
    }
    
    private let player: AVPlayer
    private let durationObserver: PlayerDurationObserver
    private var timeObserver: PlayerTimeObserver
    private var boundaryObserverBegin: Any?
    private var boundaryObserverEnd: Any?
    private var endPlayingObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var state = PlaybackState.waitingForSelection
    @Published var periodFrom: Double = 0
    @Published var periodTo: Double = 0 // 0 означает отсутствие конца отрывка, но оно потом перекроется
    @Published var currentDuration: TimeInterval = 0
    @Published var currentTime: TimeInterval = 0
    @Published private(set) var currentSpeed: Float = 1.0
    
    private var oldState = PlaybackState.waitingForSelection
    private var audioVerses: [BibleAcousticalVerseFull] = []
    private var currentVerseIndex: Int = -1
    private var stopAtEnd = true
    
    var onStartVerse: ((Int) -> Void)? // устанавливается снаружи, поэтому без private
    var onEndVerse: (() -> Void)? // устанавливается снаружи, поэтому без private
    var smoothPauseLength = 0.3 // устанавливается снаружи, поэтому без private
    
    private var pauseTimer: Timer?
    
    private var itemTitle: String = ""
    private var itemSubtitle: String = ""
    
    // MARK: init
    init() {
        
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
        try? AVAudioSession.sharedInstance().setActive(true)
        
        self.player = AVPlayer()
        self.durationObserver = PlayerDurationObserver(player: self.player)
        self.timeObserver = PlayerTimeObserver(player: self.player)
        
        self.setupNowPlaying()
        self.setupRemoteTransportControls()
        
        // наблюдаем, когда подгрузится песня и определится ее длина
        durationObserver.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] duration in
                self?.currentDuration = duration
                
                if self?.state == .buffering {
                    self?.state = .waitingForPlay
                    self?.player.seek(to: CMTimeMake(value: Int64(self!.periodFrom*100), timescale: 100))
                    self?.currentTime = self?.periodFrom ?? 0
                    self?.findAndSetCurrentVerseIndex()
                }
                
                if self?.oldState == .playing {
                    self?.playSimple()
                }
                
            }
            .store(in: &cancellables)
        
        // Подписка на уведомления о прерываниях
        NotificationCenter.default.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: AVAudioSession.sharedInstance())
            
        // наблюдаем за изменением позиции
        timeObserver.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                self?.currentTime = time
            }
            .store(in: &cancellables)
        
        // Пример подписки на окончание трека
        endPlayingObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            // Здесь меняем state и делаем что нужно, когда трек доиграл
            //print("Reached the absolute end of the file.")
            self.state = .finished
        }
    }
    
    deinit {
        // Важно не забыть убрать подписку
        if let endPlayingObserver = endPlayingObserver {
            NotificationCenter.default.removeObserver(endPlayingObserver)
        }
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        if type == .began {
            // Прерывание началось, приостановить воспроизведение
            pauseSimple()
        } else if type == .ended {
            // Прерывание закончилось, можно возобновить воспроизведение
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    playSimple()
                }
            }
        }
    }
    
    private func setupNowPlaying() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = itemTitle
        nowPlayingInfo[MPMediaItemPropertyArtist] = itemSubtitle
        // Добавьте дополнительные метаданные по необходимости
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] event in
            self?.playSimple()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] event in
            self?.pauseSimple()
            return .success
        }
        
        // Добавьте другие команды по необходимости
    }

    // MARK: установка параметров новой композиции
    func setItem(playerItem: AVPlayerItem, periodFrom: Double, periodTo: Double, audioVerses: [BibleAcousticalVerseFull], itemTitle: String, itemSubtitle: String) {
        
        self.oldState = self.state
        if self.state == .playing {
            self.pauseSimple()
        }
        
        self.periodFrom = periodFrom
        self.periodTo = periodTo
        
        self.audioVerses = audioVerses
        self.currentVerseIndex = -1
        
        self.state = .buffering
        self.currentTime = 0
        self.currentDuration = 0
        
        self.deleteObservation()
        self.setObservation()
        
        self.itemTitle = itemTitle
        self.itemSubtitle = itemSubtitle
        self.setupNowPlaying()
        
        self.player.replaceCurrentItem(with: playerItem)
        
    }
    
    // Удаление предыдущих наблюдателей, если они существуют
    private func deleteObservation() {
        if let observerBegin = boundaryObserverBegin {
            player.removeTimeObserver(observerBegin)
            self.boundaryObserverBegin = nil
        }
        if let observerEnd = boundaryObserverEnd {
            player.removeTimeObserver(observerEnd)
            self.boundaryObserverEnd = nil
        }
    }
    
    private func setObservation() {
        // вычисляем время
        var timesBegin: [NSValue] = []
        var timesEnd: [NSValue] = []
        
        for verse in audioVerses {
            let verseBeginTime = CMTime(seconds: verse.begin, preferredTimescale: 10)
            timesBegin.append(NSValue(time: verseBeginTime))
            let verseEndTime = CMTime(seconds: verse.end, preferredTimescale: 10)
            timesEnd.append(NSValue(time: verseEndTime))
        }
        
        // наблюдаем за началом стиха, чтобы позиционировать
        boundaryObserverBegin = player.addBoundaryTimeObserver(forTimes: timesBegin, queue: .main) {
            //print("Reached verse BEGIN")
            self.currentTime = CMTimeGetSeconds(self.player.currentTime())
            self.findAndSetCurrentVerseIndex()
        }
        
        // наблюдаем за концом стиха, чтобы делать паузы
        boundaryObserverEnd = player.addBoundaryTimeObserver(forTimes: timesEnd, queue: .main) {
            //print("Reached verse END")
            // остановка при достижении конца отрывка
            if self.stopAtEnd && self.currentVerseIndex == self.audioVerses.count - 1 {
                self.pauseSimple()
            }
            else {
                self.onEndVerse?()
            }
        }
    }
    
    // ищем стих, в который точно попадает текущее положение
    private func findAndSetCurrentVerseIndex() {
        for (index, verse) in audioVerses.enumerated() {
            // +0.1, т.к. позиционирование не точное, может сработать чуть раньше
            if currentTime + 0.1 >= verse.begin && currentTime + 0.1 <= verse.end {
                //print("index \(index), currentVerseIndex \(currentVerseIndex), currentTime + 0.1 \(currentTime + 0.1), begin \(verse.begin), end \(verse.end)")
                if index != currentVerseIndex {
                    //print("cur changed from", currentVerseIndex, "to", index)
                }
                
                setCurrentVerseIndex(index)
                break
            }
        }
    }
    
    private func setCurrentVerseIndex(_ cur: Int) { //
        //print("setCurrentVerseIndex \(cur)")
        if cur != self.currentVerseIndex { //  && cur != -1
            self.currentVerseIndex = cur
            self.onStartVerse?(cur)
        }
    }
    
    // MARK: воспр/пауза
    func doPlayOrPause() {
        if self.state == .playing {
            pauseSmoothly(duration: smoothPauseLength)
        }
        else if state == .buffering {
            // ничего не делать
        }
        else if state == .finished {
            self.restart()
            self.playSimple()
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
        //self.timeObserver.pause(false)
        self.player.play()
        self.state = .playing
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
                let to = CMTimeGetSeconds(self.player.currentTime()) - duration
                self.player.seek(to: CMTimeMake(value: Int64(to*100), timescale: 100))
            }
        }
    }
    
    func breakForSeconds(_ seconds: Double) {
        self.player.pause()
        self.state = .autopausing
        
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // проверим, а то вдруг уже совсем остановили
            if self.state == .autopausing {
                self.playSimple()
            }
        }
    }
    
    // MARK: перемотка
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
            findAndSetCurrentVerseIndex()
        }
    }
    
    func restart() {
        if state == .playing || state == .pausing || state == .finished {
            stopAtEnd = true
            setCurrentVerseIndex(-1)
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
    
    // MARK: скорость
    func changeSpeed() {
        if currentSpeed >= 2 || currentSpeed < 0.6 {
            currentSpeed = 0.6
        }
        else {
            currentSpeed += 0.2
        }
        
        player.defaultRate = currentSpeed
        if state == .playing {
            player.rate = currentSpeed
            //player.setRate(currentSpeed, time: .invalid, atHostTime: .invalid)
        }
    }
    
    func setSpeed(speed: Float) {
        currentSpeed = speed
        player.defaultRate = speed
    }
    
    
}
