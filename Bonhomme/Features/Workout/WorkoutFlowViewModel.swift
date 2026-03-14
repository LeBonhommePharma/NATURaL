import SwiftUI
import Observation
import BonhommeCore

/// State machine driving the guided pose-by-pose workout experience.
@Observable
@MainActor
final class WorkoutFlowViewModel {

    // MARK: - Phase

    enum Phase: Equatable {
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
    let feedbackEngine = FeedbackEngine()
    private let hrvAnalyzer = HRVAnalyzer()
    private let medicationAnalyzer = MedicationAnalyzer()

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

    init(plan: WorkoutPlan) {
        self.plan = plan
        feedbackEngine.register(hrvAnalyzer)
        feedbackEngine.register(medicationAnalyzer)
    }

    // MARK: - Controls

    func start() {
        sessionStartDate = Date()
        phase = .countdown(secondsRemaining: 3)
        startCountdownSequence()
    }

    func pause() {
        recorder.pause()
        timerTask?.cancel()
    }

    func resume() {
        recorder.resume()
        if case .active(let idx) = phase {
            startPoseTimer(for: idx)
        }
    }

    func stop() {
        timerTask?.cancel()
        phase = .complete
        Task {
            try? await recorder.end()
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
        WorkoutResult(
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
            heartRateSamples: recorder.heartRateSamples
        )
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

            // Start HealthKit recording
            try? await recorder.start()

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
            try? await recorder.end()
            phase = .complete
        }
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
