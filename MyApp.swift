import SwiftUI
import SwiftData
import TipKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [Article.self, Message.self])
        }
    }

    init() {
        try? Tips.resetDatastore()
        try? Tips.configure()
    }
}
