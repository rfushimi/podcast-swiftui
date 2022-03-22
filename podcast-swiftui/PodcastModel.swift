import Foundation

struct PodcastFeed: Identifiable, Equatable {
    let name: String
    let feedURL: URL?
    let artworkURL: URL?
    var episodes: [PodcastEpisode]
    var id: String { feedURL?.absoluteString ?? "" }
    static func == (lhs: PodcastFeed, rhs: PodcastFeed) -> Bool {
        return lhs.feedURL == rhs.feedURL
    }
}

struct PodcastEpisode: Identifiable, Equatable {
    let name: String
    let episodeURL: URL?
    var duration: Double = 100
    var summary: String = ""

    var id: String { episodeURL?.absoluteString ?? "" }
    static func == (lhs: PodcastEpisode, rhs: PodcastEpisode) -> Bool {
        return lhs.episodeURL == rhs.episodeURL
    }
}
