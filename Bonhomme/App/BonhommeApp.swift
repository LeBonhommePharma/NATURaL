import SwiftUI
import SwiftData
import TipKit
import BonhommeCore

@main
struct BonhommeApp: App {
    @State private var appState = AppState()
    @AppStorage("natural.didFinishWelcome") private var didFinishWelcome = false
    @State private var completedWelcomeThisLaunch = false
    @Environment(\.scenePhase) private var scenePhase

    /// Stored once at app launch — must NOT be a computed property.
    /// A computed `var` would create a new ModelContainer on every `body`
    /// re-evaluation (triggered by any AppState mutation).
    ///
    /// Bootstrap records local or ephemeral mode for user-visible UX
    /// (`AppState.persistenceSync`); failures are never silent.
    static let persistenceBootstrap = PersistenceConfiguration.bootstrap()
    private let persistentContainer: ModelContainer = BonhommeApp.persistenceBootstrap.container

    var body: some Scene {
        WindowGroup {
            // First use is a durable scene state, not a sheet owned by Home's
            // adaptive navigation hierarchy. Rotation and split-view rebuilding
            // must not dismiss it or count as completion.
            Group {
                if hasCompletedWelcome {
                    ContentView()
                } else {
                    WelcomeView {
                        // Explicit completion also takes effect immediately when
                        // preferences are overridden or cannot persist this launch.
                        completedWelcomeThisLaunch = true
                        didFinishWelcome = true
                    }
                }
            }
                .environment(appState)
                .onOpenURL { url in
                    guard (try? TVRelayPairing(url: url)) != nil else { return }
                    appState.pendingTVInvitation = url
                    appState.showsTVDisplay = true
                }
                .sheet(isPresented: Binding(
                    get: { hasCompletedWelcome && appState.showsTVDisplay },
                    set: { appState.showsTVDisplay = $0 }
                ), onDismiss: {
                    appState.pendingTVInvitation = nil
                }) {
                    TVConnectionSheet(invitationURL: appState.pendingTVInvitation)
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
                .onAppear {
                    appState.persistenceSync.apply(Self.persistenceBootstrap)
                    appState.checkForResumableWorkout()
                }
                .task {
                    do {
                        try Tips.configure([
                            .displayFrequency(.daily),
                            .datastoreLocation(.applicationDefault)
                        ])
                    } catch {
                        // TipKit is optional chrome — sessions still run if configure fails.
                    }
                }
        }
        .modelContainer(persistentContainer)
    }

    private var hasCompletedWelcome: Bool {
        didFinishWelcome || completedWelcomeThisLaunch
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
            // CareKit uses a local OCKStore — independent of HealthKit authorization
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
    @State private var navigateToRestoredWorkout = false
    @State private var intentPlan: WorkoutPlan?
    @State private var navigateToIntentPlan = false
    @State private var initializationError: Error?
    @State private var showDebugDashboard = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .bottom) {
            NavigationStack {
                HomeView()
                    .navigationDestination(isPresented: $navigateToRestoredWorkout) {
                        if let vm = appState.pendingRestoredWorkout {
                            WorkoutFlowView(restoredViewModel: vm)
                        }
                    }
                    .navigationDestination(isPresented: $navigateToIntentPlan) {
                        if let plan = intentPlan {
                            WorkoutFlowView(plan: plan, feedbackEngine: appState.feedbackEngine)
                        }
                    }
                    .toolbar {
                        #if DEBUG
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                                showDebugDashboard.toggle()
                            } label: {
                                Image(systemName: "ladybug.fill")
                                    .foregroundStyle(showDebugDashboard ? BrandColor.strawberry : .secondary)
                                    .frame(minWidth: 44, minHeight: 44)
                            }
                            .accessibilityLabel("Debug dashboard")
                            .accessibilityValue(showDebugDashboard ? "Visible" : "Hidden")
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
            .onChange(of: navigateToIntentPlan) { _, isShowing in
                if !isShowing {
                    intentPlan = nil
                    appState.noteWorkoutDismissed()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .intentStartWorkoutPlan)) { note in
                let planId = note.userInfo?["planId"] as? String
                    ?? IntentBridge.shared.consumePendingPlanId()
                presentIntentPlan(id: planId)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active, !appState.isWorkoutActive,
                   let pendingId = IntentBridge.shared.consumePendingPlanId() {
                    presentIntentPlan(id: pendingId)
                }
            }
            .onAppear {
                // Surface durable or temporary storage status from launch bootstrap.
                appState.persistenceSync.apply(BonhommeApp.persistenceBootstrap)
                // If detect already ran in BonhommeApp.onAppear before ContentView mounted,
                // consume any pending auto-present flag immediately.
                if appState.shouldAutoPresentRestoredSession {
                    navigateToRestoredWorkout = true
                    appState.noteRestoredSessionPresented()
                }
                // Honor App Intent plan start queued while the app was launching.
                if let pendingId = IntentBridge.shared.consumePendingPlanId() {
                    presentIntentPlan(id: pendingId)
                }
            }
            .task {
                // Perform async initialization checks
                await performInitializationChecks()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                StorageStatusBanner(status: appState.persistenceSync)
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

    /// Opens a workout flow from an App Intent plan id.
    @MainActor
    private func presentIntentPlan(id: String?) {
        guard let id,
              let plan = PoseCatalog.allPlans.first(where: { $0.id == id }) else {
            return
        }
        // Avoid stacking a second session while one is already presenting.
        guard !appState.isWorkoutActive else { return }
        _ = IntentBridge.shared.consumePendingPlanId()
        intentPlan = plan
        navigateToIntentPlan = true
        appState.noteWorkoutPresented()
    }
}

// MARK: - Storage Status Banner

/// Top-of-app banner when on-device storage is temporary or unusable.
/// Includes optional Retry; copy never claims silent data loss.
struct StorageStatusBanner: View {
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
                            .frame(width: SessionSpacing.minTapTarget, height: SessionSpacing.minTapTarget)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(LocalizedString(en: "Dismiss", fr: "Fermer").localized)
                }

                if let feedback = status.retryFeedback {
                    Text(feedback)
                        .font(.system(size: 12))
                        .foregroundStyle(status.restartRecommended ? BrandColor.mint.opacity(0.9) : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 12) {
                    Button {
                        Task { await status.retryLocalStorage() }
                    } label: {
                        if status.isRetrying {
                            ProgressView()
                                .controlSize(.small)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text(LocalizedString(en: "Retry storage", fr: "Réessayer le stockage").localized)
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

/// First-use introduction; browsing and guided sessions do not require Health permission.
private struct WelcomeView: View {
    let continueToApp: () -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image("Bloom")
                        .resizable().scaledToFit()
                        .frame(maxWidth: .infinity).frame(height: 210)
                        .accessibilityHidden(true)
                    Text(LocalizedString(en: "Make room for yourself.", fr: "Faites-vous une place.").localized)
                        .font(.largeTitle.bold())
                    Text(LocalizedString(en: "Gentle chair yoga, one breath at a time. Every session is available from the start, and you can begin without an account or an Apple Watch.", fr: "Du yoga sur chaise, un souffle à la fois. Chaque séance est disponible dès le début. Commencez sans compte ni Apple Watch.").localized)
                        .font(.title3)
                    Label(LocalizedString(en: "Choose a stable chair and enough space to move.", fr: "Choisissez une chaise stable et assez d’espace pour bouger.").localized, systemImage: "chair.fill")
                    Label(LocalizedString(en: "Adapt each movement to your comfort. Pause whenever you need.", fr: "Adaptez chaque mouvement à votre confort. Faites une pause au besoin.").localized, systemImage: "pause.circle")
                    Text(LocalizedString(en: "Your records stay on this device. Analysis runs locally. NATURaL does not collect or receive your data.", fr: "Vos dossiers restent sur cet appareil. L’analyse s’exécute localement. NATURaL ne collecte pas et ne reçoit pas vos données.").localized)
                        .font(.footnote).foregroundStyle(BrandColor.fgMuted)
                    Text(LocalizedString(en: "Biofeedback is optional. NATURaL is a wellness app; its entropy indicators do not diagnose conditions or measure drug binding.", fr: "La rétroaction physiologique est facultative. NATURaL est une app de bien-être; ses indicateurs d’entropie ne diagnostiquent pas de maladies et ne mesurent pas la liaison des médicaments.").localized)
                        .font(.footnote).foregroundStyle(BrandColor.fgMuted)
                    NavigationLink { AppInformationView() } label: {
                        Label(LocalizedString(en: "Your data & privacy", fr: "Vos données et votre confidentialité").localized, systemImage: "hand.raised")
                    }
                    .tint(SessionPalette.accent)
                    Button(action: continueToApp) {
                        Text(LocalizedString(en: "Find my first session", fr: "Trouver ma première séance").localized)
                            .font(.headline)
                            .foregroundStyle(SessionPalette.onAccent)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, minHeight: SessionSpacing.phoneControlHeight)
                    }
                    .sessionProminentButtonStyle()
                    .tint(SessionPalette.accent)
                    .accessibilityIdentifier("welcome.continue")
                }
                .padding(28).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }
            .foregroundStyle(BrandColor.fg)
            .background(BrandColor.bg)
        }
        // This introduction uses the fixed midnight palette, including its artwork
        // and navigation chrome, regardless of the surrounding home appearance.
        .preferredColorScheme(.dark)
    }
}

/// Always available from home; permissions are requested only after an explicit action.
struct AppInformationView: View {
    @Environment(AppState.self) private var appState
    @State private var requestingHealth = false
    @State private var healthMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    Image("Bloom").resizable().scaledToFit().frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 16)).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NATURaL").font(.title2.bold())
                        Text(LocalizedString(en: "Chair yoga. Freely yours.", fr: "Le yoga sur chaise, en toute liberté.").localized)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Section(LocalizedString(en: "Apple Health", fr: "Apple Santé").localized) {
                Text(LocalizedString(en: "Connect Health to read heart rate and activity and save completed workouts. Health chooses what to share; a completed permission request does not mean every data type was allowed. You can use guided sessions without connecting.", fr: "Connectez Santé pour lire la fréquence cardiaque et l’activité et enregistrer vos séances. Vous choisissez les données à partager. Une demande terminée ne signifie pas que tous les accès sont autorisés. Les séances guidées restent accessibles sans connexion.").localized)
                Button {
                    Task { await connectHealth() }
                } label: {
                    HStack {
                        Label(LocalizedString(en: "Choose Health permissions", fr: "Choisir les autorisations Santé").localized, systemImage: "heart.text.square")
                        if requestingHealth { ProgressView() }
                    }
                }
                .disabled(requestingHealth || !HealthKitManager.isAvailable)
                if let healthMessage { Text(healthMessage).font(.footnote).foregroundStyle(.secondary) }
                Text(LocalizedString(en: "Change access at any time in Health → your profile → Apps → NATURaL. Medication records require separate consent in Prescriptions.", fr: "Modifiez l’accès dans Santé → votre profil → Apps → NATURaL. Les dossiers de médicaments demandent un consentement distinct dans Ordonnances.").localized)
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section(LocalizedString(en: "Privacy & storage", fr: "Confidentialité et stockage").localized) {
                Text(LocalizedString(en: "We do not collect, receive or keep your personal or health data. There is no NATURaL account, no analytics, and no iCloud sync. Session history, preferences and medication entries stay on this device so analysis can run locally.", fr: "Nous ne collectons, ne recevons ni ne conservons vos données personnelles ou de santé. Il n’y a ni compte NATURaL, ni analyse d’audience, ni sync iCloud. L’historique, les préférences et les médicaments saisis restent sur cet appareil pour que l’analyse s’exécute localement.").localized)
                Text(LocalizedString(en: "HealthKit manages records you authorize in Apple Health; we never receive those samples. Completed workouts can be relayed between your paired iPhone and Watch. Sharing a workout card or joining SharePlay is your choice.", fr: "HealthKit gère les données autorisées dans Apple Santé; nous ne recevons jamais ces échantillons. Les séances peuvent être relayées entre votre iPhone et votre Watch jumelés. Le partage d’une carte ou une séance SharePlay reste votre choix.").localized)
                Text(LocalizedString(en: "Optional Apple Music playback contacts Apple. Its services process playback requests under Apple’s privacy policy.", fr: "La lecture facultative Apple Music contacte Apple, qui traite les requêtes selon sa politique de confidentialité.").localized)
                Link(LocalizedString(en: "Privacy policy", fr: "Politique de confidentialité").localized, destination: URL(string: "https://thebonhomme.com/NATURaL/privacy/")!)
                Link("Apple Privacy", destination: URL(string: "https://www.apple.com/legal/privacy/")!)
                Text(LocalizedString(en: "Delete records saved to Apple Health in the Health app. Removing NATURaL removes its local app data; exported cards and records in Health remain under your control.", fr: "Supprimez les données Apple Santé dans l’app Santé. Supprimer NATURaL retire ses données locales; les cartes exportées et les données Santé restent sous votre contrôle.").localized)
            }
            Section(LocalizedString(en: "Understanding biofeedback", fr: "Comprendre la rétroaction").localized) {
                Text(LocalizedString(en: "Shannon entropy describes variation in a sampled signal. Signal quality, movement, breathing and sampling affect it. A change is not proof of relaxation, treatment response, or molecular binding. These experimental indicators support exploration, not clinical decisions.", fr: "L’entropie de Shannon décrit la variation d’un signal échantillonné. La qualité du signal, le mouvement, la respiration et l’échantillonnage l’influencent. Un changement ne prouve pas une relaxation, une réponse au traitement ou une liaison moléculaire. Ces indicateurs expérimentaux servent à l’exploration, pas aux décisions cliniques.").localized)
            }
            Section(LocalizedString(en: "Acknowledgements", fr: "Remerciements").localized) {
                NavigationLink(LocalizedString(en: "Open-source licenses", fr: "Licences open source").localized) {
                    ScrollView {
                        Text(acknowledgements)
                            .font(.footnote)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                    .navigationTitle(LocalizedString(en: "Licenses", fr: "Licences").localized)
                }
            }
            Section(LocalizedString(en: "Contact", fr: "Contact").localized) {
                Link(LocalizedString(en: "Support & help", fr: "Aide et assistance").localized, destination: URL(string: "https://thebonhomme.com/NATURaL/support/")!)
                Link("lp@thebonhomme.com", destination: URL(string: "mailto:lp@thebonhomme.com")!)
                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(LocalizedString(en: "About & Privacy", fr: "À propos et confidentialité").localized)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var acknowledgements: String {
        guard let url = Bundle.main.url(forResource: "Acknowledgements", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return LocalizedString(en: "Licenses are unavailable. Please contact support.", fr: "Les licences sont indisponibles. Contactez l’assistance.").localized
        }
        return text
    }

    @MainActor private func connectHealth() async {
        requestingHealth = true
        defer { requestingHealth = false }
        do {
            try await appState.healthKitManager.requestAuthorization()
            appState.healthKitAuthorized = true
            try? await appState.healthKitManager.enableBackgroundDelivery()
            healthMessage = LocalizedString(en: "Permission choices saved. Available metrics depend on the access and samples you share.", fr: "Choix enregistrés. Les mesures disponibles dépendent des accès et des échantillons partagés.").localized
        } catch {
            healthMessage = LocalizedString(en: "Health could not connect. You can try again or continue with guided movement.", fr: "Connexion à Santé impossible. Réessayez ou continuez les mouvements guidés.").localized
        }
    }
}
