//
//  ContentView.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/26.
//

import SwiftUI
import XMLCoder
import Combine
import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            PodcastListView()
                .navigationBarTitle(Text("Feeds"))
                .toolbar {
                    ToolbarItemGroup(placement: .bottomBar) {
                        PodcastPlayerToolBar().environmentObject(AudioPlayer.shared)
                    }
                }
        }
    }
}

let artworkURL = URL(fileURLWithPath: Bundle.main.path(forResource: "artwork", ofType: "png")!)

struct PodcastListView: View {
    var body: some View {
        List {
            PodcastListCell(feed: PodcastFeed(
                name: "Image Cast",
                feedURL: URL(string: "https://anchor.fm/s/3f0f1de4/podcast/rss"),
                artworkURL: URL(string: "https://s3-us-west-2.amazonaws.com/anchor-generated-image-bank/production/podcast_uploaded_nologo400/10479553/10479553-1622526656948-b7c7992408ad7.jpg"),
                episodes: []
            ))
            PodcastListCell(feed: PodcastFeed(
                name: "研エンの仲",
                feedURL: URL(string: "https://anchor.fm/s/2631f634/podcast/rss"),
                artworkURL: artworkURL,
                episodes: [
                    PodcastEpisode(name: "#0 Podcastを始めた理由について.mp3",
                                   episodeURL: URL(
                                       fileURLWithPath: "episode.mp3"
                                   )),
                ]
            ))
        }
    }
}

struct PodcastListCell: View {
    @State var feed: PodcastFeed
    var body: some View {
        HStack {
            UrlImageView(urlString: feed.artworkURL?.absoluteString)
                .frame(width: 48, height: 48, alignment: .center)
                .padding(4)
            NavigationLink(destination: PodcastDetailView(feed: feed)) {
                Text(feed.name).padding()
            }
        }
    }
}

struct PodcastLoadView: View {
    @State var feed: PodcastFeed
    @State var cancellables: Set<AnyCancellable> = []

    var body: some View {
        VStack {
            Text("Refreshing..")
            ForEach(feed.episodes) { episode in
                PodcastEpisodeCell(episode: episode)
            }
        }.onAppear {
//            feed.refresh()
            let fetcher = FeedFetcher()
            fetcher.fetchEpisodes(feedURL: feed.feedURL!).sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { _ in
                self.feed.episodes = []
            }).store(in: &cancellables)
        }
    }
}

struct PodcastLoadView_Previews: PreviewProvider {
    static var previews: some View {
        PodcastLoadView(feed: PodcastFeed(
            name: "研エンの仲",
            feedURL: URL(string: "https://anchor.fm/s/2631f634/podcast/rss"),
            artworkURL: URL(fileURLWithPath: "artwork.png"),
            episodes: [
                PodcastEpisode(name: "#0 Podcastを始めた理由について.mp3",
                               episodeURL: URL(
                                   fileURLWithPath: "episode.mp3"
                               )),
                PodcastEpisode(name: "#0 Podcastを始めた理由について.mp3",
                               episodeURL: URL(
                                   fileURLWithPath: "episode.mp3"
                               )),
                PodcastEpisode(name: "#0 Podcastを始めた理由について.mp3",
                               episodeURL: URL(
                                   fileURLWithPath: "episode.mp3"
                               )),
                PodcastEpisode(name: "#0 Podcastを始めた理由について.mp3",
                               episodeURL: URL(
                                   fileURLWithPath: "episode.mp3"
                               )),
            ]
        )).environmentObject(AudioPlayer.shared)
    }
}
