import Foundation

public enum MotionCoachPhase: Sendable {
    case preview
    case active
    case transition
}

/// A pause-aware animation clock. No wall-clock phase jumps on resume.
struct MotionCoachPlaybackClock {
    private var origin: Date
    private var pausedAt: Date?
    private var pausedDuration: TimeInterval = 0

    init(now: Date = Date()) { origin = now }

    func time(at now: Date) -> TimeInterval {
        max(0, (pausedAt ?? now).timeIntervalSince(origin) - pausedDuration)
    }

    mutating func setPaused(_ paused: Bool, at now: Date) {
        if paused, pausedAt == nil { pausedAt = now }
        if !paused, let start = pausedAt {
            pausedDuration += max(0, now.timeIntervalSince(start))
            pausedAt = nil
        }
    }
}

public struct AnimationPhaseState: Sendable {
    public enum Phase: Sendable {
        case setup
        case hold
        case release
    }

    public var phase: Phase
    public var progress: Double
    public var poseBlend: Double
    public var oscillationBlend: Double

    /// A fully formed pose without setup/release animation or idle oscillation.
    public static let still = AnimationPhaseState(phase: .hold, progress: 1, poseBlend: 1, oscillationBlend: 0)

    public static let neutral = AnimationPhaseState(
        phase: .hold,
        progress: 1.0,
        poseBlend: 0.0,
        oscillationBlend: 0.3
    )

    public static func compute(
        elapsed: TimeInterval,
        duration: TimeInterval,
        setupDuration: TimeInterval = 3.0,
        releaseDuration: TimeInterval = 2.0
    ) -> AnimationPhaseState {
        guard duration.isFinite, duration > 0 else { return .still }
        let elapsed = elapsed.isFinite ? max(0, elapsed) : 0
        let setup = setupDuration.isFinite ? max(0, setupDuration) : 0
        let release = releaseDuration.isFinite ? max(0, releaseDuration) : 0
        let scale = min(1, duration / max(setup + release, 0.001))
        let holdStart = setup * scale
        let releaseLength = release * scale
        let holdEnd = duration - releaseLength

        if elapsed < holdStart {
            let t = clamp01(elapsed / holdStart)
            let eased = quinticEase(t)
            return AnimationPhaseState(
                phase: .setup,
                progress: t,
                poseBlend: eased,
                oscillationBlend: eased * 0.4
            )
        } else if elapsed < holdEnd {
            return AnimationPhaseState(
                phase: .hold,
                progress: clamp01((elapsed - holdStart) / max(holdEnd - holdStart, 0.1)),
                poseBlend: 1.0,
                oscillationBlend: 1.0
            )
        } else {
            let t = clamp01(releaseLength > 0 ? (elapsed - holdEnd) / releaseLength : 1)
            let eased = 1.0 - quinticEase(t)
            return AnimationPhaseState(
                phase: .release,
                progress: t,
                poseBlend: eased,
                oscillationBlend: eased * 0.6
            )
        }
    }

    public static func compute(
        elapsed: TimeInterval,
        duration: TimeInterval,
        phase: MotionCoachPhase
    ) -> AnimationPhaseState {
        switch phase {
        case .preview:
            return AnimationPhaseState(
                phase: .hold,
                progress: 0.5,
                poseBlend: 0.7,
                oscillationBlend: 0.5
            )
        case .active:
            return compute(elapsed: elapsed, duration: duration)
        case .transition:
            return AnimationPhaseState(
                phase: .release,
                progress: 0.5,
                poseBlend: 0.6,
                oscillationBlend: 0.3
            )
        }
    }
}

private func clamp01(_ v: Double) -> Double {
    max(0, min(1, v))
}

private func quinticEase(_ t: Double) -> Double {
    let s = clamp01(t)
    return s * s * s * (s * (s * 6.0 - 15.0) + 10.0)
}
