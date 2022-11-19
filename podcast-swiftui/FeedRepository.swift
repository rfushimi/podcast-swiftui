import Combine
import Foundation
import XMLCoder

struct RSS: Codable {
    let channel: Channel

    struct Channel: Codable {
        let title: String
        let description: String
        let link: String
        let image: Image
        let item: [Item]

        struct Image: Codable {
            let url: String
        }

        struct Item: Codable {
            let title: String
            let link: String
            let enclosure: Enclosure
            let summary: String
            let duration: UInt

            struct Enclosure: Codable {
            let url: String
            let length: UInt

                enum CodingKeys: String, CodingKey {
                    case url
                    case length
                }

                static func nodeEncoding(for _: CodingKey) -> XMLEncoder.NodeEncoding {
                    return .attribute
                }
            }
        }
    }
}

protocol FeedFetcherProtocol {
    func fetchEpisodes(feedURL: URL) -> Future<RSS, APIError>
}

enum APIError: Error {
    case request
    case response(error: Error? = nil)
    case emptyResponse
    case decode(Error)
    case http(status: Int, data: Data)
}

final class FeedFetcher: FeedFetcherProtocol {
    func fetchEpisodes(feedURL: URL) -> Future<RSS, APIError> {
        return Future<RSS, APIError> { promise in
            URLSession.shared
                .dataTask(with: URLRequest(url: feedURL)) { data, response, error in
                    if let error = error {
                        promise(.failure(.response(error: error)))
                    }
                    guard let data = data, let response = response as? HTTPURLResponse else {
                        promise(.failure(.response()))
                        return
                    }
                    guard 200 ..< 300 ~= response.statusCode else {
                        promise(.failure(.http(status: response.statusCode, data: data)))
                        return
                    }
                    let decoder = XMLDecoder()
                    decoder.shouldProcessNamespaces = true
                    do {
                        let RSSFeed = try decoder.decode(RSS.self, from: data)
                        print(RSSFeed)
                        promise(.success(RSSFeed))
                    } catch {
                        promise(.failure(APIError.decode(error)))
                    }
                }.resume()
        }
    }
}
