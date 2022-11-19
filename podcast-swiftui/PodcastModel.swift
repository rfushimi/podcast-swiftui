import Foundation
import Combine
import SwiftUI

class PodcastRepositoryStore: ObservableObject {
    @Published var repository: PodcastRepository = PodcastRepository()
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                       in: .userDomainMask,
                                       appropriateFor: nil,
                                       create: false)
            .appendingPathComponent("repository.data")
    }

    // MARK: Load
    static func load(completion: @escaping (Result<PodcastRepository, Error>)->Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURL = try fileURL()
                guard let file = try? FileHandle(forReadingFrom: fileURL) else {
                    DispatchQueue.main.async {
                        completion(.success(PodcastRepository.init()))
                    }
                    return
                }
                let repository = try JSONDecoder().decode(PodcastRepository.self, from: file.availableData)
                DispatchQueue.main.async {
                    completion(.success(repository))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    // MARK: Save
    static func save(repository: PodcastRepository, completion: @escaping (Result<Int, Error>)->Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(repository)
                let outfile = try fileURL()
                try data.write(to: outfile)
                DispatchQueue.main.async {
                    completion(.success(repository.feeds.count))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

class PodcastRepository: ObservableObject, Codable {
    @Published var feeds: [PodcastFeedObject] = []
    
    init() {}
    
    // MARK: Codable
    enum CodingKeys: CodingKey {
        case feeds
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        feeds = try container.decode(Array.self, forKey: .feeds)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(feeds, forKey: .feeds)
    }

}

class PodcastFeedObject: ObservableObject, Identifiable, Equatable, Codable {
    init(name: String, feedURL: URL, artworkURL: URL, episodes: [PodcastEpisodeObject]) {
        self.name = name
        self.feedURL = feedURL
        self.artworkURL = artworkURL
        self.episodes = episodes
    }

    @Published var name: String = ""
    @Published var feedURL: URL? = nil
    @Published var artworkURL: URL? = nil
    @Published var episodes: [PodcastEpisodeObject] = []
    private var cancellables: Set<AnyCancellable> = []
    
    func refresh() {
        let fetcher = FeedFetcher()
        fetcher.fetchEpisodes(feedURL: self.feedURL!)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { [weak self] response in
                self?.episodes = response.channel.item.map { item in
                    let episodeURL = URL(string: item.enclosure.url)!
                    let summary = item.summary.replacingOccurrences(
                        of: "<[^>]+>",
                        with: "",
                        options: .regularExpression,
                        range: nil
                    )
                    return PodcastEpisodeObject(
                        name: item.title,
                        episodeURL: episodeURL,
                        duration: Double(item.duration),
                        summary: summary
                    )
                }
                self?.name = response.channel.title
                self?.artworkURL = URL(string: response.channel.image.url)!
            }).store(in: &cancellables)
    }

    // MARK: Equatable, Identifiable
    var id: String { feedURL?.absoluteString ?? "" }
    static func == (lhs: PodcastFeedObject, rhs: PodcastFeedObject) -> Bool {
        return lhs.feedURL == rhs.feedURL
    }

    // MARK: Codable
    enum CodingKeys: CodingKey {
        case name
        case feedURL
        case artworkURL
        case episodes
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        feedURL = try container.decode(URL.self, forKey: .feedURL)
        artworkURL = try container.decode(URL.self, forKey: .artworkURL)
        episodes = try container.decode(Array.self, forKey: .episodes)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(feedURL, forKey: .feedURL)
        try container.encode(artworkURL, forKey: .artworkURL)
        try container.encode(episodes, forKey: .episodes)
    }
}

class PodcastEpisodeObject: ObservableObject, Identifiable, Equatable, Codable {
    init(name: String, episodeURL: URL, duration: Double, summary: String) {
        self.name = name
        self.episodeURL = episodeURL
        self.duration = duration
        self.summary = summary
    }

    @Published var name: String = ""
    @Published var episodeURL: URL? = nil
    @Published var duration: Double = 0
    @Published var summary: String = ""

    var id: String { episodeURL?.absoluteString ?? "" }
    static func == (lhs: PodcastEpisodeObject, rhs: PodcastEpisodeObject) -> Bool {
        return lhs.episodeURL == rhs.episodeURL
    }

    // MARK: Codable
    enum CodingKeys: CodingKey {
        case name
        case episodeURL
        case duration
        case summary
    }
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        episodeURL = try container.decode(URL.self, forKey: .episodeURL)
        duration = try container.decode(Double.self, forKey: .duration)
        summary = try container.decode(String.self, forKey: .summary)
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(episodeURL, forKey: .episodeURL)
        try container.encode(duration, forKey: .duration)
        try container.encode(summary, forKey: .summary)
    }
}

class FeedRefreshBehavior: ObservableObject {
    @ObservedObject var feed: PodcastFeedObject
//    var cancellables: Set<AnyCancellable> = []
    init(feed: PodcastFeedObject) {
        self.feed = feed
    }
}
