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
    public private(set) var endedEarly = false
    /// A long scheduling/sleep gap requires an explicit resume; no unseen poses are counted.
    public private(set) var pausedForSuspension = false

    public var upcomingPose: Pose? {
        guard case .transition(let next, _) = phase else { return nil }
        return plan.poses[safe: next]
    }

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
        case .complete: return lastPoseIndex
        case .ready: return 0
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

    @ObservationIgnored private var timerTask: Task<Void, Never>?
    @ObservationIgnored private let clock: @MainActor () -> TimeInterval
    @ObservationIgnored private let automaticallyTicks: Bool
    @ObservationIgnored private var lastTick: TimeInterval?
    private var transitionTimeRemaining: TimeInterval = 0
    private var lastPoseIndex = 0

    // A 250 ms timer may occasionally be delayed; a multi-second gap means the
    // guided presentation was interrupted. Freeze instead of replaying that gap.
    static let suspensionThreshold: TimeInterval = 3

    public convenience init(plan: WorkoutPlan, feedbackEngine: FeedbackEngine = FeedbackEngine()) {
        let origin = ContinuousClock.now
        self.init(plan: plan, feedbackEngine: feedbackEngine, clock: {
            let components = origin.duration(to: ContinuousClock.now).components
            return Double(components.seconds) + Double(components.attoseconds) / 1e18
        }, automaticallyTicks: true)
    }

    /// Internal deterministic seam: tests advance the monotonic clock and call tick().
    init(plan: WorkoutPlan, feedbackEngine: FeedbackEngine = FeedbackEngine(),
         clock: @escaping @MainActor () -> TimeInterval, automaticallyTicks: Bool) {
        self.plan = plan
        self.feedbackEngine = feedbackEngine
        self.clock = clock
        self.automaticallyTicks = automaticallyTicks
        feedbackEngine.register(HRVAnalyzer())
    }

    deinit { timerTask?.cancel() }

    public func start() {
        guard phase == .ready || phase == .complete else { return }
        cancelTimer()
        posesCompletedCount = 0
        endedEarly = false
        pausedForSuspension = false
        elapsedTime = 0
        isPaused = false
        lastPoseIndex = 0
        lastTick = clock()
        beginPose(at: 0)
        advance(by: 0) // Resolve empty/zero-duration poses and transitions immediately.
        startTimer()
    }

    public func pause() {
        guard !isPaused, isRunning else { return }
        tick()
        guard isRunning else { return }
        isPaused = true
        cancelTimer()
        lastTick = nil
    }

    public func resume() {
        guard isPaused, isRunning else { return }
        isPaused = false
        pausedForSuspension = false
        lastTick = clock()
        startTimer()
    }

    public func stop() {
        guard isRunning else { return }
        tick()
        guard isRunning else { return } // The final pose may have just finished.
        endedEarly = posesCompletedCount < plan.poseCount
        finish()
    }

    public func reset() {
        cancelTimer()
        isPaused = false
        pausedForSuspension = false
        lastTick = nil
        elapsedTime = 0
        posesCompletedCount = 0
        poseTimeRemaining = 0
        transitionTimeRemaining = 0
        lastPoseIndex = 0
        endedEarly = false
        phase = .ready
    }

    private var isRunning: Bool {
        switch phase {
        case .active, .transition: return true
        case .ready, .complete: return false
        }
    }

    /// Apply actual monotonic elapsed time, never the number of timer callbacks.
    func tick() {
        guard isRunning, !isPaused, let previous = lastTick else { return }
        let now = clock()
        let delta = now - previous
        guard now.isFinite, delta.isFinite, delta >= 0,
              delta <= Self.suspensionThreshold else {
            isPaused = true
            pausedForSuspension = true
            lastTick = nil
            cancelTimer()
            return
        }
        lastTick = now
        advance(by: delta)
    }

    private func advance(by interval: TimeInterval) {
        var unconsumed = interval
        while isRunning {
            switch phase {
            case .active(let index):
                let consumed = min(poseTimeRemaining, unconsumed)
                poseTimeRemaining -= consumed
                elapsedTime += consumed
                unconsumed -= consumed
                guard poseTimeRemaining <= 0 else { return }
                posesCompletedCount = index + 1
                let next = index + 1
                guard next < plan.poses.count else {
                    finish()
                    return
                }
                transitionTimeRemaining = Self.validDuration(plan.transitionSeconds)
                phase = .transition(nextPoseIndex: next, secondsRemaining: transitionSeconds)
            case .transition(let next, _):
                let consumed = min(transitionTimeRemaining, unconsumed)
                transitionTimeRemaining -= consumed
                elapsedTime += consumed
                unconsumed -= consumed
                if transitionTimeRemaining > 0 {
                    phase = .transition(nextPoseIndex: next, secondsRemaining: transitionSeconds)
                    return
                }
                beginPose(at: next)
            case .ready, .complete:
                return
            }
        }
    }

    private var transitionSeconds: Int {
        Int(exactly: transitionTimeRemaining.rounded(.up)) ?? Int.max
    }

    private static func validDuration(_ seconds: TimeInterval) -> TimeInterval {
        seconds.isFinite && seconds > 0 ? seconds : 0
    }

    private func beginPose(at index: Int) {
        guard plan.poses.indices.contains(index) else {
            finish()
            return
        }
        lastPoseIndex = index
        poseTimeRemaining = Self.validDuration(plan.poses[index].durationSeconds)
        phase = .active(poseIndex: index)
    }

    private func finish() {
        cancelTimer()
        lastTick = nil
        isPaused = false
        pausedForSuspension = false
        phase = .complete
    }

    private func cancelTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func startTimer() {
        guard automaticallyTicks, isRunning, !isPaused else { return }
        cancelTimer()
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(250)) }
                catch { return }
                guard !Task.isCancelled, self?.handleTimerTick() == true else { return }
            }
        }
    }

    // Keep a strong reference only for synchronous work, never across Task.sleep.
    private func handleTimerTick() -> Bool {
        tick()
        return isRunning && !isPaused
    }

}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
