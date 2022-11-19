//
//  PodcastFeedAddRSSForm.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/27.
//

import Foundation
import SwiftUI

struct PodcastFeedAddRSSView: View {
    @State var feedURL: String = ""
    @StateObject var repository: PodcastRepository
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        VStack {
            Form {
                TextField("RSS Feed URL", text: $feedURL)
                Button("追加") {
                    if let feedURL = URL(string: feedURL) {
                        repository.feeds.append(PodcastFeedObject.init(name: "New Podcast", feedURL: feedURL, artworkURL: feedURL, episodes: []))
                        self.presentation.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
