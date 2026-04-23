import Foundation

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
        let holdStart = setupDuration
        let holdEnd = duration - releaseDuration

        if elapsed < holdStart {
            let t = clamp01(elapsed / setupDuration)
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
            let t = clamp01((elapsed - holdEnd) / releaseDuration)
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
