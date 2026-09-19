import SwiftUI
import TipKit
import BonhommeCore

/// Create services only when a destination appears. Eager NavigationLink construction
/// must not mutate the shared feedback engine during a parent SwiftUI body update.
struct WorkoutFlowView: View {
    private let plan: WorkoutPlan?
    private let feedbackEngine: FeedbackEngine?
    private let restoredViewModel: WorkoutFlowViewModel?
    @State private var viewModel: WorkoutFlowViewModel?

    init(plan: WorkoutPlan, feedbackEngine: FeedbackEngine = FeedbackEngine()) {
        self.plan = plan
        self.feedbackEngine = feedbackEngine
        restoredViewModel = nil
    }

    init(restoredViewModel: WorkoutFlowViewModel) {
        plan = nil
        feedbackEngine = nil
        self.restoredViewModel = restoredViewModel
    }

    var body: some View {
        Group {
            if let viewModel { WorkoutSessionView(viewModel: viewModel) }
            else { ProgressView() }
        }
        .task {
            guard viewModel == nil else { return }
            if let restoredViewModel { viewModel = restoredViewModel }
            else if let plan, let feedbackEngine {
                viewModel = WorkoutFlowViewModel(plan: plan, feedbackEngine: feedbackEngine)
            }
        }
    }
}

/// The main guided workout screen that drives the pose-by-pose flow.
/// On iPad (regular width), displays a 60/40 split with pose visual and metrics panel.
private struct WorkoutSessionView: View {
    @State private var viewModel: WorkoutFlowViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Shared app state — used to mark any live workout as presenting so scene-active
    /// auto-load cannot re-enter and spawn a second session from 5s persist state.
    @Environment(AppState.self) private var appState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sciExplainText: String?
    @ObservedObject private var tvDisplay = TVDisplayCoordinator.shared
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: WorkoutFlowViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        notificationContent
        .alert(
            SessionHUDCopy.explainSCI.localized,
            isPresented: Binding(
                get: { sciExplainText != nil },
                set: { if !$0 { sciExplainText = nil } }
            )
        ) {
            Button(LocalizedString(en: "OK", fr: "OK").localized, role: .cancel) {
                sciExplainText = nil
            }
        } message: {
            Text(sciExplainText ?? "")
        }
    }

    // Separate opaque view boundaries keep the phase canvas and lifecycle
    // modifiers tractable for the SwiftUI type checker on every build mode.
    private var notificationContent: some View {
        televisionContent
        .onReceive(NotificationCenter.default.publisher(for: .workoutShouldPersistState)) { _ in
            viewModel.persistState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .intentPauseWorkout)) { _ in
            viewModel.pause()
        }
        .onReceive(NotificationCenter.default.publisher(for: .intentResumeWorkout)) { _ in
            viewModel.resume()
        }
        .onReceive(NotificationCenter.default.publisher(for: .intentEndWorkout)) { _ in
            viewModel.stop()
        }
        .onReceive(NotificationCenter.default.publisher(for: .intentLogPose)) { _ in
            viewModel.logCurrentPoseFromIntent()
        }
        .onReceive(NotificationCenter.default.publisher(for: .intentExplainSCI)) { _ in
            Task { await presentSCIExplanation() }
        }
    }

    private var televisionContent: some View {
        lifecycleContent
        .task {
            while !Task.isCancelled {
                publishTVState()
                do { try await Task.sleep(for: .seconds(1)) } catch { return }
            }
        }
        .onChange(of: viewModel.phase) { _, _ in publishTVState() }
        .onChange(of: viewModel.isPaused) { _, _ in publishTVState() }
        .onChange(of: tvDisplay.displayEnabled) { _, _ in publishTVState() }
        .onChange(of: scenePhase) { _, _ in publishTVState() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { appState.showsTVDisplay = true } label: {
                    Label(LocalizedString(en: "TV display", fr: "Affichage TV").localized,
                          systemImage: tvDisplay.displayEnabled ? "tv.fill" : "tv")
                }.accessibilityIdentifier("session.tvDisplay")
            }
        }
        .onDisappear {
            tvDisplay.stopTVDiscovery()
            if viewModel.phase != .ready && viewModel.phase != .complete { viewModel.stop() }
            appState.noteWorkoutDismissed()
        }
    }

    private var lifecycleContent: some View {
        sessionLayout
        .preferredColorScheme(.dark)
        .navigationBarBackButtonHidden()
        .statusBarHidden()
        .onAppear {
            // All entry paths (catalog start, banner, auto-restore navigation) mark active
            // so BonhommeApp scenePhase.active does not re-run detect→auto-load mid-session.
            appState.noteWorkoutPresented()
            // Wire drug-response / cross-domain context into InsightEngine (pose/session narratives).
            // Non-blocking — does not start or delay the pose timer.
            viewModel.syncPharmaContext(
                drugResponse: appState.medicationTracker.latestDrugResponse,
                crossDomain: appState.medicationTracker.latestCrossDomainValidation
            )
            if viewModel.isRestoredSession {
                viewModel.resumeRestoredSession()
            }
        }
        .onChange(of: appState.medicationTracker.latestDrugResponse?.doseEvent.timestamp) { _, _ in
            viewModel.syncPharmaContext(
                drugResponse: appState.medicationTracker.latestDrugResponse,
                crossDomain: appState.medicationTracker.latestCrossDomainValidation
            )
        }
    }

    /// Reserve actual layout space for the controls. An inset on the enclosing
    /// ZStack allowed its GeometryReader/ScrollView to paint below the HUD.
    private var sessionLayout: some View {
        VStack(spacing: 0) {
            sessionCanvas
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
            phoneSessionChrome
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
        }
        .background(BrandColor.bg.ignoresSafeArea())
    }

    private var sessionCanvas: some View {
        ZStack {
            BrandColor.bg.ignoresSafeArea()

            switch viewModel.phase {
            case .ready:
                if usesRegularSessionLayout {
                    scrollableSessionContent { iPadReadyView }
                } else {
                    scrollableSessionContent { readyView }
                }
            case .countdown(let seconds):
                CountdownView(secondsRemaining: seconds)
            case .active(let poseIndex):
                if usesRegularSessionLayout {
                    scrollableSessionContent { iPadActivePoseView(poseIndex: poseIndex) }
                } else {
                    scrollableSessionContent { activePoseView(poseIndex: poseIndex) }
                }
            case .transition(let nextIndex, let seconds):
                if usesRegularSessionLayout {
                    scrollableSessionContent { iPadTransitionView(nextIndex: nextIndex, seconds: seconds) }
                } else {
                    scrollableSessionContent { transitionView(nextIndex: nextIndex, seconds: seconds) }
                }
            case .cooldown:
                cooldownView
            case .complete:
                let hrv = viewModel.feedbackEngine.latestInsight(for: .heartRateVariability)
                SummaryView(
                    result: viewModel.buildResult(),
                    sciScore: hrv?.score,
                    sciTrend: hrv?.trend.asSCITrend ?? .stable,
                    insightEngine: viewModel.insightEngine,
                    healthSaveFailed: viewModel.healthSaveFailed,
                    isFinishing: viewModel.isFinishing,
                    drugResponse: appState.medicationTracker.latestDrugResponse
                        ?? viewModel.insightEngine.latestDrugResponse
                ) {
                    dismiss()
                }
            }

            // Live breath guide — subtle always; stronger during grounding.
            // Driven by session snapshot (BreathingGuideActuatorChannel); never blocks control.
            if showsBreathingGuide {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        BreathingGuideOverlay(
                            breathsPerMinute: viewModel.breathsPerMinute,
                            isGrounding: viewModel.isGrounding,
                            alwaysVisible: true
                        )
                    }
                }
                .padding(.bottom, showsSessionControls ? 8 : 0)
                .allowsHitTesting(false)
            }

            if viewModel.isPaused && showsSessionControls {
                SessionPausedOverlay()
            }
        }
    }

    private func publishTVState() {
        guard tvDisplay.displayEnabled, scenePhase == .active else {
            tvDisplay.clearPayload()
            return
        }
        if viewModel.phase == .complete { tvDisplay.stopTVDiscovery(); return }
        if let payload = viewModel.buildTVPayload() { tvDisplay.send(payload: payload) }
        else { tvDisplay.clearPayload() }
    }

    @MainActor
    private func presentSCIExplanation() async {
        let insight = viewModel.feedbackEngine.latestInsight(for: .heartRateVariability)
        sciExplainText = await viewModel.insightEngine.explainSCI(
            score: insight?.score,
            trend: insight?.trend.asSCITrend ?? .stable,
            plainLanguage: true
        )
    }

    private var usesRegularSessionLayout: Bool {
        sizeClass == .regular && !dynamicTypeSize.isAccessibilitySize
    }

    /// Phone HUD sits in the thumb zone: metrics (active only) then pause/end.
    /// iPad regular width keeps metrics in the inspector panel instead.
    @ViewBuilder
    private var phoneSessionChrome: some View {
        if showsSessionControls {
            VStack(spacing: SessionSpacing.xs) {
                if showsLiveHUD {
                    phoneHUD
                }
                SessionControlBar(
                    isPaused: viewModel.isPaused,
                    onPauseResume: {
                        if viewModel.isPaused { viewModel.resume() } else { viewModel.pause() }
                    },
                    onEnd: { viewModel.stop() },
                    prominence: usesRegularSessionLayout ? .pad : .phone
                )
                .padding(.bottom, SessionSpacing.xxs)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var showsLiveHUD: Bool {
        guard case .active = viewModel.phase else { return false }
        return !usesRegularSessionLayout && !usesInlineHUD
    }

    /// Large text and short landscape windows keep metrics in the scroll flow,
    /// leaving only essential controls pinned rather than consuming the viewport.
    private var usesInlineHUD: Bool {
        dynamicTypeSize.isAccessibilitySize || verticalSizeClass == .compact
    }

    private var phoneHUD: some View {
        SessionHUDBar(metrics: viewModel.sessionHUDMetrics)
            .accessibilityIdentifier("session.hud")
            .padding(.horizontal, SessionSpacing.md)
            .popoverTip(SessionTips.sci)
            .popoverTip(SessionTips.airPods)
    }

    /// Breath ring during active / transition / countdown (not ready or summary).
    private var showsBreathingGuide: Bool {
        guard !viewModel.isPaused else { return false }
        switch viewModel.phase {
        case .active, .transition, .countdown, .cooldown:
            return true
        case .ready, .complete:
            return false
        }
    }

    /// Scrollable content keeps instructions reachable on short windows and at large text sizes.
    private func scrollableSessionContent<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        GeometryReader { geometry in
            ScrollView {
                content()
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollIndicators(.hidden)
            .clipped()
            .accessibilityIdentifier("session.content")
        }
    }

    private var showsSessionControls: Bool {
        switch viewModel.phase {
        case .countdown, .active, .transition: return true
        default: return false
        }
    }

    // MARK: - iPad Active Pose (stage + inspector)

    private var iPadReadyView: some View {
        HStack(alignment: .center, spacing: SessionSpacing.xxl) {
            if let firstPose = viewModel.plan.poses.first {
                PoseCoachStage(pose: firstPose, phase: .preview)
                    .frame(maxWidth: 480, maxHeight: 420)
                    .popoverTip(SessionTips.arCoach)
            }

            VStack(alignment: .leading, spacing: SessionSpacing.md) {
                Text(viewModel.plan.name.localized)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(BrandColor.fg)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(viewModel.plan.poseCount) \(LocalizedString(en: "poses", fr: "postures").localized) · \(formattedDuration(viewModel.plan.totalDuration))")
                    .font(.title3)
                    .foregroundStyle(BrandColor.fg.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
                if !viewModel.plan.description.localized.isEmpty {
                    Text(viewModel.plan.description.localized)
                        .font(.body)
                        .foregroundStyle(BrandColor.fg.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                SessionBeginButton { viewModel.start() }
                    .frame(maxWidth: 360)
                Button(SessionHUDCopy.cancel.localized) { dismiss() }
                    .font(.body)
                    .foregroundStyle(BrandColor.fg.opacity(0.55))
                    .frame(minHeight: SessionSpacing.minTapTarget)
            }
            .frame(maxWidth: 420, alignment: .leading)
        }
        .padding(.horizontal, SessionSpacing.xxl)
        .padding(.vertical, SessionSpacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func iPadActivePoseView(poseIndex: Int) -> some View {
        let pose = viewModel.plan.poses[poseIndex]
        return HStack(spacing: 0) {
            VStack(spacing: SessionSpacing.md) {
                Spacer(minLength: SessionSpacing.md)
                PoseCoachStage(pose: pose, phase: .active,
                                poseElapsed: pose.durationSeconds - viewModel.poseTimeRemaining,
                                isPaused: viewModel.isPaused)
                    .frame(maxWidth: 560, minHeight: 320, maxHeight: 440)
                    .padding(.horizontal, SessionSpacing.xl)

                SessionPoseHeader(pose: pose, prominence: .large)

                SessionCountdownNumeral(remaining: viewModel.poseTimeRemaining)
                PoseGuideDetails(pose: pose).padding(.horizontal, SessionSpacing.xl)

                if !pose.breathingPattern.localized.isEmpty {
                    Label(pose.breathingPattern.localized, systemImage: "wind")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(BrandColor.fg.opacity(0.5))
                }

                if !viewModel.currentVoiceCue.isEmpty {
                    Text(viewModel.currentVoiceCue)
                        .font(.title3.weight(.medium))
                        .foregroundStyle(BrandColor.fg.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SessionSpacing.xl)
                        .animation(SessionMotion.animation(reduceMotion: reduceMotion, duration: 0.35), value: viewModel.currentVoiceCue)
                }
                Spacer(minLength: SessionSpacing.md)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, BrandColor.hairlineStrong, .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 1)

            SessionHUDPanel(metrics: viewModel.sessionHUDMetrics, showsGauges: true)
                .frame(width: 340)
                .frame(maxHeight: .infinity)
                .background(BrandColor.bgCard)
                .popoverTip(SessionTips.sci)
                .popoverTip(SessionTips.airPods)
        }
    }

    private func iPadTransitionView(nextIndex: Int, seconds: Int) -> some View {
        HStack(spacing: 0) {
            transitionView(nextIndex: nextIndex, seconds: seconds)
                .frame(maxWidth: .infinity)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, BrandColor.hairlineStrong, .clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 1)

            SessionHUDPanel(metrics: viewModel.sessionHUDMetrics, showsGauges: true)
                .frame(width: 340)
                .frame(maxHeight: .infinity)
                .background(BrandColor.bgCard)
                .popoverTip(SessionTips.sci)
                .popoverTip(SessionTips.airPods)
        }
    }

    // MARK: - Phone Phase Views

    private var readyView: some View {
        VStack(spacing: SessionSpacing.lg) {
            Spacer(minLength: SessionSpacing.md)

            if let firstPose = viewModel.plan.poses.first {
                PoseCoachStage(pose: firstPose, phase: .preview)
                    .frame(height: dynamicTypeSize.isAccessibilitySize ? 220 : 280)
                    .padding(.horizontal, SessionSpacing.lg)
                    .popoverTip(SessionTips.arCoach)
            } else {
                Image(systemName: "figure.yoga")
                    .font(.system(size: 64, weight: .medium))
                    .foregroundStyle(SessionPalette.accent)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
            }

            Text(viewModel.plan.name.localized)
                .font(.title.weight(.bold))
                .foregroundStyle(BrandColor.fg)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, SessionSpacing.md)

            Text("\(viewModel.plan.poseCount) \(LocalizedString(en: "poses", fr: "postures").localized) · \(formattedDuration(viewModel.plan.totalDuration))")
                .font(.body)
                .foregroundStyle(BrandColor.fg.opacity(0.6))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, SessionSpacing.md)

            Spacer(minLength: SessionSpacing.md)

            SessionBeginButton { viewModel.start() }
                .padding(.horizontal, SessionSpacing.xl)

            Button(SessionHUDCopy.cancel.localized) { dismiss() }
                .font(.body)
                .foregroundStyle(BrandColor.fg.opacity(0.55))
                .frame(minHeight: SessionSpacing.minTapTarget)
                .padding(.bottom, SessionSpacing.lg)
        }
        .padding(.horizontal, SessionSpacing.sm)
    }

    private func activePoseView(poseIndex: Int) -> some View {
        let pose = viewModel.plan.poses[poseIndex]
        let catColor = Color(hue: pose.category.accentHue, saturation: 0.7, brightness: 0.9)

        return VStack(spacing: 0) {
            Spacer(minLength: SessionSpacing.sm)

            PoseCoachStage(pose: pose, phase: .active,
                            poseElapsed: pose.durationSeconds - viewModel.poseTimeRemaining,
                                isPaused: viewModel.isPaused)
                .frame(height: dynamicTypeSize.isAccessibilitySize ? 220 : 280)
                .padding(.horizontal, SessionSpacing.lg)

            SessionPoseHeader(pose: pose, prominence: dynamicTypeSize.isAccessibilitySize ? .compact : .regular)
                .padding(.top, SessionSpacing.md)
                .padding(.horizontal, SessionSpacing.md)

            SessionCountdownNumeral(remaining: viewModel.poseTimeRemaining, tint: BrandColor.fg)
                .padding(.top, SessionSpacing.md)

            if !pose.breathingPattern.localized.isEmpty {
                Label(pose.breathingPattern.localized, systemImage: "wind")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BrandColor.fg.opacity(0.5))
                    .symbolRenderingMode(.hierarchical)
                    .labelStyle(.titleAndIcon)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, SessionSpacing.xl)
                    .padding(.top, SessionSpacing.xs)
            }

            if !viewModel.currentVoiceCue.isEmpty {
                Text(viewModel.currentVoiceCue)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(BrandColor.fg.opacity(0.78))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, SessionSpacing.lg)
                    .padding(.top, SessionSpacing.sm)
                    .animation(SessionMotion.animation(reduceMotion: reduceMotion, duration: 0.35), value: viewModel.currentVoiceCue)
            }

            if usesInlineHUD {
                phoneHUD.padding(.top, SessionSpacing.md)
            }

            PoseGuideDetails(pose: pose).padding(SessionSpacing.lg)
            Spacer(minLength: SessionSpacing.xl)
        }
        .tint(catColor)
    }

    private func transitionView(nextIndex: Int, seconds: Int) -> some View {
        let nextPose = nextIndex < viewModel.plan.poses.count ? viewModel.plan.poses[nextIndex] : nil
        let catColor = nextPose.map { Color(hue: $0.category.accentHue, saturation: 0.7, brightness: 0.9) } ?? SessionPalette.accent

        return VStack(spacing: SessionSpacing.md) {
            Spacer(minLength: SessionSpacing.md)

            Text(SessionHUDCopy.nextUp.localized)
                .font(.headline)
                .foregroundStyle(BrandColor.fg.opacity(0.5))

            if let nextPose {
                PoseCoachStage(pose: nextPose, phase: .transition, isPaused: viewModel.isPaused)
                    .frame(height: 240)
                    .padding(.horizontal, SessionSpacing.lg)
                SessionPoseHeader(pose: nextPose, prominence: .regular)
                    .padding(.horizontal, SessionSpacing.md)
            }

            SessionCountdownNumeral(remaining: TimeInterval(seconds), tint: catColor)

            Spacer(minLength: SessionSpacing.md)
        }
    }

    private var cooldownView: some View {
        VStack(spacing: SessionSpacing.md) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 56, weight: .medium))
                .foregroundStyle(SessionPalette.accent)
                .symbolRenderingMode(.hierarchical)
            Text(LocalizedString(en: "Great work!", fr: "Excellent travail!").localized)
                .font(.title.weight(.bold))
                .foregroundStyle(BrandColor.fg)
            Text(LocalizedString(en: "Wrapping up your session...", fr: "Fin de votre séance...").localized)
                .font(.body)
                .foregroundStyle(BrandColor.fg.opacity(0.6))
            ProgressView()
                .tint(SessionPalette.accent)
            Spacer()
        }
    }

    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if seconds == 0 {
            return "\(minutes) min"
        }
        return "\(minutes)m \(seconds)s"
    }
}

// InsightTrend → SCITrend bridge is defined in BonhommeCore/TVDisplay/TVDisplayPayload.swift

/// Explicit consent applies to both authenticated TV relay and external scenes.
/// An incoming QR URL pre-fills the invitation; it never starts sharing by itself.
struct TVConnectionSheet: View {
    let invitationURL: URL?
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var coordinator = TVDisplayCoordinator.shared
    @State private var selectedTV: UUID?
    @State private var pairingKey = ""
    @State private var errorMessage: String?
    @State private var attemptedPairing = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(copy("Show the pose guide, session timing and available heart-rate/SCI readings on your TV. Anyone in the room can see these readings.",
                              "Affichez le guide, le chronomètre et les mesures cardiaques/SCI disponibles sur votre téléviseur. Les personnes présentes peuvent voir ces mesures."))
                    Toggle(copy("Share this session on TV", "Partager cette séance à la télévision"), isOn: $coordinator.displayEnabled)
                        .accessibilityIdentifier("tv.shareSession")
                    Text(copy("The display clears when the session ends, the app leaves the foreground or the connection becomes stale. Keep your iPhone or iPad open during the session.",
                              "L’affichage s’efface à la fin de la séance, lorsque l’app quitte le premier plan ou si la connexion n’est plus à jour. Gardez l’app ouverte pendant la séance."))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section(copy("NATURaL on Apple TV", "NATURaL sur Apple TV")) {
                    if coordinator.nativeConnected {
                        Label(copy("Connected securely", "Connexion sécurisée"), systemImage: "checkmark.shield")
                        Button(TVRelayCopy.disconnect.localized) { coordinator.disconnectNativeTV() }
                    } else {
                        Text(copy("Open NATURaL on Apple TV and choose Pair iPhone or iPad. Scan its QR code using Camera, or choose the TV here and enter its key.",
                                  "Ouvrez NATURaL sur Apple TV et choisissez Jumeler un iPhone ou iPad. Scannez le code QR avec Appareil photo ou choisissez le téléviseur ici et saisissez sa clé."))
                        if coordinator.discoveryUnavailable {
                            Text(TVRelayCopy.unavailable.localized).foregroundStyle(.secondary)
                            Text(copy("Allow Local Network in Settings → Apps → NATURaL. Both devices must use the same local network.",
                                      "Autorisez Réseau local dans Réglages → Apps → NATURaL. Les appareils doivent utiliser le même réseau local."))
                                .font(.footnote)
                        }
                        Picker(copy("Television", "Téléviseur"), selection: $selectedTV) {
                            Text(copy("Choose a TV", "Choisir un téléviseur")).tag(nil as UUID?)
                            ForEach(coordinator.discoveredTVs) { tv in
                                Text(tv.name).tag(Optional(tv.id))
                            }
                        }
                        SecureField(copy("Pairing key", "Clé de jumelage"), text: $pairingKey)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .accessibilityIdentifier("tv.pairingKey")
                        if coordinator.discoveredTVs.isEmpty {
                            Label(copy("Looking for a pairing invitation…", "Recherche d’une invitation de jumelage…"), systemImage: "antenna.radiowaves.left.and.right")
                                .foregroundStyle(.secondary)
                        }
                        Button {
                            guard let selectedTV else { return }
                            do {
                                try coordinator.pair(with: selectedTV, key: pairingKey)
                                attemptedPairing = true
                                errorMessage = nil
                            } catch {
                                errorMessage = copy("Could not pair. Check the selected TV and its current key, then try again.",
                                                    "Jumelage impossible. Vérifiez le téléviseur et sa clé actuelle, puis réessayez.")
                            }
                        } label: {
                            HStack {
                                Text(copy("Confirm and connect", "Confirmer et connecter"))
                                if coordinator.nativeConnecting { ProgressView() }
                            }
                        }
                        .disabled(!coordinator.displayEnabled || selectedTV == nil || pairingKey.count != 43 || coordinator.nativeConnecting)
                        .accessibilityIdentifier("tv.confirmPairing")
                        if let errorMessage { Text(errorMessage).foregroundStyle(.secondary) }
                    }
                }
                Section(copy("AirPlay or a cable", "AirPlay ou un câble")) {
                    Label(coordinator.externalDisplayConnected
                          ? copy("External display connected", "Écran externe connecté")
                          : copy("No external display connected", "Aucun écran externe connecté"), systemImage: "tv")
                    Text(copy("For AirPlay, open Control Center → Screen Mirroring and choose your television. For a wired display, connect a compatible HDMI adapter. Enable sharing above to show the dedicated guide when iOS provides a second screen.",
                              "Pour AirPlay, ouvrez Centre de contrôle → Recopie de l’écran et choisissez votre téléviseur. Pour un écran filaire, utilisez un adaptateur HDMI compatible. Activez le partage ci-dessus pour afficher le guide lorsque iOS fournit un second écran."))
                    Text(copy("Some receivers mirror the whole phone screen instead. Silence notifications and keep the workout open. The phone remains your controller if a TV connection fails.",
                              "Certains récepteurs recopient tout l’écran du téléphone. Désactivez les notifications et gardez la séance ouverte. Le téléphone reste votre commande si la connexion TV échoue."))
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle(copy("TV display", "Affichage TV"))
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button(copy("Done", "Terminé")) { dismiss() }
            } }
        }
        .task {
            coordinator.beginTVDiscovery()
            if let invitationURL, let pairing = try? TVRelayPairing(url: invitationURL) {
                selectedTV = pairing.id
                pairingKey = pairing.code
            }
        }
        .onChange(of: coordinator.nativeConnecting) { old, connecting in
            if old && !connecting && attemptedPairing && !coordinator.nativeConnected {
                errorMessage = copy("The connection did not complete. Keep NATURaL open on the TV and try a new invitation.",
                                    "La connexion n’a pas abouti. Gardez NATURaL ouvert sur le téléviseur et essayez une nouvelle invitation.")
            }
        }
        .onChange(of: coordinator.displayEnabled) { _, enabled in
            if !enabled { coordinator.clearPayload(); coordinator.disconnectNativeTV() }
        }
        .onDisappear {
            pairingKey = ""
            if !coordinator.displayEnabled { coordinator.stopTVDiscovery() }
        }
    }

    private func copy(_ en: String, _ fr: String) -> String { LocalizedString(en: en, fr: fr).localized }
}
