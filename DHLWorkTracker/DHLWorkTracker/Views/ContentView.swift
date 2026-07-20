import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Vandaag", systemImage: "timer") }
            HistoryView()
                .tabItem { Label("Geschiedenis", systemImage: "clock.arrow.circlepath") }
            OverviewView()
                .tabItem { Label("Overzicht", systemImage: "chart.bar") }
            SettingsView()
                .tabItem { Label("Instellingen", systemImage: "gearshape") }
        }
        .tint(.orange)
        .task {
            SeedData.ensureDefaults(context: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Shift.self, WorkSegment.self, HourlyRate.self, AppSettings.self], inMemory: true)
}
