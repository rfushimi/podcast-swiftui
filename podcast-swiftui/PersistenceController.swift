//import Foundation
//import CoreData
//
//struct PersistenceController {
//    // A singleton for our entire app to use
//    static let shared = PersistenceController()
//
//    // Storage for Core Data
//    let container: NSPersistentContainer
//
//    // A test configuration for SwiftUI previews
//    static var preview: PersistenceController = {
//        let controller = PersistenceController(inMemory: true)
//
//        // Create 10 example programming languages.
//        for _ in 0..<10 {
////            let language = ProgrammingLanguage(context: controller.container.viewContext)
////            language.name = "Example Language 1"
////            language.creator = "A. Programmer"
//            let episode = PodcastEpisode.init(context: controller.container.viewContext)
//            episode.summary = "エピソードの概要"
//            episode.episodeURL = URL(string: "https://developer.apple.com/tutorials/app-dev-training/persisting-data")
//            episode.duration = 1234
//            episode.guid = UUID.init(uuidString: "65c9af37-2c6b-44f6-94d0-067dcc2baf5b")
//
//            let feed = PodcastFeed.init(context: controller.container.viewContext)
//            feed.title = "研エンの仲"
//            feed.feedURL = URL(string: "https://anchor.fm/s/2631f634/podcast/rss")
//            feed.artworkURL = URL(fileURLWithPath: Bundle.main.path(forResource: "artwork", ofType: "png")!)
//            feed.episodes = episode
//            
//        }
//
//        return controller
//    }()
//
//    // An initializer to load Core Data, optionally able
//    // to use an in-memory store.
//    init(inMemory: Bool = false) {
//        // If you didn't name your model Main you'll need
//        // to change this name below.
//        container = NSPersistentContainer(name: "Main")
//
//        if inMemory {
//            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
//        }
//
//        container.loadPersistentStores { description, error in
//            if let error = error {
//                fatalError("Error: \(error.localizedDescription)")
//            }
//        }
//    }
//    func save() {
//        let context = container.viewContext
//
//        if context.hasChanges {
//            do {
//                try context.save()
//            } catch {
//                // Show some error here
//            }
//        }
//    }}
