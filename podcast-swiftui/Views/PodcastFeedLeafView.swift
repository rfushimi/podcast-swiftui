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
    @State var feed: PodcastFeed
    @State var cancellables: Set<AnyCancellable> = []

    var body: some View {
        VStack {
            List {
                Text(feed.name)
                    .listRowSeparator(.hidden)
                    .frame(maxWidth: .infinity, alignment: .center)
                UrlImageView(urlString: feed.feedURL?.absoluteString)
                    .frame(width: 160, height: 160, alignment: .center)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden)
                ForEach(feed.episodes) { episode in
                    PodcastEpisodeCell(episode: episode)
                }
                Button("Refresh") {
                    let fetcher = FeedFetcher()
                    fetcher.fetchEpisodes(feedURL: feed.feedURL!)
                        .sink(receiveCompletion: { completion in
                            print(completion)
                        }, receiveValue: { response in
                            var episodes: [PodcastEpisode] = []
                            for item in response.channel.item {
                                var ep = PodcastEpisode(name: item.title,
                                                        episodeURL: URL(string: item
                                                            .enclosure.url),
                                                        duration: Double(item.duration))
                                ep.summary = item.summary.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)

                                episodes.append(ep)
                            }
                            self.feed.episodes = episodes
                        }).store(in: &cancellables)
                }
                Spacer()
            }.listStyle(PlainListStyle())
        }.environmentObject(AudioPlayer.shared)
    }
}

struct PodcastEpisodeCell: View {
    @State var episode: PodcastEpisode
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
            }
            PodcastPlayButton(episode: episode)
        }
    }
}

struct PodcastDetailView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastDetailView(feed: PodcastFeed(
            name: "研エンの仲",
            feedURL: URL(
                fileURLWithPath: "podcast.rss"
            ),
            artworkURL: URL(fileURLWithPath: "artwork.png"),
            episodes: [
                PodcastEpisode(name: "#0 Podcastを始めた理由について.mp3",
                               episodeURL: URL(
                                   fileURLWithPath: "episode.mp3"
                               ),
                               summary: "limitedBy はオプショナルの引数ですが、limitedBy を指定しないと、実在する index を超えた値を指定するとエラーになります。検索しないので、実在する index を超えた値を指定してもエラーになりません。"),
                PodcastEpisode(name: "#0 Podcastを始めた理由について.mp3",
                               episodeURL: URL(
                                   fileURLWithPath: "episode.mp3"
                               ),
                               summary: "limitedBy はオプショナルの引数ですが、limitedBy を指定しないと、実在する index を超えた値を指定するとエラーになります。検索しないので、実在する index を超えた値を指定してもエラーになりません。"),
                PodcastEpisode(name: "#0 Podcastを始めた理由について.mp3",
                               episodeURL: URL(
                                   fileURLWithPath: "episode.mp3"
                               ),
                               summary: "limitedBy はオプショナルの引数ですが、limitedBy を指定しないと、実在する index を超えた値を指定するとエラーになります。検索しないので、実在する index を超えた値を指定してもエラーになりません。"),
                PodcastEpisode(name: "#0 Podcastを始めた理由について.mp3",
                               episodeURL: URL(
                                   fileURLWithPath: "episode.mp3"
                               ),
                               summary: "limitedBy はオプショナルの引数ですが、limitedBy を指定しないと、実在する index を超えた値を指定するとエラーになります。検索しないので、実在する index を超えた値を指定してもエラーになりません。"),
            ]
        ))
    }
}
