//
//  PodcastFeed.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/26.
//

import Combine
import SwiftUI
import SyndiKit

struct PodcastDetailView: View {
    @StateObject var feed: PodcastFeedObject

    var body: some View {
        VStack {
            List {
                Text(feed.name)
                    .listRowSeparator(.hidden)
                    .frame(maxWidth: .infinity, alignment: .center)
                UrlImageView(imageURL: $feed.artworkURL)
                    .frame(width: 160, height: 160, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                ForEach($feed.episodes, content: { $episode in
                    PodcastEpisodeCell(episode: $episode)
                })
            }
            .listStyle(PlainListStyle())
            .refreshable {
                feed.refresh()
            }
            Spacer()
        }
    }
}

struct PodcastEpisodeCell: View {
    @Binding var episode: PodcastEpisodeObject
    @EnvironmentObject var audioPlayer: AudioPlayer

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(episode.name).lineLimit(1).font(.subheadline)
                    Spacer()
                }
                HStack {
                    PodcastDurationText(episode: episode)
                    Spacer()
                }
                Text(episode.summary).lineLimit(3).font(.caption).foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)

            }
            PodcastPlayButton(episode: episode).padding(6)
        }
    }
}

struct PodcastDetailView_Previews: PreviewProvider {
    @State static var previewFeed = PodcastFeedObject(
        name: "研エンの仲",
        feedURL: URL(
            fileURLWithPath: "podcast.rss"
        ),
        artworkURL: URL(fileURLWithPath: "artwork.png"),
        episodes: Array(repeating: PodcastEpisodeObject(
            name: "エピソードのタイトル",
            episodeURL: URL(fileURLWithPath: "episode.mp3"),
            duration: 1234,
            summary: String(repeating: "Podcastの概要 ", count: 100)
        ), count: 4)
    )
    static var previews: some View {
        PodcastDetailView(feed: previewFeed)
            .environmentObject(AudioPlayer.shared)
    }
}
