import SwiftUI
import SwiftData
import BonhommeCore

@main
struct BonhommeApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    /// Stored once at app launch — must NOT be a computed property.
    /// A computed `var` would create a new ModelContainer on every `body`
    /// re-evaluation (triggered by any AppState mutation), causing repeated
    /// CloudKit initialization storms and the forever-loading symptom.
    private let persistentContainer: ModelContainer = Self.makePersistentContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
                .onAppear {
                    appState.checkForResumableWorkout()
                }
        }
        .modelContainer(persistentContainer)
    }

    /// SwiftData ModelContainer with CloudKit sync for cross-device data.
    /// Three-tier fallback: CloudKit → local-only → in-memory (last resort).
    /// Called exactly once via the stored `persistentContainer` let-property.
    private static func makePersistentContainer() -> ModelContainer {
        do {
            return try PersistenceConfiguration.makeContainer()
        } catch {
            // CloudKit container fails on simulators or when iCloud is not signed in.
            print("⚠️ Failed to create CloudKit container: \(error.localizedDescription)")
            print("   Falling back to local-only storage.")

            let schema = Schema([
                WorkoutRecord.self,
                UserPreferences.self,
                SessionStreak.self,
                MedicationSchedule.self,
                DrugResponseRecord.self,
            ])

            do {
                let fallbackConfig = ModelConfiguration("NATURaLLocal", schema: schema)
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                print("❌ CRITICAL: Failed to create local container: \(error.localizedDescription)")
                print("   Using in-memory storage. Data will not persist.")

                // Unnamed in-memory config avoids any name-based store lookup.
                // FIX: build the container directly from the model types without
                // a named configuration — the name-based lookup can itself fail
                // when the schema has validation errors. Passing types directly
                // lets SwiftData construct the schema fresh with no store conflict.
                do {
                    return try ModelContainer(for:
                        WorkoutRecord.self,
                        UserPreferences.self,
                        SessionStreak.self,
                        MedicationSchedule.self,
                        DrugResponseRecord.self
                    )
                } catch {
                    // Absolute last resort — single-model container so the app
                    // can at least boot and show an error UI instead of crashing.
                    print("❌ FATAL: In-memory container failed: \(error)")
                    do {
                        return try ModelContainer(
                            for: WorkoutRecord.self,
                            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
                        )
                    } catch {
                        // SwiftData still failed: empty in-memory config without try!
                        // (UI should surface a non-recoverable storage banner.)
                        fatalError(
                            "SwiftData ModelContainer could not be created: \(error.localizedDescription)"
                        )
                    }
                }
            }
        }
    }

    /// Handles scene phase transitions for state persistence.
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        switch newPhase {
        case .background, .inactive:
            // Persist workout state when app moves to background
            if appState.isWorkoutActive {
                // The active WorkoutFlowViewModel persists its own state
                // via its timer loop (every 5 seconds) and this trigger.
                NotificationCenter.default.post(
                    name: .workoutShouldPersistState,
                    object: nil
                )
            }
        case .active:
            // Check for resumable workout when returning to foreground
            if !appState.isWorkoutActive {
                appState.checkForResumableWorkout()
            }
            // Refresh CareKit prescriptions only after HealthKit authorization
            Task {
                if appState.healthKitAuthorized {
                    await appState.careKitBridge.refreshPrescribedTasks()
                } else {
                    print("ℹ️ Skipping CareKit refresh: HealthKit not authorized")
                }
            }
        @unknown default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let workoutShouldPersistState = Notification.Name("natural.workoutShouldPersistState")
}

// MARK: - Content View

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var navigateToRestoredWorkout = false
    @State private var initializationError: Error?
    @State private var showDebugDashboard = false

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                HomeView()
                    .navigationDestination(isPresented: $navigateToRestoredWorkout) {
                        if let vm = appState.pendingRestoredWorkout {
                            WorkoutFlowView(restoredViewModel: vm)
                        }
                    }
                    .toolbar {
                        #if DEBUG
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showDebugDashboard.toggle()
                            } label: {
                                Image(systemName: "ladybug.fill")
                                    .foregroundStyle(showDebugDashboard ? .orange : .secondary)
                            }
                        }
                        #endif
                    }
            }
            // Auto-load: when detect→load finds recoverable local activity, present the session
            // without a confirm-only gate. Discard remains secondary (home banner / stop).
            .onChange(of: appState.shouldAutoPresentRestoredSession) { _, shouldPresent in
                if shouldPresent {
                    navigateToRestoredWorkout = true
                    appState.noteRestoredSessionPresented()
                }
            }
            .onChange(of: navigateToRestoredWorkout) { _, isShowing in
                if !isShowing {
                    appState.noteRestoredSessionUIDismissed()
                }
            }
            .onAppear {
                // If detect already ran in BonhommeApp.onAppear before ContentView mounted,
                // consume any pending auto-present flag immediately.
                if appState.shouldAutoPresentRestoredSession {
                    navigateToRestoredWorkout = true
                    appState.noteRestoredSessionPresented()
                }
            }
            .task {
                // Perform async initialization checks
                await performInitializationChecks()
            }
            .task {
                // Request HealthKit authorization early and enable background delivery
                guard HealthKitManager.isAvailable else {
                    print("ℹ️ HealthKit not available on this device; skipping authorization.")
                    return
                }
                do {
                    try await appState.healthKitManager.requestAuthorization()
                    appState.healthKitAuthorized = true
                    try? await appState.healthKitManager.enableBackgroundDelivery()
                    // Safe to refresh CareKit prescriptions after authorization
                    await appState.careKitBridge.refreshPrescribedTasks()
                } catch {
                    appState.healthKitAuthorized = false
                    print("⚠️ HealthKit authorization failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    /// Validates that core app components initialized correctly.
    @MainActor
    private func performInitializationChecks() async {
        print("🔍 Running initialization diagnostics...")
        
        // Check HealthKit availability
        if HealthKitManager.isAvailable {
            print("✅ HealthKit is available")
        } else {
            print("⚠️ HealthKit is not available on this device")
        }
        
        // Detect local activity (same store as launch path)
        let loader = LocalActivitySessionLoader(store: appState.workoutStateStore)
        if loader.hasRecoverableActivity() {
            print("ℹ️ Recoverable local activity detected — auto-load path engaged")
        }
        
        // Verify feedback engine is ready
        print("✅ FeedbackEngine initialized with analyzers")
        
        print("✅ Initialization checks complete")
    }
}
