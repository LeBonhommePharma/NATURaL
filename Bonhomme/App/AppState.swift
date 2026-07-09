import SwiftUI
import Observation
import BonhommeCore

@Observable
@MainActor
final class AppState {
    var isWorkoutActive = false
    var isPremium = true
    var healthKitAuthorized = false

    /// Set when a killed-app workout state is detected and auto-loaded on launch/active.
    var pendingRestoredWorkout: WorkoutFlowViewModel?

    /// When true, the UI should auto-present the restored session (not wait on confirm-only gate).
    /// Consumed by ContentView after navigation is triggered.
    var shouldAutoPresentRestoredSession = false

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
        do {
            feedbackEngine.register(HRVAnalyzer())
            feedbackEngine.register(MedicationAnalyzer())
            feedbackEngine.register(DockingInsightAnalyzer())
            
            medicationTracker = MedicationTracker(feedbackEngine: feedbackEngine)
            
            print("✅ AppState initialized successfully")
        } catch {
            // If any analyzer registration fails, we still need to initialize medicationTracker
            // with whatever analyzers were successfully registered
            medicationTracker = MedicationTracker(feedbackEngine: feedbackEngine)
            print("⚠️ AppState initialization completed with warnings: \(error.localizedDescription)")
        }
    }

    /// Detects recoverable local activity and auto-loads it into a runnable restored session.
    /// Called on launch and when returning to active. Does not require a manual confirm step to load.
    func detectAndAutoLoadLocalActivity() {
        // Skip while a workout UI is already presenting to avoid re-entrant navigation.
        if isWorkoutActive { return }

        let loader = LocalActivitySessionLoader(store: workoutStateStore)
        guard loader.hasRecoverableActivity(),
              let vm = WorkoutFlowViewModel.restoreIfAvailable(
                feedbackEngine: feedbackEngine,
                store: workoutStateStore
              ) else {
            pendingRestoredWorkout = nil
            shouldAutoPresentRestoredSession = false
            return
        }

        pendingRestoredWorkout = vm
        shouldAutoPresentRestoredSession = true
    }

    /// Checks for a recoverable workout on app launch / become-active and auto-loads it.
    /// Kept as the historical entry name used by BonhommeApp scene wiring.
    func checkForResumableWorkout() {
        detectAndAutoLoadLocalActivity()
    }

    /// Marks that the restored session has been auto-presented (navigation triggered).
    func noteRestoredSessionPresented() {
        shouldAutoPresentRestoredSession = false
        isWorkoutActive = true
    }

    /// Clears the pending restored workout (user discarded / declined).
    func dismissRestoredWorkout() {
        pendingRestoredWorkout = nil
        shouldAutoPresentRestoredSession = false
        isWorkoutActive = false
        workoutStateStore.clear()
    }

    /// Called when the restored-session UI is dismissed without discarding persistence.
    func noteRestoredSessionUIDismissed() {
        isWorkoutActive = false
    }
}
