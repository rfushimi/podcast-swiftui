//
//  ImageView.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/26.
//

import SwiftUI

struct UrlImageView: View {
    @ObservedObject var urlImageModel: UrlImageModel

    init(urlString: String?) {
        urlImageModel = UrlImageModel(urlString: urlString)
    }

    var body: some View {
        Image(uiImage: urlImageModel.image ?? UrlImageView.defaultImage!)
            .resizable()
            .scaledToFit()
    }

    static var defaultImage = UIImage(named: "artwork.png")
}

class UrlImageModel: ObservableObject {
    @Published var image: UIImage?
    var urlString: String?

    init(urlString: String?) {
        self.urlString = urlString
        loadImage()
    }

    func loadImage() {
        loadImageFromUrl()
    }

    func loadImageFromUrl() {
        guard let urlString = urlString else {
            return
        }

        let url = URL(string: urlString)!
        let task = URLSession.shared.dataTask(
            with: url,
            completionHandler: getImageFromResponse(data:response:error:)
        )
        task.resume()
    }

    func getImageFromResponse(data: Data?, response _: URLResponse?, error: Error?) {
        guard error == nil else {
            print("Error: \(error!)")
            return
        }
        guard let data = data else {
            print("No data found")
            return
        }

        DispatchQueue.main.async {
            guard let loadedImage = UIImage(data: data) else {
                return
            }
            self.image = loadedImage
        }
    }
}

struct ImageView_Previews: PreviewProvider {
    static var previews: some View {
        UrlImageView(urlString: "episode.mp3")
            .frame(width: 30, height: 30, alignment: .center)
            .previewLayout(.sizeThatFits)
        UrlImageView(urlString: "episode.mp3")
            .frame(width: 64, height: 64, alignment: .center)
            .previewLayout(.sizeThatFits)
    }
}
