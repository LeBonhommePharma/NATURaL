import SwiftUI
import BonhommeCore

/// watchOS companion app entry point for NATURaL Chair Yoga.
/// Provides independent workout execution with direct wrist sensor access
/// and WatchConnectivity relay to the iOS hub.
@main
struct BonhommeWatchApp: App {
    @State private var workoutManager = WatchWorkoutManager()
    @State private var connectivityBridge = WatchConnectivityBridge()

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environment(workoutManager)
                .environment(connectivityBridge)
        }
    }
}
