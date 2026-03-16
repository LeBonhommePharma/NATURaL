import SwiftUI
import Observation
import BonhommeCore

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

    /// App-wide multi-signal analysis engine shared across workout sessions.
    let feedbackEngine = FeedbackEngine()

    /// Medication tracking and drug response analysis service.
    let medicationTracker: MedicationTracker

    init() {
        // Register all signal analyzers at app level so data persists across sessions
        feedbackEngine.register(HRVAnalyzer())
        feedbackEngine.register(MedicationAnalyzer())
        feedbackEngine.register(DockingInsightAnalyzer())

        medicationTracker = MedicationTracker(feedbackEngine: feedbackEngine)
    }

    /// Checks for a recoverable workout on app launch.
    func checkForResumableWorkout() {
        pendingRestoredWorkout = WorkoutFlowViewModel.restoreIfAvailable(feedbackEngine: feedbackEngine)
    }

    /// Clears the pending restored workout (user declined to resume).
    func dismissRestoredWorkout() {
        pendingRestoredWorkout = nil
        workoutStateStore.clear()
    }
}
