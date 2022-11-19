//
//  podcast_swiftuiApp.swift
//  podcast-swiftui
//
//  Created by Ryohei Fushimi on 2022/02/26.
//

import MusicKit
import SwiftUI

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        NSLog("\(#function)")
        ConfigModel.shared = ConfigModel(nowPlayableBehavior: IOSNowPlayableBehavior())
        return true
    }
}

@main
struct podcast_swiftuiApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject var audioPlayer = AudioPlayer.shared
    @StateObject private var store = PodcastRepositoryStore()
 
    var body: some Scene {
        WindowGroup {
            MainView(repository: store.repository) {
                PodcastRepositoryStore.save(repository: store.repository) { result in
                    print("Saved \(result) feeds")
                }
            }
                .environmentObject(audioPlayer)
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    PodcastRepositoryStore.load { result in
                        switch result {
                        case .failure(let error):
                            fatalError(error.localizedDescription)
                        case .success(let repository):
                            print("Loaded \(repository.feeds.count) feeds")
                            store.repository = repository
                        }
                    }
                }
        }.onChange(of: scenePhase) { phase in
//            persistenceController.save()
            if phase == .background {
                print("changed to background!")

            } else if phase == .active {
                print("changed to active!")
            }
        }
    }
}
