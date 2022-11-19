//
//  AudioPlayer.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/26.
//

import AVFoundation
import Foundation
import MediaPlayer
import SwiftUI
import Combine

class PlayerTimeObserver {
  let publisher = PassthroughSubject<TimeInterval, Never>()
  private var timeObservation: Any?
  
  init(player: AVPlayer) {
    // Periodically observe the player's current time, whilst playing
    timeObservation = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: nil) { [weak self] time in
      guard let self = self else { return }
      // Publish the new player time
      self.publisher.send(time.seconds)
    }
  }
}

class AudioPlayer: NSObject, AVAudioPlayerDelegate, ObservableObject {
    enum PlayerState {
        case stopped
        case playing
        case paused
    }

    static let shared = AudioPlayer()
    unowned let nowPlayableBehavior: NowPlayable

    @Published var currentEpisode: PodcastEpisodeObject?
    @Published var playerState: PlayerState = .stopped {
        didSet {
            NSLog("%@", "**** Set player state \(playerState)")
        }
    }
    @Published var currentTime: Double = 0
    @Published var currentTimeRatio: Double = 0

    var player: AVQueuePlayer
    var udpateCurrentTimeTimer: Timer?
    let currentTimeObserver: PlayerTimeObserver
    
    // `true` if the current session has been interrupted by another app.
    private var isInterrupted: Bool = false

    override init() {
        // Configure the app for Now Playing Info and Remote Command Center behaviors.
        nowPlayableBehavior = ConfigModel.shared.nowPlayableBehavior
        player = AVQueuePlayer(items: [])
        player.allowsExternalPlayback = ConfigModel.shared.allowsExternalPlayback
        currentTimeObserver = PlayerTimeObserver(player: player)

        super.init()

        udpateCurrentTimeTimer = Timer.scheduledTimer(
            withTimeInterval: 0.5,
            repeats: true,
            block: { _ in
                self.currentTime = self.player.currentTime().seconds
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

        if player.currentItem != nil {
            _ = player.observe(\.currentItem, options: .initial) {
                [unowned self] _, _ in
                self.handlePlayerItemChange()
            }
            _ = player.observe(\.rate, options: .initial) {
                [unowned self] _, _ in
                self.handlePlaybackChange()
            }
            _ = player.observe(\.currentItem?.status, options: .initial) {
                [unowned self] _, _ in
                self.handlePlaybackChange()
            }
        }

        // Create a player, and configure it for external playback, if the
        // configuration requires.

        // Construct lists of commands to be registered or disabled.

        var registeredCommands = [] as [NowPlayableCommand]
        var enabledCommands = [] as [NowPlayableCommand]

        for group in ConfigModel.shared.commandCollections {
            registeredCommands
                .append(contentsOf: group.commands
                    .compactMap { $0.shouldRegister ? $0.command : nil })
            enabledCommands
                .append(contentsOf: group.commands
                    .compactMap { $0.shouldDisable ? $0.command : nil })
        }

        do {
            try nowPlayableBehavior.handleNowPlayableConfiguration(commands: registeredCommands,
                                                                   disabledCommands: enabledCommands,
                                                                   commandHandler: handleCommand(
                                                                       command:event:
                                                                   ),
                                                                   interruptionHandler: handleInterrupt(
                                                                       with:
                                                                   ))
        } catch {
            fatalError("Failed to set up audio player.")
        }
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

    func play(episode: PodcastEpisodeObject?) {
        if let episode = episode {
            activateAudioSessionIfNeeded()
            if currentEpisode?.episodeURL == episode.episodeURL {
                player.play()
            } else {
                player.pause()
                player.removeAllItems()
                let playerItem = AVPlayerItem(url: episode.episodeURL!)
                player.insert(playerItem, after: nil)
                player.play()

                currentEpisode = episode
                playerState = .playing

                handlePlayerItemChange()
            }
        } else {
            if let _ = currentEpisode {
                player.play()
                playerState = .playing
            }
        }
        
    }

    func pause() {
        player.pause()
        playerState = .paused
    }

    func optOut() {
        player.pause()
        player.removeAllItems()
        playerState = .stopped

        nowPlayableBehavior.handleNowPlayableSessionEnd()
    }

    func audioPlayerDidFinishPlaying(_: AVAudioPlayer, successfully _: Bool) {
        playerState = .stopped
    }

    private func togglePlayPause() {
        switch playerState {
        case .stopped:
            play(episode: currentEpisode)

        case .playing:
            pause()

        case .paused:
            play(episode: currentEpisode)
        }
    }

    private func handleCommand(command: NowPlayableCommand,
                               event: MPRemoteCommandEvent) -> MPRemoteCommandHandlerStatus
    {
        switch command {
        case .pause:
            pause()

        case .play:
            play(episode: currentEpisode)

        case .stop:
            pause()

        case .togglePausePlay:
            togglePlayPause()

        case .nextTrack:
            nextTrack()

        case .previousTrack:
            previousTrack()

        case .changePlaybackRate:
            guard let event = event as? MPChangePlaybackRateCommandEvent
            else { return .commandFailed }
            setPlaybackRate(event.playbackRate)

        case .seekBackward:
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            setPlaybackRate(event.type == .beginSeeking ? -3.0 : 1.0)

        case .seekForward:
            guard let event = event as? MPSeekCommandEvent else { return .commandFailed }
            setPlaybackRate(event.type == .beginSeeking ? 3.0 : 1.0)

        case .skipBackward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            skipBackward(by: event.interval)

        case .skipForward:
            guard let event = event as? MPSkipIntervalCommandEvent else { return .commandFailed }
            skipForward(by: event.interval)

        case .changePlaybackPosition:
            guard let event = event as? MPChangePlaybackPositionCommandEvent
            else { return .commandFailed }
            seek(to: event.positionTime)

//        case .enableLanguageOption:
//            guard let event = event as? MPChangeLanguageOptionCommandEvent else { return .commandFailed }
//            guard didEnableLanguageOption(event.languageOption) else { return .noActionableNowPlayingItem }

//        case .disableLanguageOption:
//            guard let event = event as? MPChangeLanguageOptionCommandEvent else { return .commandFailed }
//            guard didDisableLanguageOption(event.languageOption) else { return .noActionableNowPlayingItem }

        default:
            break
        }

        return .success
    }

    // MARK: Now Playing Info

    // Helper method: update Now Playing Info when the current item changes.

    private func handlePlayerItemChange() {
        guard playerState != .stopped else { return }
        if let currentEpisode = currentEpisode {
            let metadata = NowPlayableStaticMetadata(
                assetURL: currentEpisode.episodeURL!,
                mediaType: .audio,
                isLiveStream: false,
                title: currentEpisode.name,
                artist: currentEpisode.name,
                artwork: MPMediaItemArtwork(boundsSize: CGSize(width: 256, height: 256),
                                            requestHandler: { _ in return UIImage.init() }),
                albumArtist: currentEpisode.name,
                albumTitle: currentEpisode.name
            )
            nowPlayableBehavior.handleNowPlayableItemChange(metadata: metadata)
        }
    }

    // MARK: Interruptions

    // Handle a session interruption.

    private func handleInterrupt(with interruption: NowPlayableInterruption) {
        switch interruption {
        case .began:
            isInterrupted = true

        case let .ended(shouldPlay):
            isInterrupted = false

            switch playerState {
            case .stopped:
                break

            case .playing where shouldPlay:
                player.play()

            case .playing:
                playerState = .paused

            case .paused:
                break
            }

        case let .failed(error):
            print(error.localizedDescription)
            optOut()
        }
    }

    // Helper method: update Now Playing Info when playback rate or position changes.

    private func handlePlaybackChange() {
        guard playerState != .stopped else { return }

        // Find the current item.

        guard let currentItem = player.currentItem else { optOut(); return }
        guard currentItem.status == .readyToPlay else { return }

        // Create language option groups for the asset's media selection,
        // and determine the current language option in each group, if any.

        // Note that this is a simple example of how to create language options.
        // More sophisticated behavior (including default values, and carrying
        // current values between player tracks) can be implemented by building
        // on the techniques shown here.

        let asset = currentItem.asset

        // Construct the dynamic metadata, including language options for audio,
        // subtitle and closed caption tracks that can be enabled for the
        // current asset.

        let isPlaying = playerState == .playing
        let metadata = NowPlayableDynamicMetadata(rate: player.rate,
                                                  position: Float(currentItem.currentTime()
                                                      .seconds),
                                                  duration: Float(currentItem.duration.seconds))

        nowPlayableBehavior.handleNowPlayablePlaybackChange(playing: isPlaying, metadata: metadata)
    }

    private func nextTrack() {
        if case .stopped = playerState { return }

        player.advanceToNextItem()
    }

    private func previousTrack() {
        if case .stopped = playerState { return }

        let currentTime = player.currentTime().seconds
        let currentItems = player.items()
        let previousIndex = player.items().count - currentItems.count - 1

        guard currentTime < 3, previousIndex > 0,
              previousIndex < currentItems.count else { seek(to: .zero); return }

        player.removeAllItems()

        for playerItem in currentItems[(previousIndex - 1)...] {
            if player.canInsert(playerItem, after: nil) {
                player.insert(playerItem, after: nil)
            }
        }

        if case .playing = playerState {
            player.play()
        }
    }

    private func seek(to time: CMTime) {
        if case .stopped = playerState { return }

        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) {
            isFinished in
            if isFinished {
                self.handlePlaybackChange()
            }
        }
    }

    private func seek(to position: TimeInterval) {
        seek(to: CMTime(seconds: position, preferredTimescale: 1))
    }

    private func skipForward(by interval: TimeInterval) {
        seek(to: player.currentTime() + CMTime(seconds: interval, preferredTimescale: 1))
    }

    private func skipBackward(by interval: TimeInterval) {
        seek(to: player.currentTime() - CMTime(seconds: interval, preferredTimescale: 1))
    }

    private func setPlaybackRate(_ rate: Float) {
        if case .stopped = playerState { return }

        player.rate = rate
    }
}
