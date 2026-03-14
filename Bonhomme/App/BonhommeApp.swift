import SwiftUI
import SwiftData

@main
struct BonhommeApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

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
    private var persistentContainer: ModelContainer {
        do {
            return try PersistenceConfiguration.makeContainer()
        } catch {
            // If CloudKit container fails, fall back to local-only storage.
            // This can happen on simulators or when iCloud is not signed in.
            let schema = Schema([
                WorkoutRecord.self,
                UserPreferences.self,
                SessionStreak.self,
                MedicationSchedule.self,
            ])
            let fallbackConfig = ModelConfiguration(
                "NATURaLLocal",
                schema: schema
            )
            return try! ModelContainer(for: schema, configurations: [fallbackConfig])
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
            // Refresh CareKit prescriptions
            Task {
                await appState.careKitBridge.refreshPrescribedTasks()
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
    @State private var showResumeAlert = false
    @State private var navigateToRestoredWorkout = false

    var body: some View {
        NavigationStack {
            HomeView()
                .navigationDestination(isPresented: $navigateToRestoredWorkout) {
                    if let vm = appState.pendingRestoredWorkout {
                        WorkoutFlowView(restoredViewModel: vm)
                    }
                }
        }
        .onChange(of: appState.pendingRestoredWorkout != nil) { _, hasWorkout in
            showResumeAlert = hasWorkout
        }
        .alert(
            LocalizedString(
                en: "Resume Workout?",
                fr: "Reprendre l'entraînement ?"
            ).localized,
            isPresented: $showResumeAlert
        ) {
            Button(LocalizedString(en: "Resume", fr: "Reprendre").localized) {
                navigateToRestoredWorkout = true
            }
            Button(LocalizedString(en: "Discard", fr: "Annuler").localized, role: .destructive) {
                appState.dismissRestoredWorkout()
            }
        } message: {
            if let vm = appState.pendingRestoredWorkout {
                Text(LocalizedString(
                    en: "You have an unfinished \(vm.plan.name.en) session. Would you like to continue?",
                    fr: "Vous avez une séance \(vm.plan.name.fr) inachevée. Voulez-vous continuer ?"
                ).localized)
            }
        }
    }
}
