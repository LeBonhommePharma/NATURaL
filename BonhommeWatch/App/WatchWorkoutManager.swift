import HealthKit
import Observation
import BonhommeCore

/// Manages the native watchOS HKWorkoutSession for direct wrist sensor access.
/// Provides higher-frequency HR data than the iOS relay path and computes
/// on-wrist SCI via the FeedbackEngine.
///
/// ## RR / SCI
/// BPM→RR is a **proxy** (`RRIntervalProxy.syntheticRR`) with light physiological jitter
/// so SCI is not stuck at 1.0 on constant BPM. Prefer real RR when HealthKit exposes it
/// (future heartbeat-series path); until then synthetic is documented as non-clinical.
@Observable
@MainActor
final class WatchWorkoutManager: NSObject {

    // MARK: - Published State

    private(set) var isRecording = false
    private(set) var isPaused = false
    private(set) var currentHeartRate: Double?
    private(set) var activeCalories: Double = 0
    private(set) var averageHeartRate: Double?
    private(set) var heartRateSamples: [HeartRateSample] = []
    /// Mirrors iOS `WorkoutFlowViewModel.posesCompletedCount` — only full holds.
    private(set) var posesCompletedCount: Int = 0
    private(set) var lastRRSource: RRIntervalSource = .synthetic

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
        isPaused = false

        let config = HKWorkoutConfiguration()
        config.activityType = .yoga
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
            maxHeartRate: heartRateSamples.map(\.bpm).max(),
            heartRateSamples: heartRateSamples
        )
    }

    /// Current biofeedback snapshot for WCSession relay to iOS.
    func buildBiofeedbackSnapshot() -> BiofeedbackSnapshot {
        let insights = feedbackEngine.analyzeAll()
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

    /// Ingest HR as HRV signals. BPM→RR is a **proxy** with light jitter (not clinical HRV).
    private func processHeartRateForSCI(bpm: Double) {
        _ = bpm
        let recentBPM = heartRateSamples.suffix(10).map(\.bpm)
        guard recentBPM.count >= 4 else { return }

        // Synthetic proxy with physiological noise so SCI is not stuck at 1.0.
        let recentRR = RRIntervalProxy.syntheticRR(fromBPMSamples: Array(recentBPM))
        lastRRSource = .synthetic
        guard !RRIntervalProxy.isMeaninglessForSCI(recentRR) else { return }

        let signal = HRVSignal(
            timestamp: Date(),
            sdnn: RRIntervalProxy.standardDeviation(recentRR),
            rmssd: RRIntervalProxy.rmssd(recentRR),
            rrIntervals: recentRR
        )
        feedbackEngine.ingest(signal)
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
