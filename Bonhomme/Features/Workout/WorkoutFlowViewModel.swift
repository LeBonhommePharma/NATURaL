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

    /// Tracks whether this session was restored from a killed app.
    private(set) var isRestoredSession = false

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
    private var lastMusicAdaptation: Date = .distantPast
    private var liveActivity: Activity<WorkoutActivityAttributes>?

    init(plan: WorkoutPlan, feedbackEngine: FeedbackEngine = FeedbackEngine()) {
        self.plan = plan
        self.feedbackEngine = feedbackEngine
    }

    // MARK: - State Restoration

    /// Attempt to restore a killed-app workout session.
    /// Returns a configured ViewModel if recoverable state exists, nil otherwise.
    static func restoreIfAvailable(feedbackEngine: FeedbackEngine = FeedbackEngine()) -> WorkoutFlowViewModel? {
        let store = WorkoutStateStore()
        guard let persisted = store.load(),
              let plan = persisted.resolvePlan() else {
            return nil
        }

        let vm = WorkoutFlowViewModel(plan: plan, feedbackEngine: feedbackEngine)
        vm.isRestoredSession = true
        vm.sessionStartDate = persisted.sessionStartDate
        vm.elapsedTime = persisted.elapsedTime
        vm.poseTimeRemaining = persisted.poseTimeRemaining

        // Map persisted phase back to VM phase
        switch persisted.phase {
        case .ready:
            vm.phase = .ready
        case .countdown(let secs):
            vm.phase = .countdown(secondsRemaining: secs)
        case .active(let idx):
            vm.phase = .active(poseIndex: idx)
        case .transition(let nextIdx, let secs):
            vm.phase = .transition(nextPoseIndex: nextIdx, secondsRemaining: secs)
        case .cooldown:
            vm.phase = .cooldown
        case .complete:
            store.clear()
            return nil
        }

        return vm
    }

    /// Resume a restored session: reconnect to the HealthKit workout session
    /// and restart timers from the persisted state.
    func resumeRestoredSession() {
        guard isRestoredSession else { return }

        Task {
            // Attempt to recover the existing HealthKit workout session
            await recoverHealthKitSession()

            // Resume at the current phase
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
            try await recorder.start()
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
        sessionStartDate = Date()
        phase = .countdown(secondsRemaining: 3)
        startCountdownSequence()
    }

    func pause() {
        recorder.pause()
        musicService.pause()
        timerTask?.cancel()
        persistState()
    }

    func resume() {
        recorder.resume()
        Task { await musicService.playWorkoutMusic(mood: musicService.adaptiveMood, style: plan.style) }
        if case .active(let idx) = phase {
            startPoseTimer(for: idx)
        }
    }

    func stop() {
        timerTask?.cancel()
        phase = .complete
        stateStore.clear()
        musicService.stop()
        endLiveActivity()
        Task {
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
            isPaused: false,
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
            posesCompleted: currentPoseIndex + 1,
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

            // Start HealthKit recording with style-aware activity type
            try? await recorder.start(style: plan.style)

            // Start adaptive music with style-aware playlists
            await musicService.requestAuthorization()
            await musicService.playWorkoutMusic(mood: .calm, style: plan.style)

            // Start Live Activity for Dynamic Island
            startLiveActivity()

            // Begin first pose
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

                // Periodic state persistence (every 5 seconds)
                persistenceCounter += 1
                if persistenceCounter % 5 == 0 {
                    persistState()
                    await adaptMusicToCurrentSCI()
                }
            }

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
            phase = .complete
        }
    }

    // MARK: - Adaptive Music

    /// Checks current SCI from FeedbackEngine and adapts music mood.
    /// Debounced to minimum 30-second intervals.
    private func adaptMusicToCurrentSCI() async {
        let now = Date()
        guard now.timeIntervalSince(lastMusicAdaptation) >= 30 else { return }

        let insight = feedbackEngine.latestInsight(for: .heartRateVariability)
        await musicService.adaptToSCI(score: insight?.score, trend: insight?.trend ?? .stable, style: plan.style)
        lastMusicAdaptation = now
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
