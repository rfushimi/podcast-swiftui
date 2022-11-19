//
//  ContentView.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/26.
//

import Combine
import CoreData
import SwiftUI

struct MainView: View {
    @ObservedObject var repository: PodcastRepository
    @Environment(\.scenePhase) private var scenePhase
    let saveAction: () -> Void
    var body: some View {
        NavigationView {
            PodcastListView(repository: repository)
                .navigationBarTitle(Text("Feeds"))
        }.onChange(of: scenePhase) { phase in
            if phase == .inactive { saveAction() }
        }
    }
}

struct PodcastListView: View {
    @ObservedObject var repository: PodcastRepository
    var body: some View {
        VStack {
            List {
                ForEach(repository.feeds) { feed in
                    PodcastListCell(feed: feed)
                }.onDelete(perform: rowRemove).listRowSeparator(.hidden)
                NavigationLink(destination: PodcastFeedAddRSSView(repository: repository)) {
                    Text("Add RSS Feed")
                }.listRowSeparator(.hidden)
                Button("Remove all feeds") {
                    repository.feeds = []
                }.listRowSeparator(.hidden)
                Link("Manage Subscription", destination: URL.init(string: "https://apps.apple.com/account/subscriptions")!)
            }.refreshable {
                repository.feeds.forEach { feed in
                    feed.refresh()
                }
            }
            Spacer()
            PodcastPlayerToolBar().frame(height: 40)
        }
    }

    func addFeed(_ feed: PodcastFeedObject) {
        if !repository.feeds.contains(feed) {
            repository.feeds.append(feed)
            feed.refresh()
        }
    }

    func rowRemove(offsets: IndexSet) {
        repository.feeds.remove(atOffsets: offsets)
    }
}

struct PodcastListCell: View {
    @ObservedObject var feed: PodcastFeedObject
    var body: some View {
        HStack {
            UrlImageView(imageURL: $feed.artworkURL)
                .frame(width: 48, height: 48, alignment: .center)
                .padding(4)
            NavigationLink(destination: PodcastDetailView(feed: feed)) {
                Text(feed.name).padding()
            }
        }
    }
}

// MARK: Previews

struct PodcastListView_Previews: PreviewProvider {
    static var previewFeed = PodcastFeedObject(
        name: "研エンの仲",
        feedURL: URL(string: "https://anchor.fm/s/2631f634/podcast/rss")!,
        artworkURL: URL(fileURLWithPath: "artwork.png"),
        episodes: [
            PodcastEpisodeObject(name: "#0 Podcastを始めた理由について.mp3",
                                 episodeURL: URL(
                                     fileURLWithPath: "episode.mp3"
                                 ), duration: 1234, summary: "Podcastの概要"),
        ]
    )
    static let repository: PodcastRepository = {
        let repository = PodcastRepository()
        repository.feeds = [previewFeed, previewFeed, previewFeed]
        return repository
    }()

    static var previews: some View {
        PodcastListView(repository: self.repository)
            .environmentObject(AudioPlayer.shared)
    }
}

struct PodcastListCell_Previews: PreviewProvider {
    @State static var previewFeed = PodcastFeedObject(
        name: "研エンの仲",
        feedURL: URL(string: "https://anchor.fm/s/2631f634/podcast/rss")!,
        artworkURL: URL(fileURLWithPath: "artwork.png"),
        episodes: [
            PodcastEpisodeObject(name: "#0 Podcastを始めた理由について.mp3",
                                 episodeURL: URL(
                                     fileURLWithPath: "episode.mp3"
                                 ), duration: 1234, summary: "Podcastの概要"),
        ]
    )
    static var previews: some View {
        List {
            PodcastListCell(feed: previewFeed).environmentObject(AudioPlayer.shared)
            PodcastListCell(feed: previewFeed).environmentObject(AudioPlayer.shared)
            PodcastListCell(feed: previewFeed).environmentObject(AudioPlayer.shared)
        }
        .environmentObject(AudioPlayer.shared)
    }
}

// struct PodcastLoadView: View {
//    @Binding var feed: PodcastFeedObject
//    @State var cancellables: Set<AnyCancellable> = []
//
//    var body: some View {
//        VStack {
//            Text("Refreshing..")
//            ForEach($feed.episodes) { $episode in
//                PodcastEpisodeCell(episode: $episode)
//            }
//        }.onAppear {
//            let fetcher = FeedFetcher()
//            fetcher.fetchEpisodes(feedURL: feed.feedURL!).sink(receiveCompletion: { completion in
//                print(completion)
//            }, receiveValue: { _ in
//                self.feed.episodes = []
//            }).store(in: &cancellables)
//        }
//    }
// }

// struct PodcastLoadView_Previews: PreviewProvider {
//    @State static var previewFeed = PodcastFeedObject(
//        name: "研エンの仲",
//        feedURL: URL(string: "https://anchor.fm/s/2631f634/podcast/rss")!,
//        artworkURL: URL(fileURLWithPath: "artwork.png"),
//        episodes: [
//            PodcastEpisodeObject(name: "#0 Podcastを始めた理由について.mp3",
//                                 episodeURL: URL(
//                                     fileURLWithPath: "episode.mp3"
//                                 ), duration: 1234, summary: "Podcastの概要"),
//        ]
//    )
//    static var previews: some View {
//        PodcastLoadView(feed:$previewFeed).environmentObject(AudioPlayer.shared)
//    }
// }
