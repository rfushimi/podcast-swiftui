//
//  PodcastFeedAddRSSForm.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/27.
//

import Foundation

struct PodcastFeedAddRSSView: View {
    @State var feedURL: String = ""
    @Environment(\.presentationMode) var presentation
    var body: some View {
        VStack {
            Form {
                TextField("RSS Feed URL", text: $feedURL)
                Button("追加") {
                    self.presentation.wrappedValue.dismiss()
                }
            }
        }
    }
}
