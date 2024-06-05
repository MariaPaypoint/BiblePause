//
//  advAudioManager.swift
//  cep
//
//  Created by Maria Novikova on 27.08.2022.
//


//import Foundation
import AVFoundation
//import AVKit

/*
class SoundManager : ObservableObject {
    var audioPlayer: AVPlayer?

    func playSound(sound: String) {
        if let url = URL(string: sound) {
            self.audioPlayer = AVPlayer(url: url)
        }
    }
    
    func goToTime(seconds: Int64) {
        let videoStartTime: CMTime = CMTimeMake(value: seconds, timescale: 1)
        audioPlayer?.seek(to: videoStartTime)
    }
    
    func getLen() -> String {
        //audioPlayer?.currentItem?.duration.duration ?? "-00:00"
        return audioPlayer?.currentItem?.duration.positionalTime ?? "-00:00"
    }
}

extension CMTime {
    var roundedSeconds: TimeInterval {
        guard !(seconds.isNaN || seconds.isInfinite) else {
            print("0")
            return 0 // or do some error handling
        }
        print(seconds.rounded())
        return seconds.rounded()
    }
    
    var hours:  Int { return Int(roundedSeconds / 3600) }
    var minute: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 3600) / 60) }
    var second: Int { return Int(roundedSeconds.truncatingRemainder(dividingBy: 60)) }
    
    var positionalTime: String {
        return hours > 0 ?
            String(format: "%d:%02d:%02d",
                   hours, minute, second) :
            String(format: "%02d:%02d",
                   minute, second)
    }
}
*/
/*
extension CMTime {
    var hrs:  Int { return Int(seconds.rounded() / 3600) }
    var mins: Int { return Int(seconds.truncatingRemainder(dividingBy: 3600) / 60) }
    var secs: Int { return Int(seconds.truncatingRemainder(dividingBy: 60)) }
    var duration: String { return hrs > 0 ? String(format: "%i:%02i:%02i", hrs, mins, secs) : String(format: "%02i:%02i", mins, secs)
    }
}
*/

/*
class AudioManager {
    static let shared = AudioManager()
    
    var audioPlayer: AVAudioPlayer?
    
    func startPlayer(track: String) {
        let url = Bundle.main.url(forResource: track, withExtension: "mp3")
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url!)
            
            audioPlayer?.play()
        } catch {
            print("Fail playing", error)
        }
    }
}
*/


//


import Combine

class PlayerTimeObserver {
    let publisher = PassthroughSubject<TimeInterval, Never>()
    private weak var player: AVPlayer?
    private var timeObservation: Any?
    private var paused = false
    
    init(player: AVPlayer) {
        self.player = player
        
        // Periodically observe the player's current time, whilst playing
        timeObservation = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: nil) { [weak self] time in
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

