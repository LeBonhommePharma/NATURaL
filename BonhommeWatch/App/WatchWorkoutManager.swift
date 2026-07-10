import HealthKit
import Observation
import BonhommeCore

/// Manages the native watchOS HKWorkoutSession for direct wrist sensor access.
/// Provides higher-frequency HR data than the iOS relay path and computes
/// on-wrist SCI via the FeedbackEngine.
@Observable
@MainActor
final class WatchWorkoutManager: NSObject {

    // MARK: - Published State

    private(set) var isRecording = false
    private(set) var currentHeartRate: Double?
    private(set) var activeCalories: Double = 0
    private(set) var averageHeartRate: Double?
    private(set) var heartRateSamples: [HeartRateSample] = []

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

    override init() {
        super.init()
        feedbackEngine.register(hrvAnalyzer)
    }

    // MARK: - Workout Lifecycle

    func start(plan: WorkoutPlan) async throws {
        currentPlan = plan
        sessionStartDate = Date()

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
        session?.pause()
        timerTask?.cancel()
    }

    func resume() {
        session?.resume()
        if case .active(let idx) = phase {
            startPoseTimer(for: idx)
        }
    }

    func end() async throws {
        timerTask?.cancel()
        session?.end()
        try await builder?.endCollection(at: Date())
        _ = try await builder?.finishWorkout()
        isRecording = false
        phase = .complete
    }

    // MARK: - Result

    func buildResult() -> WorkoutResult? {
        guard let plan = currentPlan else { return nil }
        let poseIndex: Int
        switch phase {
        case .active(let idx): poseIndex = idx
        case .transition(let nextIdx, _): poseIndex = max(0, nextIdx - 1)
        default: poseIndex = plan.poses.count - 1
        }

        return WorkoutResult(
            workoutPlanId: plan.id,
            workoutPlanName: plan.name.localized,
            startDate: sessionStartDate ?? Date(),
            endDate: Date(),
            totalDuration: elapsedTime,
            posesCompleted: poseIndex + 1,
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
        guard let plan = currentPlan else { return }
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
            try? await end()
        }
    }

    /// Ingest HR data as HRV signals for on-wrist SCI computation.
    private func processHeartRateForSCI(bpm: Double) {
        // Convert BPM to approximate RR interval in ms
        let rrInterval = 60000.0 / bpm
        // Build a synthetic HRV signal from recent HR samples
        let recentRR = heartRateSamples.suffix(10).map { 60000.0 / $0.bpm }
        guard recentRR.count >= 4 else { return }

        let signal = HRVSignal(
            timestamp: Date(),
            sdnn: standardDeviation(recentRR),
            rmssd: rmssd(recentRR),
            rrIntervals: recentRR
        )
        feedbackEngine.ingest(signal)
    }

    private func standardDeviation(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        return sqrt(squaredDiffs.reduce(0, +) / Double(values.count - 1))
    }

    private func rmssd(_ intervals: [Double]) -> Double {
        guard intervals.count >= 2 else { return 0 }
        var sumSquaredDiff = 0.0
        for i in 1..<intervals.count {
            let diff = intervals[i] - intervals[i - 1]
            sumSquaredDiff += diff * diff
        }
        return sqrt(sumSquaredDiff / Double(intervals.count - 1))
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
                        // Cap buffer (~1h @ 1Hz); batch-trim with slack to avoid O(n) every sample.
                        if heartRateSamples.count > 3600 + 64 {
                            heartRateSamples.removeFirst(heartRateSamples.count - 3600)
                        }
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
