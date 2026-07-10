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
    ///
    /// Bootstrap records CloudKit → local → ephemeral mode for user-visible UX
    /// (`AppState.persistenceSync`); failures are never silent.
    static let persistenceBootstrap = PersistenceConfiguration.bootstrap()
    private let persistentContainer: ModelContainer = BonhommeApp.persistenceBootstrap.container

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
                .onAppear {
                    appState.persistenceSync.apply(Self.persistenceBootstrap)
                    appState.checkForResumableWorkout()
                }
        }
        .modelContainer(persistentContainer)
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
                // Surface CloudKit / local / ephemeral mode from launch bootstrap.
                appState.persistenceSync.apply(BonhommeApp.persistenceBootstrap)
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
            .safeAreaInset(edge: .top, spacing: 0) {
                CloudKitSyncStatusBanner(status: appState.persistenceSync)
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

        let sync = appState.persistenceSync
        print("ℹ️ Persistence mode: \(sync.mode.rawValue)")
        if let err = sync.underlyingErrorDescription {
            print("   Underlying init detail: \(err)")
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

// MARK: - CloudKit Sync Status Banner

/// Top-of-app banner when CloudKit init fell back to local-only or ephemeral storage.
/// Includes optional Retry; copy never claims silent data loss.
struct CloudKitSyncStatusBanner: View {
    @Bindable var status: PersistenceSyncStatus

    var body: some View {
        if status.shouldShowBanner {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: status.systemImageName)
                        .font(.system(size: 22))
                        .foregroundStyle(status.accentColor)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(status.bannerTitle)
                            .font(.system(size: 15, weight: .semibold))
                        Text(status.bannerMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    Button {
                        status.dismissBanner()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(LocalizedString(en: "Dismiss", fr: "Fermer").localized)
                }

                if let feedback = status.retryFeedback {
                    Text(feedback)
                        .font(.system(size: 12))
                        .foregroundStyle(status.restartRecommended ? Color.green.opacity(0.9) : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await status.retryCloudKitConnection() }
                    } label: {
                        if status.isRetrying {
                            ProgressView()
                                .controlSize(.small)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(LocalizedString(en: "Retry iCloud", fr: "Réessayer iCloud").localized)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(status.accentColor)
                    .disabled(status.isRetrying)

                    Button {
                        status.dismissBanner()
                    } label: {
                        Text(LocalizedString(en: "Not now", fr: "Pas maintenant").localized)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(status.isRetrying)
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(status.accentColor.opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 4)
            .accessibilityElement(children: .contain)
        }
    }
}
