import SwiftUI
import Observation
import BonhommeCore

@Observable
@MainActor
final class AppState {
    /// True while any workout UI (new or restored) is on-screen.
    /// Guards scenePhase.active re-detect so mid-session 5s persist does not spawn a second auto-load.
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
    /// Shared with ExternalDisplaySceneDelegate so AirPlay UI sees the same payloads.
    let tvDisplayCoordinator = TVDisplayCoordinator.shared
    let careKitBridge = CareKitBridge()
    let phoneConnectivityBridge = PhoneConnectivityBridge()
    let workoutStateStore = WorkoutStateStore()

    /// App-wide multi-signal analysis engine shared across workout sessions.
    let feedbackEngine = FeedbackEngine()

    /// Medication tracking and drug response analysis service.
    let medicationTracker: MedicationTracker

    /// Consent-gated prescription import (HealthKit clinical + manual + CareKit).
    let prescriptionService: MedicationPrescriptionService

    /// CloudKit / local / ephemeral storage mode for user-visible sync UX.
    let persistenceSync = PersistenceSyncStatus()

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

        prescriptionService = MedicationPrescriptionService(
            healthKitManager: healthKitManager,
            medicationTracker: medicationTracker,
            careKitBridge: careKitBridge
        )

        // Wire App Intents → live FeedbackEngine / MedicationTracker
        IntentBridge.shared.bind(
            feedbackEngine: feedbackEngine,
            medicationTracker: medicationTracker
        )

        // ClusterFleet: iCloud peer heartbeats (iPhone/iPad/Mac) + Watch auto-upsert hooks.
        // Watch membership is also driven by PhoneConnectivityBridge reachability.
        ClusterFleetPresenceCoordinator.shared.start()
    }

    /// Detects recoverable local activity and auto-loads it into a runnable restored session.
    /// Called on launch and when returning to active. Does not require a manual confirm step to load.
    /// Re-entrancy: when `isWorkoutActive` (any live workout UI), policy skips so become-active
    /// does not rebuild a second VM from the mid-session persist store.
    func detectAndAutoLoadLocalActivity() {
        let loader = LocalActivitySessionLoader(store: workoutStateStore)
        let decision = LocalActivityAutoLoadPolicy.decide(
            isWorkoutAlreadyPresenting: isWorkoutActive,
            loader: loader
        )

        switch decision {
        case .skipAlreadyPresenting:
            // Leave pending/presenting state alone — live session owns the UI.
            return
        case .skipNoRecoverableActivity:
            pendingRestoredWorkout = nil
            shouldAutoPresentRestoredSession = false
        case .autoLoad(let session):
            pendingRestoredWorkout = WorkoutFlowViewModel(
                restoredSession: session,
                feedbackEngine: feedbackEngine
            )
            shouldAutoPresentRestoredSession = true
        }
    }

    /// Checks for a recoverable workout on app launch / become-active and auto-loads it.
    /// Kept as the historical entry name used by BonhommeApp scene wiring.
    func checkForResumableWorkout() {
        detectAndAutoLoadLocalActivity()
    }

    /// Marks that any workout UI (new plan or restored) is presenting.
    /// Must be called from `WorkoutFlowView` onAppear for *all* entry paths.
    func noteWorkoutPresented() {
        isWorkoutActive = true
    }

    /// Marks that the workout UI left the screen (dismiss / complete / pop).
    func noteWorkoutDismissed() {
        isWorkoutActive = false
    }

    /// Marks that the restored session has been auto-presented (navigation triggered).
    func noteRestoredSessionPresented() {
        shouldAutoPresentRestoredSession = false
        noteWorkoutPresented()
    }

    /// Clears the pending restored workout (user discarded / declined).
    func dismissRestoredWorkout() {
        pendingRestoredWorkout = nil
        shouldAutoPresentRestoredSession = false
        noteWorkoutDismissed()
        workoutStateStore.clear()
    }

    /// Called when the restored-session navigation path is dismissed without discarding persistence.
    func noteRestoredSessionUIDismissed() {
        noteWorkoutDismissed()
    }
}
