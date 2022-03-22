//
//  AudioPlayer.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/26.
//

import AVFoundation
import Foundation
import SwiftUI
import MediaPlayer

class AudioPlayer: NSObject, AVAudioPlayerDelegate, ObservableObject {
    static let shared = AudioPlayer()

    @Published var currentEpisode: PodcastEpisode?
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var currentTimeRatio: Double = 0

    var player: AVPlayer?
    var udpateCurrentTimeTimer: Timer?

    override init() {
        super.init()
        
        udpateCurrentTimeTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true,
            block: { _ in
                self.currentTime = (self.player?.currentTime() ?? CMTime.zero).seconds
                if let currentEpisode = self.currentEpisode {
                    if currentEpisode.duration > 0 {
                        self.currentTimeRatio = self.currentTime / currentEpisode.duration
                    } else {
                        self.currentTimeRatio = 0
                    }
                } else {
                    self.currentTimeRatio = 0
                }
            }
        )
    }
    
    func activateAudioSessionIfNeeded() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio)
            try session.setActive(true)
        } catch {
            fatalError("Failed to activate audio session.")
        }
    }

    func play(episode: PodcastEpisode) {
        activateAudioSessionIfNeeded()
        if currentEpisode?.episodeURL == episode.episodeURL {
            player?.play()
        } else {
            player?.pause()
            player = AVPlayer(url: episode.episodeURL!)
            player?.play()

            currentEpisode = episode
            isPlaying = true
        }
    }

    func pause() {
        player?.pause()
        currentEpisode = nil
        isPlaying = false
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        isPlaying = false
    }
}
