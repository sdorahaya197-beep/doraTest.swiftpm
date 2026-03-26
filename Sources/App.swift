import SwiftUI
import SwiftData

@main
struct DoraTestApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Race.self)
    }
}
