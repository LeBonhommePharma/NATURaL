import SwiftUI
import Observation
import ActivityKit
import BonhommeCore

/// State machine driving the guided pose-by-pose workout experience.
/// Supports state restoration for killed-app recovery and adaptive music via SCI.
@Observable
@MainActor
final class WorkoutFlowViewModel {

    // MARK: - Phase

    enum Phase: Equatable, Codable {
        case ready
        case countdown(secondsRemaining: Int)
        case active(poseIndex: Int)
        case transition(nextPoseIndex: Int, secondsRemaining: Int)
        case cooldown
        case complete
    }

    // MARK: - Published State

    private(set) var phase: Phase = .ready
    private(set) var poseTimeRemaining: TimeInterval = 0
    private(set) var elapsedTime: TimeInterval = 0

    let plan: WorkoutPlan
    let recorder = WorkoutRecorder()
    let feedbackEngine: FeedbackEngine
    let musicService = MusicService()
    private let stateStore = WorkoutStateStore()

    /// Crooks-cycle pharma control session (σ_irr minimization, universal beat sync).
    private let pharmaControl = PharmaControlSessionManager.shared

    /// Latest σ_irr snapshot for metrics / debug overlays.
    private(set) var sigmaIrr: Double = 0
    private(set) var crooksPhase: ThermodynamicPhase = .forward
    private(set) var crownBeta: Double = 0

    /// Tracks whether this session was restored from a killed app.
    private(set) var isRestoredSession = false

    /// BUG 5 FIX: Track completed poses explicitly instead of using currentPoseIndex + 1.
    /// Incremented only when a pose timer reaches zero naturally (i.e., pose was fully held).
    private(set) var posesCompletedCount: Int = 0

    /// Whether the session is currently paused (timer cancelled, HealthKit suspended).
    private(set) var isPaused: Bool = false

    var currentPose: Pose? {
        switch phase {
        case .active(let idx): return plan.poses[safe: idx]
        case .transition(let nextIdx, _): return plan.poses[safe: max(0, nextIdx - 1)]
        default: return nil
        }
    }

    var currentPoseIndex: Int {
        switch phase {
        case .active(let idx): return idx
        case .transition(let nextIdx, _): return max(0, nextIdx - 1)
        default: return 0
        }
    }

    // MARK: - Private

    private var timerTask: Task<Void, Never>?
    private var sessionStartDate: Date?
    private var persistenceCounter: Int = 0
    private var liveActivity: Activity<WorkoutActivityAttributes>?

    init(plan: WorkoutPlan, feedbackEngine: FeedbackEngine = FeedbackEngine()) {
        self.plan = plan
        self.feedbackEngine = feedbackEngine
        // Ensure HRV analyzer is present even when a bare engine is injected.
        feedbackEngine.register(HRVAnalyzer())
        // Wire live HR → synthetic RR → FeedbackEngine (mirrors Watch path).
        recorder.onHRVIngest = { [weak self] sdnn, rmssd, rr in
            self?.ingestHRVSample(sdnn: sdnn, rmssd: rmssd, rrIntervals: rr)
        }
    }

    // MARK: - State Restoration

    /// Attempt to restore a killed-app workout session from local activity.
    /// Uses `LocalActivitySessionLoader` (detect → load) so the same path is unit-tested in BonhommeCore.
    /// Returns a configured ViewModel if recoverable state exists, nil otherwise.
    static func restoreIfAvailable(
        feedbackEngine: FeedbackEngine = FeedbackEngine(),
        store: WorkoutStateStore = WorkoutStateStore()
    ) -> WorkoutFlowViewModel? {
        let loader = LocalActivitySessionLoader(store: store)
        guard let session = loader.detectAndLoad() else {
            return nil
        }
        return WorkoutFlowViewModel(restoredSession: session, feedbackEngine: feedbackEngine)
    }

    /// Builds a ViewModel from a previously loaded `RestoredLocalSession` (auto-load path).
    convenience init(restoredSession session: RestoredLocalSession, feedbackEngine: FeedbackEngine = FeedbackEngine()) {
        self.init(plan: session.plan, feedbackEngine: feedbackEngine)
        self.isRestoredSession = true
        self.sessionStartDate = session.sessionStartDate
        self.elapsedTime = session.elapsedTime
        self.poseTimeRemaining = session.poseTimeRemaining
        self.posesCompletedCount = session.posesCompletedCount

        switch session.phase {
        case .ready:
            self.phase = .ready
        case .countdown(let secs):
            self.phase = .countdown(secondsRemaining: secs)
        case .active(let idx):
            self.phase = .active(poseIndex: idx)
        case .transition(let nextIdx, let secs):
            self.phase = .transition(nextPoseIndex: nextIdx, secondsRemaining: secs)
            self.poseTimeRemaining = session.poseTimeRemaining
        case .cooldown:
            self.phase = .cooldown
        case .complete:
            self.phase = .complete
        }
    }

    /// Resume a restored session: reconnect to the HealthKit workout session
    /// and restart timers from the persisted state.
    ///
    /// Mirrors `start()` control wiring: beat sync + route observer + pharma
    /// session must be live so HR ingest → SCI → Crooks actuators work after kill/restore.
    /// (`onHRVIngest` is already wired in `init`.)
    func resumeRestoredSession() {
        guard isRestoredSession else { return }

        musicService.bindUniversalBeatSync()
        Task {
            await pharmaControl.start()
            // Attempt to recover the existing HealthKit workout session.
            await recoverHealthKitSession()

            // Resume music (fire-and-forget; never block pose recovery).
            Task { [weak self] in
                guard let self else { return }
                await self.musicService.requestAuthorization()
                await self.musicService.prefetchPlaylists(style: self.plan.style)
                await self.musicService.playWorkoutMusic(
                    mood: self.musicService.adaptiveMood,
                    style: self.plan.style
                )
            }

            // Resume at the current phase.
            switch phase {
            case .active(let idx):
                startPoseTimer(for: idx)
            case .transition(let nextIdx, _):
                startTransition(to: nextIdx)
            case .cooldown:
                startCooldown()
            case .countdown:
                startCountdownSequence()
            default:
                break
            }
        }
    }

    /// Tries to recover an active HKWorkoutSession from a previous app launch.
    private func recoverHealthKitSession() async {
        // HKWorkoutSession persists across app restarts on iOS 17+.
        // The WorkoutRecorder will attempt to reconnect to any active session.
        // If no session is found, we start a fresh one.
        do {
            // BUG 1 FIX: Pass `plan.style` so the restored HKWorkout is logged under
            // the correct HKWorkoutActivityType, not the `.chairYoga` default.
            try await recorder.start(style: plan.style)
        } catch {
            // Session may already be active from the previous launch;
            // WorkoutRecorder handles this gracefully.
        }
    }

    /// Persist current state to UserDefaults. Called every 5 seconds during
    /// active workouts and on scene phase changes.
    func persistState() {
        let persistedPhase: WorkoutStateStore.PersistedPhase
        switch phase {
        case .ready: persistedPhase = .ready
        case .countdown(let secs): persistedPhase = .countdown(secondsRemaining: secs)
        case .active(let idx): persistedPhase = .active(poseIndex: idx)
        case .transition(let nextIdx, let secs): persistedPhase = .transition(nextPoseIndex: nextIdx, secondsRemaining: secs)
        case .cooldown: persistedPhase = .cooldown
        case .complete: persistedPhase = .complete
        }

        stateStore.save(
            planId: plan.id,
            phase: persistedPhase,
            poseTimeRemaining: poseTimeRemaining,
            elapsedTime: elapsedTime,
            sessionStartDate: sessionStartDate ?? Date(),
            currentPoseIndex: currentPoseIndex
        )
    }

    // MARK: - Controls

    func start() {
        // BUG 8 (minor) FIX: Reset persistence counter so the first persist fires
        // predictably at tick 5, regardless of any prior session on this VM instance.
        persistenceCounter = 0
        posesCompletedCount = 0
        sessionStartDate = Date()
        phase = .countdown(secondsRemaining: 3)
        musicService.bindUniversalBeatSync()
        Task { await pharmaControl.start() }
        startCountdownSequence()
    }

    func pause() {
        isPaused = true
        recorder.pause()
        musicService.pause()
        timerTask?.cancel()
        persistState()
    }

    func resume() {
        isPaused = false
        recorder.resume()
        Task { [weak self] in
            guard let self else { return }
            await self.musicService.playWorkoutMusic(mood: self.musicService.adaptiveMood, style: self.plan.style)
        }

        // BUG 2 FIX: Original code only restarted the timer for the .active phase,
        // leaving the session permanently frozen if the user paused mid-transition
        // or (edge case) mid-countdown. Handle all timer-bearing phases.
        switch phase {
        case .active(let idx):
            // BUG 4 FIX: If poseTimeRemaining somehow hit 0 exactly at the pause
            // boundary, restarting the while-loop would exit immediately and silently
            // advance the sequence. Detect this and advance explicitly instead.
            if poseTimeRemaining > 0 {
                startPoseTimer(for: idx)
            } else {
                let next = idx + 1
                if next < plan.poses.count {
                    startTransition(to: next)
                } else {
                    startCooldown()
                }
            }
        case .transition(let nextIdx, _):
            // Session was paused during a transition window — resume the countdown.
            startTransition(to: nextIdx)
        case .countdown:
            // Unlikely but guard against a pause hitting right during the 3-2-1.
            startCountdownSequence()
        default:
            break
        }
    }

    func stop() {
        timerTask?.cancel()
        phase = .complete
        stateStore.clear()
        musicService.stop()
        endLiveActivity()
        Task {
            await pharmaControl.stop()
            let sciInsight = feedbackEngine.latestInsight(for: .heartRateVariability)
            let metadata = buildWorkoutMetadata(sciScore: sciInsight?.score)
            try? await recorder.end(metadata: metadata)
        }
    }

    /// Builds a TVDisplayPayload from current state for TV relay.
    /// Uses FeedbackEngine insights to populate the SCI score and trend.
    func buildTVPayload() -> TVDisplayPayload? {
        guard let pose = currentPose else { return nil }

        let insights = feedbackEngine.analyzeAll()
        return TVDisplayPayload(
            currentPose: pose,
            poseTimeRemaining: poseTimeRemaining,
            totalPoseTime: pose.durationSeconds,
            biofeedback: BiofeedbackSnapshot(
                heartRate: recorder.currentHeartRate,
                activeCalories: recorder.activeCalories,
                feedbackInsights: insights
            ),
            sessionElapsed: elapsedTime,
            isPaused: isPaused,
            sequenceIndex: currentPoseIndex,
            sequenceTotal: plan.poseCount
        )
    }

    /// Ingest an HRV sample from HealthKit into the FeedbackEngine.
    /// Call this from the workout recorder's HRV observer query.
    func ingestHRVSample(sdnn: Double, rmssd: Double, rrIntervals: [Double] = []) {
        let signal = HRVSignal(
            timestamp: Date(),
            sdnn: sdnn,
            rmssd: rmssd,
            rrIntervals: rrIntervals
        )
        feedbackEngine.ingest(signal)
    }

    // MARK: - Result

    func buildResult() -> WorkoutResult {
        stateStore.clear()
        return WorkoutResult(
            workoutPlanId: plan.id,
            workoutPlanName: plan.name.localized,
            startDate: sessionStartDate ?? Date(),
            endDate: Date(),
            totalDuration: elapsedTime,
            // BUG 5 FIX: Use the explicitly tracked counter instead of currentPoseIndex + 1.
            // currentPoseIndex + 1 over-counts when stop() is called before any pose completes
            // and under-counts after transitions. posesCompletedCount is incremented only when
            // a pose timer reaches zero naturally inside startPoseTimer.
            posesCompleted: posesCompletedCount,
            totalPoses: plan.poseCount,
            activeCalories: recorder.activeCalories,
            averageHeartRate: recorder.averageHeartRate,
            maxHeartRate: recorder.heartRateSamples.map(\.bpm).max(),
            heartRateSamples: recorder.heartRateSamples,
            yogaStyle: plan.style,
            yogaStyleName: plan.style.localizedName.localized
        )
    }

    /// Builds metadata for enriching the HKWorkout record.
    func buildWorkoutMetadata(sciScore: Double?) -> WorkoutMetadata {
        WorkoutMetadata(
            planId: plan.id,
            planName: plan.name.localized,
            styleName: plan.style.localizedName.localized,
            sciScore: sciScore
        )
    }

    // MARK: - Live Activity

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = WorkoutActivityAttributes(
            planName: plan.name.localized,
            styleName: plan.style.localizedName.localized,
            styleSymbol: plan.style.symbolName,
            totalPoses: plan.poseCount,
            accentHue: plan.style.accentHue
        )

        let initialState = WorkoutActivityAttributes.ContentState(
            currentPoseName: plan.poses.first?.name.localized ?? "",
            poseIndex: 0,
            poseTimeRemaining: Int(plan.poses.first?.durationSeconds ?? 0),
            elapsedTime: 0,
            heartRate: nil,
            calories: 0
        )

        do {
            liveActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
        } catch {
            // Live Activity not available; continue without it
        }
    }

    private func updateLiveActivity() {
        guard let liveActivity else { return }

        let state = WorkoutActivityAttributes.ContentState(
            currentPoseName: currentPose?.name.localized ?? "",
            poseIndex: currentPoseIndex,
            poseTimeRemaining: Int(poseTimeRemaining),
            elapsedTime: elapsedTime,
            heartRate: recorder.currentHeartRate.map { Int($0) },
            calories: Int(recorder.activeCalories)
        )

        Task {
            await liveActivity.update(.init(state: state, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let liveActivity else { return }

        let finalState = WorkoutActivityAttributes.ContentState(
            currentPoseName: "Complete",
            poseIndex: plan.poseCount - 1,
            poseTimeRemaining: 0,
            elapsedTime: elapsedTime,
            heartRate: recorder.currentHeartRate.map { Int($0) },
            calories: Int(recorder.activeCalories)
        )

        Task {
            await liveActivity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .after(.now + 10))
        }
        self.liveActivity = nil
    }

    // MARK: - Timer Logic

    private func startCountdownSequence() {
        timerTask?.cancel()
        timerTask = Task {
            for i in stride(from: 3, through: 1, by: -1) {
                phase = .countdown(secondsRemaining: i)
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
            }

            // FIX: Start HealthKit recording in background — don't block workout flow.
            // The workout MUST proceed even if HealthKit initialization is slow or fails.
            // This prevents the countdown-freezes-at-1 bug when HealthKit or WatchConnectivity
            // is not properly initialized.
            Task { [weak self] in
                guard let self else { return }
                do {
                    try await self.recorder.start(style: self.plan.style)
                    print("✅ HealthKit workout session started successfully")
                } catch {
                    print("⚠️ HealthKit workout session failed to start: \(error)")
                    // Continue workout without HealthKit recording
                }
            }

            // Music is fire-and-forget — MusicAuthorization.request() and
            // the Apple Music catalog search can both block indefinitely on
            // simulator or without an active Apple Music subscription.
            // The workout flow must NEVER await music.
            Task { [weak self] in
                guard let self else { return }
                await self.musicService.requestAuthorization()
                // Prefetch all mood playlists for this style, then start calm.
                await self.musicService.prefetchPlaylists(style: self.plan.style)
                await self.musicService.playWorkoutMusic(mood: .calm, style: self.plan.style)
            }

            // Start Live Activity for Dynamic Island
            startLiveActivity()

            // Begin first pose IMMEDIATELY — don't wait for HealthKit or Music
            beginPose(at: 0)
        }
    }

    private func beginPose(at index: Int) {
        guard index < plan.poses.count else {
            phase = .cooldown
            startCooldown()
            return
        }

        let pose = plan.poses[index]
        poseTimeRemaining = pose.durationSeconds
        phase = .active(poseIndex: index)
        startPoseTimer(for: index)
    }

    private func startPoseTimer(for index: Int) {
        timerTask?.cancel()
        timerTask = Task {
            while poseTimeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                poseTimeRemaining = max(0, poseTimeRemaining - 1)
                if let start = sessionStartDate {
                    elapsedTime = Date().timeIntervalSince(start)
                }

                // Update Live Activity every tick
                updateLiveActivity()

                // Periodic state persistence + control tick (every 5 seconds).
                // Music adapt is fire-and-forget so MusicKit never blocks the pose loop.
                persistenceCounter += 1
                if persistenceCounter % 5 == 0 {
                    persistState()
                    Task { [weak self] in
                        await self?.adaptMusicToCurrentSCI()
                    }
                    await tickPharmaControl()
                }
            }

            // BUG 5 FIX: Pose reached zero naturally — it was fully held. Count it.
            posesCompletedCount += 1

            // Transition to next pose
            let nextIndex = index + 1
            if nextIndex < plan.poses.count {
                startTransition(to: nextIndex)
            } else {
                phase = .cooldown
                startCooldown()
            }
        }
    }

    private func startTransition(to nextIndex: Int) {
        timerTask?.cancel()
        timerTask = Task {
            let transitionDuration = Int(plan.transitionSeconds)
            for i in stride(from: transitionDuration, through: 1, by: -1) {
                phase = .transition(nextPoseIndex: nextIndex, secondsRemaining: i)
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
            }
            beginPose(at: nextIndex)
        }
    }

    private func startCooldown() {
        timerTask?.cancel()
        timerTask = Task {
            try? await Task.sleep(for: .seconds(5))
            guard !Task.isCancelled else { return }

            // Build metadata with latest SCI score for HKWorkout enrichment
            let sciInsight = feedbackEngine.latestInsight(for: .heartRateVariability)
            let metadata = buildWorkoutMetadata(sciScore: sciInsight?.score)
            try? await recorder.end(metadata: metadata)

            musicService.stop()
            endLiveActivity()
            stateStore.clear()
            await pharmaControl.stop()
            phase = .complete
        }
    }

    // MARK: - Crooks Pharma Control

    /// SCI + HR → Crooks tick (σ_irr, phase, universal beat).
    /// Uses HRV-only analyze (not full analyzeAll) on the control path.
    private func tickPharmaControl() async {
        _ = feedbackEngine.analyze(for: .heartRateVariability)
        let sci = feedbackEngine.latestInsight(for: .heartRateVariability)?.score
        let bpm = recorder.currentHeartRate ?? CrooksCycleDefaults.nominalBPM
        let result = await pharmaControl.tickFromSCI(sciScore: sci, bpm: bpm)
        sigmaIrr = result.sigmaIrr
        crooksPhase = result.phase
        let snap = await pharmaControl.snapshot()
        crownBeta = snap.crownBeta

        // Direct apply covers listener race on first bind.
        if let beat = snap.beat {
            await musicService.applyBeatSync(beat)
        }

        // Grounding mood adapt must never block the pose/control timer (full crossfade).
        if result.didGround {
            Task { [weak self] in
                guard let self else { return }
                await self.musicService.adaptToSCI(
                    score: 0.2,
                    trend: .declining,
                    style: self.plan.style
                )
            }
        }
    }

    // MARK: - Adaptive Music

    /// Checks current SCI from FeedbackEngine and adapts music mood.
    /// Debounce is owned solely by `MusicService.adaptToSCI` (30s).
    private func adaptMusicToCurrentSCI() async {
        let insight = feedbackEngine.latestInsight(for: .heartRateVariability)
        await musicService.adaptToSCI(
            score: insight?.score,
            trend: insight?.trend ?? .stable,
            style: plan.style
        )
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
