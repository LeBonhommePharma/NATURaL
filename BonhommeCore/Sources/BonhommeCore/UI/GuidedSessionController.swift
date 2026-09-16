import Foundation
import Observation

/// Timer-driven guided session for platforms without HealthKit (Mac, and any
/// local preview). Does not record workouts or drive music/control actuators.
@Observable
@MainActor
public final class GuidedSessionController {
    public enum Phase: Equatable, Sendable {
        case ready
        case active(poseIndex: Int)
        case transition(nextPoseIndex: Int, secondsRemaining: Int)
        case complete
    }

    public let plan: WorkoutPlan
    public let feedbackEngine: FeedbackEngine

    public private(set) var phase: Phase = .ready
    public private(set) var poseTimeRemaining: TimeInterval = 0
    public private(set) var elapsedTime: TimeInterval = 0
    public private(set) var isPaused = false
    public private(set) var posesCompletedCount = 0

    public var currentPose: Pose? {
        switch phase {
        case .active(let idx): return plan.poses[safe: idx]
        case .transition(let next, _): return plan.poses[safe: max(0, next - 1)]
        default: return nil
        }
    }

    public var currentPoseIndex: Int {
        switch phase {
        case .active(let idx): return idx
        case .transition(let next, _): return max(0, next - 1)
        default: return 0
        }
    }

    public var hudMetrics: SessionHUDMetrics {
        let insight = feedbackEngine.latestInsight(for: .heartRateVariability)
        return SessionHUDMetrics(
            sciScore: insight?.score,
            sciTrend: insight?.trend.asSCITrend ?? .stable,
            heartRate: nil,
            tempoBPM: plan.style.nominalBPM,
            isPaused: isPaused,
            elapsed: elapsedTime,
            poseIndex: currentPoseIndex,
            poseCount: plan.poseCount
        )
    }

    private var timerTask: Task<Void, Never>?
    private var elapsedAnchor: Date?

    public init(plan: WorkoutPlan, feedbackEngine: FeedbackEngine = FeedbackEngine()) {
        self.plan = plan
        self.feedbackEngine = feedbackEngine
        feedbackEngine.register(HRVAnalyzer())
    }

    public func start() {
        guard phase == .ready || phase == .complete else { return }
        posesCompletedCount = 0
        elapsedTime = 0
        isPaused = false
        elapsedAnchor = Date()
        beginPose(at: 0)
    }

    public func pause() {
        guard !isPaused, phase != .ready, phase != .complete else { return }
        isPaused = true
        timerTask?.cancel()
        updateElapsed()
        elapsedAnchor = nil
    }

    public func resume() {
        guard isPaused else { return }
        isPaused = false
        elapsedAnchor = Date()
        switch phase {
        case .active(let idx): startPoseTimer(for: idx)
        case .transition(let next, let seconds): startTransition(to: next, remaining: seconds)
        default: break
        }
    }

    public func stop() {
        timerTask?.cancel()
        isPaused = false
        elapsedAnchor = nil
        phase = .complete
    }

    public func reset() {
        timerTask?.cancel()
        isPaused = false
        elapsedAnchor = nil
        elapsedTime = 0
        posesCompletedCount = 0
        poseTimeRemaining = 0
        phase = .ready
    }

    private func beginPose(at index: Int) {
        guard index < plan.poses.count else {
            phase = .complete
            timerTask?.cancel()
            return
        }
        poseTimeRemaining = plan.poses[index].durationSeconds
        phase = .active(poseIndex: index)
        startPoseTimer(for: index)
    }

    private func startPoseTimer(for index: Int) {
        timerTask?.cancel()
        timerTask = Task {
            while poseTimeRemaining > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, !isPaused else { return }
                poseTimeRemaining = max(0, poseTimeRemaining - 1)
                updateElapsed()
            }
            posesCompletedCount += 1
            let next = index + 1
            if next < plan.poses.count {
                startTransition(to: next, remaining: Int(plan.transitionSeconds))
            } else {
                phase = .complete
            }
        }
    }

    private func startTransition(to nextIndex: Int, remaining: Int) {
        timerTask?.cancel()
        timerTask = Task {
            for seconds in stride(from: max(1, remaining), through: 1, by: -1) {
                phase = .transition(nextPoseIndex: nextIndex, secondsRemaining: seconds)
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled, !isPaused else { return }
                updateElapsed()
            }
            beginPose(at: nextIndex)
        }
    }

    private func updateElapsed() {
        guard let elapsedAnchor else { return }
        let now = Date()
        elapsedTime += max(0, now.timeIntervalSince(elapsedAnchor))
        self.elapsedAnchor = now
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
