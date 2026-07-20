import SwiftUI
import SwiftData

@main
struct DHLWorkTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Shift.self,
            WorkSegment.self,
            HourlyRate.self,
            AppSettings.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
