import Foundation
import SwiftUI

struct PodcastPlayButton: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @StateObject var episode: PodcastEpisodeObject
    var body: some View {
        if audioPlayer.playerState == .playing && audioPlayer.currentEpisode == episode {
            Button(action: {
                audioPlayer.pause()
            }) {
                Image(systemName: "pause.circle").foregroundColor(.purple)
            }
        } else {
            Button(action: {
                audioPlayer.play(episode: episode)
            }) {
                Image(systemName: "play.circle").foregroundColor(.purple)
            }
        }
    }
}

struct PodcastDurationText: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    @StateObject var episode: PodcastEpisodeObject
    @State private var currentTime: Double = 0

    var body: some View {
        HStack {
            if let episode = episode {
                if audioPlayer.currentEpisode == episode {
                    Text(
                        "\(currentTime.toDurationString()) / \(episode.duration.toDurationString())"
                    ).font(.caption).foregroundColor(.gray).onReceive(audioPlayer.currentTimeObserver.publisher) { time in
                        currentTime = time
                    }
                    ProgressView(value: currentTime, total: episode.duration)
                        .foregroundColor(.purple)
                    Spacer()
                } else {
                    Text(
                        "\(episode.duration.toDurationString())"
                    ).font(.caption).foregroundColor(.gray)
                    Spacer()
                }
            } else {
                Text("00:00").font(.caption).foregroundColor(.gray)
                Spacer()
            }
        }.frame(height: 10)
    }
}

struct PodcastPlayerToolBar: View {
    @EnvironmentObject var audioPlayer: AudioPlayer
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            VStack {
                HStack {
                    if let currentEpisode = audioPlayer.currentEpisode {
                        Text(currentEpisode.name).lineLimit(1)
                            .font(.subheadline)
                        Spacer()
                        PodcastPlayButton(episode: currentEpisode).padding(4)
                    } else {
                        Text("Not Playing").disabled(true)
                        Spacer()
                    }
                }.frame(height: 24)
                HStack {
                    if let currentEpisode = audioPlayer.currentEpisode {
                        PodcastDurationText(episode: currentEpisode)
                    } else {
                        Text("00:00 / 00:00").font(.caption).foregroundColor(.gray)
                        Spacer()
                    }
                }
                Spacer()
            }.padding()
        }.frame(maxWidth: .infinity)
    }
}
