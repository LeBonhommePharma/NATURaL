import SwiftUI
import BonhommeCore

/// Compact workout session UI for Apple Watch.
/// Uses a vertical paging TabView (watchOS 10+) with three pages:
/// 1. Current pose + countdown
/// 2. Heart rate + SCI focus score
/// 3. Session progress + controls
struct WatchSessionView: View {
    @Environment(WatchWorkoutManager.self) private var manager
    @Environment(WatchConnectivityBridge.self) private var connectivity
    @Environment(\.dismiss) private var dismiss

    let plan: WorkoutPlan

    @State private var selectedTab = 0
    @State private var startError: String?
    @State private var startupTask: Task<Void, Never>?
    @State private var relayTask: Task<Void, Never>?
    @State private var crownRotationalDelta: Double = 0
    @State private var breathsPerMinute: Double = BreathingGuideActuatorChannel.defaultBreathsPerMinute
    @State private var isGrounding: Bool = false
    /// Debounce full Crooks ticks from crown micro-deltas (β still applies immediately).
    @State private var crownTickTask: Task<Void, Never>?
    @State private var breathHaptics = BreathingHapticGuide()

    var body: some View {
        TabView(selection: $selectedTab) {
            poseTab
                .tag(0)
                .accessibilityLabel(Text(LocalizedString(en: "Pose", fr: "Posture").localized))
            biofeedbackTab
                .tag(1)
                .accessibilityLabel(Text(SessionHUDCopy.focusIndex.localized))
            controlsTab
                .tag(2)
                .accessibilityLabel(Text(LocalizedString(en: "Controls", fr: "Commandes").localized))
        }
        .tabViewStyle(.verticalPage)
        .containerBackground(SessionPalette.sessionBackground.gradient, for: .tabView)
        .navigationBarBackButtonHidden(manager.isRecording)
        .focusable()
        .digitalCrownRotation(
            $crownRotationalDelta,
            from: -20,
            through: 20,
            by: 0.25,
            sensitivity: .medium,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownRotationalDelta) { oldValue, newValue in
            let delta = newValue - oldValue
            guard manager.isRecording, !manager.isPaused, !manager.isEnding, abs(delta) > 1e-6 else { return }
            Task {
                // Apply β immediately for responsive dial feel. Not shown on the HUD.
                _ = await PharmaControlSessionManager.shared.applyCrownDelta(delta)
            }
            // Debounce full Crooks ticks — 2s relay owns steady ticks; crown only
            // nudges control after rotation settles (~150ms).
            crownTickTask?.cancel()
            crownTickTask = Task {
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled, manager.isRecording, !manager.isPaused, !manager.isEnding else { return }
                let bpm = manager.currentHeartRate ?? plan.style.nominalBPM
                let sci = manager.feedbackEngine.latestInsight(for: .heartRateVariability)?.score
                let beta = await PharmaControlSessionManager.shared.snapshot().crownBeta
                let result = await PharmaControlSessionManager.shared.tickFromSCI(
                    sciScore: sci,
                    bpm: bpm,
                    crownBeta: beta
                )
                _ = result
                await applySessionSnapshot()
            }
        }
        .onAppear { startWorkout() }
        .alert(LocalizedString(en: "Unable to start", fr: "Démarrage impossible").localized, isPresented: Binding(get: { startError != nil }, set: { if !$0 { startError = nil } })) {
            Button(LocalizedString(en: "Try again", fr: "Réessayer").localized) { startWorkout() }
            Button(LocalizedString(en: "Back", fr: "Retour").localized, role: .cancel) { dismiss() }
        } message: {
            Text(startError ?? "")
        }
        .onDisappear {
            startupTask?.cancel()
            relayTask?.cancel()
            crownTickTask?.cancel()
            breathHaptics.stop()
        }
        .onChange(of: manager.isPaused) { _, paused in
            crownTickTask?.cancel()
            if paused { breathHaptics.stop() }
            else if manager.isRecording && !manager.isEnding { breathHaptics.start() }
        }
        .onChange(of: manager.isEnding) { _, ending in
            if ending { breathHaptics.stop(); crownTickTask?.cancel() }
        }
        .onChange(of: manager.phase) { _, newPhase in
            if case .complete = newPhase {
                handleWorkoutComplete()
            }
        }
    }

    // MARK: - Tab 1: Pose + Countdown

    private var poseTab: some View {
        VStack(spacing: SessionSpacing.xs) {
            switch manager.phase {
            case .idle:
                ProgressView()
                    .tint(SessionPalette.accent)
                Text(LocalizedString(en: "Starting...", fr: "Démarrage...").localized)
                    .font(.footnote)
                    .foregroundStyle(.secondary)

            case .active(let index):
                if let pose = plan.poses[safe: index] {
                    activePoseContent(pose: pose)
                }

            case .transition(let nextIndex, let seconds):
                transitionContent(nextIndex: nextIndex, seconds: seconds)

            case .cooldown:
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundStyle(SessionPalette.accent)
                    .symbolRenderingMode(.hierarchical)
                Text(LocalizedString(en: "Great work!", fr: "Bravo!").localized)
                    .font(.headline)

            case .complete:
                if manager.saveFailed {
                    Text(LocalizedString(en: "Workout ended. Health could not save this session.", fr: "Séance terminée. Santé n’a pas pu l’enregistrer.").localized)
                        .font(.footnote)
                        .foregroundStyle(BrandColor.strawberry)
                }
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(SessionPalette.accent)
                Text(LocalizedString(en: "Done!", fr: "Terminé!").localized)
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func activePoseContent(pose: Pose) -> some View {
        VStack(spacing: SessionSpacing.xs) {
            if manager.isPaused {
                SessionStatusChip(
                    title: SessionHUDCopy.paused.localized,
                    systemImage: "pause.circle.fill",
                    tint: BrandColor.strawberry,
                    compact: true
                )
            }

            Text(pose.name.localized)
                .font(.headline)
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)

            SessionCountdownNumeral(remaining: manager.poseTimeRemaining, tint: .white)

            SessionGlanceStrip(metrics: watchHUDMetrics)
        }
    }

    private func transitionContent(nextIndex: Int, seconds: Int) -> some View {
        VStack(spacing: SessionSpacing.xs) {
            Text(SessionHUDCopy.nextUp.localized)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let nextPose = plan.poses[safe: nextIndex] {
                Text(nextPose.name.localized)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            SessionCountdownNumeral(remaining: TimeInterval(seconds), tint: SessionPalette.accent)
        }
    }

    // MARK: - Tab 2: Biofeedback

    private var biofeedbackTab: some View {
        VStack(spacing: SessionSpacing.sm) {
            HStack(alignment: .center, spacing: SessionSpacing.sm) {
                CompactSCIMeter(
                    score: manager.feedbackEngine.latestInsight(for: .heartRateVariability)?.score,
                    trend: manager.feedbackEngine.latestInsight(for: .heartRateVariability)?.trend.asSCITrend ?? .stable,
                    size: 44
                )
                SessionHeartRateReadout(bpm: manager.currentHeartRate, compact: true)
            }

            SessionStatusChip(
                title: watchHUDMetrics.isPaused
                    ? SessionHUDCopy.paused.localized
                    : watchHUDMetrics.entropyState.label.localized,
                systemImage: watchHUDMetrics.isPaused ? "pause.circle.fill" : watchHUDMetrics.entropyState.symbolName,
                tint: watchHUDMetrics.isPaused ? BrandColor.strawberry : SessionPalette.entropy(watchHUDMetrics.entropyState),
                compact: true
            )

            if isGrounding, watchHUDMetrics.tempoBPM != nil {
                SessionStatusChip(
                    title: "\(watchHUDMetrics.tempoText) \(SessionHUDCopy.bpm.localized)",
                    systemImage: "metronome.fill",
                    tint: BrandColor.strawberry,
                    compact: true
                )
            }

            BreathingGuideView(
                breathsPerMinute: breathsPerMinute,
                isGrounding: isGrounding,
                prominence: isGrounding ? .grounding : .subtle
            )
            .frame(height: 28)
            .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(watchHUDMetrics.accessibilitySummary))
    }

    // MARK: - Tab 3: Controls

    private var controlsTab: some View {
        VStack(spacing: SessionSpacing.sm) {
            Text(plan.poseCount > 0
                 ? "\(manager.posesCompletedCount)/\(plan.poseCount)"
                 : "—")
                .font(.title3.weight(.bold).monospacedDigit())
                .foregroundStyle(.white)
            Text(SessionHUDMetrics.formatElapsed(manager.elapsedTime))
                .font(.body.monospacedDigit())
                .foregroundStyle(.white.opacity(0.6))

            Spacer(minLength: 4)

            if manager.isRecording && !manager.isEnding && !manager.isPaused {
                Button {
                    manager.pause()
                } label: {
                    Label(SessionHUDCopy.pause.localized, systemImage: "pause.fill")
                        .frame(maxWidth: .infinity, minHeight: SessionSpacing.minTapTarget)
                }
                .tint(SessionPalette.accent)
                .buttonStyle(.bordered)
            } else if manager.isRecording && !manager.isEnding && manager.isPaused {
                Button {
                    manager.resume()
                } label: {
                    Label(SessionHUDCopy.resume.localized, systemImage: "play.fill")
                        .frame(maxWidth: .infinity, minHeight: SessionSpacing.minTapTarget)
                }
                .tint(SessionPalette.accent)
                .buttonStyle(.borderedProminent)
            }

            Button(role: .destructive) {
                if manager.phase == .complete { dismiss() }
                else { Task { try? await manager.end() } }
            } label: {
                Text(manager.phase == .complete
                     ? LocalizedString(en: "Done", fr: "Terminé").localized
                     : SessionHUDCopy.end.localized)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: SessionSpacing.minTapTarget)
            }
            .buttonStyle(.bordered)
            .disabled(manager.isStarting || manager.isEnding || manager.phase == .idle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, SessionSpacing.xs)
    }

    // MARK: - Lifecycle

    private func startWorkout() {
        guard !manager.isStarting, !manager.isEnding, manager.phase != .complete else { return }
        if manager.isRecording {
            if !manager.isPaused { breathHaptics.start() }
            startBiofeedbackRelay()
            return
        }
        startupTask?.cancel()
        startError = nil
        startupTask = Task {
            await PharmaControlSessionManager.shared.start(
                nominalBPM: plan.style.nominalBPM,
                groundingBPM: plan.style.groundingBPM
            )
            do {
                try await manager.start(plan: plan)
                guard !Task.isCancelled else {
                    try? await manager.end()
                    return
                }
                breathHaptics.start()
                startBiofeedbackRelay()
            } catch {
                await PharmaControlSessionManager.shared.stop()
                guard !Task.isCancelled else { return }
                startError = LocalizedString(en: "Check Health permissions on your Watch, then try again. You can also use guided sessions on your iPhone.", fr: "Vérifiez les autorisations Santé sur votre Watch, puis réessayez. Les séances guidées restent disponibles sur votre iPhone.").localized
            }
        }
    }

    /// WCSession biofeedback relay + Crooks control tick (σ_irr, β, beat).
    private func startBiofeedbackRelay() {
        relayTask?.cancel()
        relayTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled, manager.isRecording else { return }
                guard !manager.isPaused, !manager.isEnding else { continue }

                let snapshot = manager.buildBiofeedbackSnapshot()
                connectivity.sendBiofeedback(snapshot)

                // HRV-only on the control path (avoid full multi-analyzer pass every 2s).
                _ = manager.feedbackEngine.analyze(for: .heartRateVariability)
                let sci = manager.feedbackEngine.latestInsight(for: .heartRateVariability)?.score
                let bpm = manager.currentHeartRate ?? plan.style.nominalBPM
                let result = await PharmaControlSessionManager.shared.tickFromSCI(
                    sciScore: sci,
                    bpm: bpm
                )
                _ = result
                await applySessionSnapshot()
            }
        }
    }

    /// Pull breath rate / grounding / β from session snapshot for UI + haptics.
    private func applySessionSnapshot() async {
        let snap = await PharmaControlSessionManager.shared.snapshot()
        breathsPerMinute = snap.effectiveBreathsPerMinute
        isGrounding = snap.isGrounding
        breathHaptics.update(
            breathsPerMinute: snap.effectiveBreathsPerMinute,
            isGrounding: snap.isGrounding
        )
    }

    private func handleWorkoutComplete() {
        relayTask?.cancel()
        crownTickTask?.cancel()
        breathHaptics.stop()
        Task { await PharmaControlSessionManager.shared.stop() }
        if let result = manager.buildResult() {
            connectivity.transferWorkoutResult(result)
        }
    }

    // MARK: - Helpers

    private var watchHUDMetrics: SessionHUDMetrics {
        let insight = manager.feedbackEngine.latestInsight(for: .heartRateVariability)
        let poseIndex: Int = {
            switch manager.phase {
            case .active(let idx): return idx
            case .transition(let next, _): return max(0, next - 1)
            default: return 0
            }
        }()
        return SessionHUDMetrics(
            sciScore: insight?.score,
            sciTrend: insight?.trend.asSCITrend ?? .stable,
            heartRate: manager.currentHeartRate,
            tempoBPM: isGrounding ? plan.style.groundingBPM : plan.style.nominalBPM,
            isGrounding: isGrounding,
            isPaused: manager.isPaused,
            elapsed: manager.elapsedTime,
            poseIndex: poseIndex,
            poseCount: plan.poseCount,
            breathsPerMinute: breathsPerMinute
        )
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
