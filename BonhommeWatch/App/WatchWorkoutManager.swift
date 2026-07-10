import HealthKit
import Observation
import BonhommeCore

/// Manages the native watchOS HKWorkoutSession for direct wrist sensor access.
/// Provides higher-frequency HR data than the iOS relay path and computes
/// on-wrist SCI via the FeedbackEngine.
///
/// ## RR / SCI provenance (mirrors iOS `WorkoutRecorder`)
/// Prefer real beat-to-beat intervals from `HKHeartbeatSeriesSample` when HealthKit
/// has them (optical PPG on-wrist often writes series during workouts). Otherwise
/// BPM samples are converted via `RRIntervalProxy.syntheticRR` — a **non-clinical
/// proxy**, not beat-to-beat HRV. Light physiological jitter prevents SCI from
/// locking at 1.0 on constant BPM. Call sites / UI should treat `lastRRSource ==
/// .synthetic` as fitness biofeedback only; gate consumers on
/// `lastRRUsableForSCI` the same way phone gates adaptive music.
@Observable
@MainActor
final class WatchWorkoutManager: NSObject {

    // MARK: - Published State

    private(set) var isRecording = false
    private(set) var isPaused = false
    private(set) var currentHeartRate: Double?
    private(set) var activeCalories: Double = 0
    private(set) var averageHeartRate: Double?
    /// Peak BPM for the session (O(1); avoids full-buffer scan on result).
    private(set) var maxHeartRate: Double?
    private(set) var heartRateSamples: [HeartRateSample] = []
    /// Mirrors iOS `WorkoutFlowViewModel.posesCompletedCount` — only full holds.
    private(set) var posesCompletedCount: Int = 0
    /// Provenance of the last RR window used for on-wrist SCI.
    private(set) var lastRRSource: RRIntervalSource = .synthetic
    /// `false` when the last RR window is meaningless for SCI (near-constant),
    /// same gate as iOS `WorkoutRecorder.lastRRUsableForAdaptiveMusic`.
    private(set) var lastRRUsableForSCI: Bool = false

    /// Current phase in the workout flow.
    enum Phase: Equatable {
        case idle
        case active(poseIndex: Int)
        case transition(nextPoseIndex: Int, secondsRemaining: Int)
        case cooldown
        case complete
    }

    private(set) var phase: Phase = .idle
    private(set) var poseTimeRemaining: TimeInterval = 0
    private(set) var elapsedTime: TimeInterval = 0

    /// On-wrist SCI computation via the shared FeedbackEngine.
    let feedbackEngine = FeedbackEngine()
    private let hrvAnalyzer = HRVAnalyzer()

    // MARK: - Private

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var timerTask: Task<Void, Never>?
    private var sessionStartDate: Date?
    private var currentPlan: WorkoutPlan?
    /// Running sum for O(1) average HR.
    private var heartRateSum: Double = 0
    /// Cached real RR intervals (ms) from the most recent heartbeat series query.
    private var cachedRealRR: [Double] = []
    private var lastHeartbeatSeriesFetch: Date = .distantPast

    override init() {
        super.init()
        feedbackEngine.register(hrvAnalyzer)
    }

    // MARK: - Workout Lifecycle

    func start(plan: WorkoutPlan) async throws {
        currentPlan = plan
        sessionStartDate = Date()
        posesCompletedCount = 0
        heartRateSamples.removeAll(keepingCapacity: true)
        heartRateSum = 0
        maxHeartRate = nil
        averageHeartRate = nil
        currentHeartRate = nil
        isPaused = false
        cachedRealRR.removeAll(keepingCapacity: true)
        lastRRSource = .synthetic
        lastRRUsableForSCI = false
        lastHeartbeatSeriesFetch = .distantPast

        let config = HKWorkoutConfiguration()
        config.activityType = plan.style.healthKitActivityType
        config.locationType = .indoor

        session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
        session?.delegate = self

        builder = session?.associatedWorkoutBuilder()
        builder?.delegate = self
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: config
        )

        session?.startActivity(with: Date())
        try await builder?.beginCollection(at: Date())
        isRecording = true

        beginPose(at: 0)
    }

    func pause() {
        isPaused = true
        session?.pause()
        timerTask?.cancel()
    }

    func resume() {
        isPaused = false
        session?.resume()
        // Restore timers for every timer-bearing phase (not only .active).
        switch phase {
        case .active(let idx):
            if poseTimeRemaining > 0 {
                startPoseTimer(for: idx)
            } else {
                let next = idx + 1
                if let plan = currentPlan, next < plan.poses.count {
                    startTransition(to: next)
                } else {
                    phase = .cooldown
                    startCooldown()
                }
            }
        case .transition(let nextIdx, let secs):
            startTransition(to: nextIdx, remainingSeconds: secs)
        case .cooldown:
            startCooldown()
        default:
            break
        }
    }

    func end() async throws {
        timerTask?.cancel()
        session?.end()
        try await builder?.endCollection(at: Date())
        _ = try await builder?.finishWorkout()
        isRecording = false
        isPaused = false
        phase = .complete
    }

    // MARK: - Result

    func buildResult() -> WorkoutResult? {
        guard let plan = currentPlan else { return nil }

        return WorkoutResult(
            workoutPlanId: plan.id,
            workoutPlanName: plan.name.localized,
            startDate: sessionStartDate ?? Date(),
            endDate: Date(),
            totalDuration: elapsedTime,
            // Mirror iOS: explicit completed count, not poseIndex+1.
            posesCompleted: posesCompletedCount,
            totalPoses: plan.poseCount,
            activeCalories: activeCalories,
            averageHeartRate: averageHeartRate,
            maxHeartRate: maxHeartRate,
            heartRateSamples: heartRateSamples
        )
    }

    /// Current biofeedback snapshot for WCSession relay to iOS.
    func buildBiofeedbackSnapshot() -> BiofeedbackSnapshot {
        // 2s relay: HRV-only refresh, not full multi-analyzer analyzeAll.
        let insights = feedbackEngine.refreshHRVAndSnapshot()
        return BiofeedbackSnapshot(
            heartRate: currentHeartRate,
            activeCalories: activeCalories,
            feedbackInsights: insights
        )
    }

    // MARK: - Timer Logic

    private func beginPose(at index: Int) {
        guard let plan = currentPlan, index < plan.poses.count else {
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
        guard let plan = currentPlan else { return }
        timerTask?.cancel()
        timerTask = Task {
            while poseTimeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                poseTimeRemaining = max(0, poseTimeRemaining - 1)
                if let start = sessionStartDate {
                    elapsedTime = Date().timeIntervalSince(start)
                }
            }

            // Pose fully held — mirror iOS posesCompletedCount.
            posesCompletedCount += 1

            let nextIndex = index + 1
            if nextIndex < plan.poses.count {
                startTransition(to: nextIndex)
            } else {
                phase = .cooldown
                startCooldown()
            }
        }
    }

    private func startTransition(to nextIndex: Int, remainingSeconds: Int? = nil) {
        guard let plan = currentPlan else { return }
        timerTask?.cancel()
        timerTask = Task {
            let transitionDuration = remainingSeconds ?? Int(plan.transitionSeconds)
            for i in stride(from: max(1, transitionDuration), through: 1, by: -1) {
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
            try? await end()
        }
    }

    /// Prefer real heartbeat-series RR when cached; else BPM→RR **proxy** with light jitter.
    ///
    /// Pure-constant BPM→RR without jitter yields SCI≈1.0 and must not drive policy
    /// (`lastRRUsableForSCI` gates that path — same as phone adaptive music).
    /// Synthetic path is **non-clinical** fitness biofeedback only.
    private func processHeartRateForSCI(bpm: Double) {
        _ = bpm
        let recentBPM = heartRateSamples.suffix(10).map(\.bpm)
        guard recentBPM.count >= 4 else { return }

        let rr: [Double]
        let source: RRIntervalSource
        if cachedRealRR.count >= 4 {
            rr = Array(cachedRealRR.suffix(32))
            source = .real
        } else {
            // Proxy: BPM samples → RR ms with ~5% SDNN-scale jitter (not clinical HRV).
            rr = RRIntervalProxy.syntheticRR(fromBPMSamples: Array(recentBPM))
            source = .synthetic
        }

        lastRRSource = source
        // Gate consumers when RR variance is still negligible (pure-constant proxy).
        // Jittered synthetic is normally usable; real series always preferred.
        lastRRUsableForSCI = !RRIntervalProxy.isMeaninglessForSCI(rr)
        guard lastRRUsableForSCI else { return }

        let signal = HRVSignal(
            timestamp: Date(),
            sdnn: RRIntervalProxy.standardDeviation(rr),
            rmssd: RRIntervalProxy.rmssd(rr),
            rrIntervals: rr
        )
        feedbackEngine.ingest(signal)
    }

    /// Throttled fetch of recent `HKHeartbeatSeriesSample` beat-to-beat intervals.
    /// Mirrors iOS `WorkoutRecorder.refreshRealRRIfNeeded`.
    private func refreshRealRRIfNeeded() async {
        let now = Date()
        guard now.timeIntervalSince(lastHeartbeatSeriesFetch) >= 15 else { return }
        lastHeartbeatSeriesFetch = now

        let seriesType = HKSeriesType.heartbeat()
        let predicate = HKQuery.predicateForSamples(
            withStart: now.addingTimeInterval(-120),
            end: now,
            options: .strictStartDate
        )

        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            let sampleQuery = HKSampleQuery(
                sampleType: seriesType,
                predicate: predicate,
                limit: 3,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { [weak self] _, samples, _ in
                guard let self, let seriesSamples = samples as? [HKHeartbeatSeriesSample], !seriesSamples.isEmpty else {
                    cont.resume()
                    return
                }
                Task { @MainActor in
                    var intervals: [Double] = []
                    for series in seriesSamples {
                        if let beats = await self.fetchHeartbeatSeriesBeats(series) {
                            intervals.append(contentsOf: beats)
                        }
                    }
                    if intervals.count >= 4 {
                        self.cachedRealRR = Array(intervals.suffix(64))
                    }
                    cont.resume()
                }
            }
            healthStore.execute(sampleQuery)
        }
    }

    /// Returns beat-to-beat RR intervals in ms, or nil on error / empty.
    private func fetchHeartbeatSeriesBeats(_ series: HKHeartbeatSeriesSample) async -> [Double]? {
        await withCheckedContinuation { cont in
            var rr: [Double] = []
            var previous: TimeInterval?
            var settled = false
            let finish: ([Double]?) -> Void = { result in
                guard !settled else { return }
                settled = true
                cont.resume(returning: result)
            }
            let query = HKHeartbeatSeriesQuery(heartbeatSeries: series) { _, timeSinceSeriesStart, _, done, error in
                if error != nil {
                    finish(nil)
                    return
                }
                if let previous {
                    let deltaMs = (timeSinceSeriesStart - previous) * 1000.0
                    // Physiological RR band (~30–300 BPM); reject sensor gaps / noise.
                    if deltaMs > 200 && deltaMs < 2000 {
                        rr.append(deltaMs)
                    }
                }
                previous = timeSinceSeriesStart
                if done {
                    finish(rr.isEmpty ? nil : rr)
                }
            }
            healthStore.execute(query)
        }
    }
}

// MARK: - HKWorkoutSessionDelegate

extension WatchWorkoutManager: HKWorkoutSessionDelegate {
    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didChangeTo toState: HKWorkoutSessionState,
        from fromState: HKWorkoutSessionState,
        date: Date
    ) {}

    nonisolated func workoutSession(
        _ workoutSession: HKWorkoutSession,
        didFailWithError error: Error
    ) {}
}

// MARK: - HKLiveWorkoutBuilderDelegate

extension WatchWorkoutManager: HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutBuilder(
        _ workoutBuilder: HKLiveWorkoutBuilder,
        didCollectDataOf collectedTypes: Set<HKSampleType>
    ) {
        Task { @MainActor in
            for type in collectedTypes {
                guard let quantityType = type as? HKQuantityType else { continue }

                if quantityType == HKQuantityType(.heartRate) {
                    let stats = workoutBuilder.statistics(for: quantityType)
                    if let bpm = stats?.mostRecentQuantity()?
                        .doubleValue(for: .count().unitDivided(by: .minute())) {
                        currentHeartRate = bpm
                        heartRateSamples.append(HeartRateSample(bpm: bpm, timestamp: Date()))
                        heartRateSum += bpm
                        if let peak = maxHeartRate {
                            maxHeartRate = max(peak, bpm)
                        } else {
                            maxHeartRate = bpm
                        }
                        if heartRateSamples.count > 3600 + 64 {
                            let overflow = heartRateSamples.count - 3600
                            for i in 0..<overflow {
                                heartRateSum -= heartRateSamples[i].bpm
                            }
                            heartRateSamples.removeFirst(overflow)
                            heartRateSum = heartRateSamples.reduce(0.0) { $0 + $1.bpm }
                        }
                        let n = heartRateSamples.count
                        averageHeartRate = n > 0 ? heartRateSum / Double(n) : nil
                        processHeartRateForSCI(bpm: bpm)
                        // Opportunistically refresh real RR cache (throttled).
                        Task { await self.refreshRealRRIfNeeded() }
                    }
                    if let avg = stats?.averageQuantity()?
                        .doubleValue(for: .count().unitDivided(by: .minute())) {
                        averageHeartRate = avg
                    }
                }

                if quantityType == HKQuantityType(.activeEnergyBurned) {
                    let stats = workoutBuilder.statistics(for: quantityType)
                    if let cal = stats?.sumQuantity()?
                        .doubleValue(for: .kilocalorie()) {
                        activeCalories = cal
                    }
                }
            }
        }
    }

    nonisolated func workoutBuilderDidCollectEvent(
        _ workoutBuilder: HKLiveWorkoutBuilder
    ) {}
}
