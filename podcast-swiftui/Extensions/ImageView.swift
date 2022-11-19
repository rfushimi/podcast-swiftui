//
//  ImageView.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/26.
//

import SwiftUI

struct UrlImageView: View {
    @ObservedObject var urlImageModel: UrlImageModel
    @Binding var imageURL: URL?

    init(imageURL: Binding<URL?>) {
        self._imageURL = imageURL
        if let url = imageURL.wrappedValue {
            self.urlImageModel = UrlImageModel(url: url)
        } else {
            self.urlImageModel = UrlImageModel(url: nil)
        }
    }

    var body: some View {
        Image(uiImage: urlImageModel.image ?? UrlImageView.defaultImage!)
            .resizable()
//            .scaledToFit()
//            .onChange(of: url) {
//                self.urlImageModel =  UrlImageModel(url: self.$url.wrappedValue.absoluteURL)
//            }
    }

    static var defaultImage = UIImage(named: "artwork.png")
}

class UrlImageModel: ObservableObject {
    @Published var image: UIImage?
    var url: URL?

    init(url: URL?) {
        self.url = url
        loadImage()
    }

    func loadImage() {
        loadImageFromUrl()
    }

    func loadImageFromUrl() {
        guard let url = url else { return }
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
