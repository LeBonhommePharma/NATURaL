import SwiftUI

@main
struct BonhommeApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            HomeView()
        }
    }
}
