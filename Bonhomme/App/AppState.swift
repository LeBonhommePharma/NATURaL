import SwiftUI
import Observation

@Observable
final class AppState {
    var isWorkoutActive = false
    var isPremium = true
    var healthKitAuthorized = false

    /// Set when a killed-app workout state is detected on launch.
    var pendingRestoredWorkout: WorkoutFlowViewModel?

    let healthKitManager = HealthKitManager()
    let subscriptionManager = SubscriptionManager()
    let tvDisplayCoordinator = TVDisplayCoordinator()
    let careKitBridge = CareKitBridge()
    let phoneConnectivityBridge = PhoneConnectivityBridge()
    let workoutStateStore = WorkoutStateStore()

    /// Checks for a recoverable workout on app launch.
    func checkForResumableWorkout() {
        pendingRestoredWorkout = WorkoutFlowViewModel.restoreIfAvailable()
    }

    /// Clears the pending restored workout (user declined to resume).
    func dismissRestoredWorkout() {
        pendingRestoredWorkout = nil
        workoutStateStore.clear()
    }
}
