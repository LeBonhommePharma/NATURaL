import Foundation

/// Material needed to rebuild a runnable restored workout session from local activity.
/// Pure data — no UI, HealthKit, or Music dependencies — so detect→load can be unit-tested.
public struct RestoredLocalSession: Sendable, Equatable {
    public let plan: WorkoutPlan
    public let phase: WorkoutStateStore.PersistedPhase
    public let poseTimeRemaining: TimeInterval
    public let elapsedTime: TimeInterval
    public let sessionStartDate: Date
    public let currentPoseIndex: Int
    /// Poses fully completed before the restored point (mirrors WorkoutFlowViewModel restore rules).
    public let posesCompletedCount: Int

    public init(
        plan: WorkoutPlan,
        phase: WorkoutStateStore.PersistedPhase,
        poseTimeRemaining: TimeInterval,
        elapsedTime: TimeInterval,
        sessionStartDate: Date,
        currentPoseIndex: Int,
        posesCompletedCount: Int
    ) {
        self.plan = plan
        self.phase = phase
        self.poseTimeRemaining = poseTimeRemaining
        self.elapsedTime = elapsedTime
        self.sessionStartDate = sessionStartDate
        self.currentPoseIndex = currentPoseIndex
        self.posesCompletedCount = posesCompletedCount
    }

    /// Builds a restored session from persisted state + resolved plan using the same phase mapping as the app restore path.
    public static func from(persisted: WorkoutStateStore.PersistedWorkoutState, plan: WorkoutPlan) -> RestoredLocalSession? {
        // Mirror WorkoutFlowViewModel.restoreIfAvailable: complete is unrestorable.
        if case .complete = persisted.phase { return nil }
        if case .ready = persisted.phase { return nil }

        let poseTimeRemaining: TimeInterval
        let posesCompletedCount: Int
        let currentPoseIndex: Int

        switch persisted.phase {
        case .ready:
            return nil
        case .countdown:
            poseTimeRemaining = persisted.poseTimeRemaining
            posesCompletedCount = 0
            currentPoseIndex = 0
        case .active(let idx):
            poseTimeRemaining = persisted.poseTimeRemaining
            posesCompletedCount = idx
            currentPoseIndex = idx
        case .transition(let nextIdx, _):
            // During transition, remaining time reflects the *next* pose's duration.
            poseTimeRemaining = plan.poses.indices.contains(nextIdx)
                ? plan.poses[nextIdx].durationSeconds
                : persisted.poseTimeRemaining
            posesCompletedCount = nextIdx
            currentPoseIndex = max(0, nextIdx - 1)
        case .cooldown:
            poseTimeRemaining = persisted.poseTimeRemaining
            posesCompletedCount = plan.poses.count
            currentPoseIndex = max(0, plan.poses.count - 1)
        case .complete:
            return nil
        }

        return RestoredLocalSession(
            plan: plan,
            phase: persisted.phase,
            poseTimeRemaining: poseTimeRemaining,
            elapsedTime: persisted.elapsedTime,
            sessionStartDate: persisted.sessionStartDate,
            currentPoseIndex: currentPoseIndex,
            posesCompletedCount: posesCompletedCount
        )
    }
}

/// Detects recoverable local in-progress workout activity and loads it into a session snapshot.
///
/// Detect and load are separable:
/// - `hasRecoverableActivity()` — pure presence check
/// - `loadIfAvailable()` — detect then build a restored session (nil when none)
public struct LocalActivitySessionLoader: @unchecked Sendable {
    public let store: WorkoutStateStore

    public init(store: WorkoutStateStore = WorkoutStateStore()) {
        self.store = store
    }

    /// Pure detect: true when recoverable local activity is present on device.
    public func hasRecoverableActivity() -> Bool {
        store.hasActiveWorkout
    }

    /// Detect then load: returns a restored session ready for the UI layer to present, or nil.
    public func loadIfAvailable() -> RestoredLocalSession? {
        guard let persisted = store.load(),
              let plan = persisted.resolvePlan(),
              let session = RestoredLocalSession.from(persisted: persisted, plan: plan) else {
            return nil
        }
        return session
    }

    /// Convenience: detect + load in one step for launch/active wiring.
    /// Equivalent to `loadIfAvailable()`; named for call-site clarity.
    public func detectAndLoad() -> RestoredLocalSession? {
        loadIfAvailable()
    }
}

// MARK: - Launch / become-active auto-load policy

/// Decision outcome for launch/scene-active auto-load (re-entrancy aware).
public enum LocalActivityAutoLoadDecision: Sendable, Equatable {
    /// A workout UI is already presenting — do not rebuild/auto-present a second session.
    case skipAlreadyPresenting
    /// No recoverable local activity (or load failed).
    case skipNoRecoverableActivity
    /// Safe to auto-load this restored session.
    case autoLoad(RestoredLocalSession)
}

/// Pure policy for whether launch/active should detect→load and auto-present.
/// Used by `AppState.detectAndAutoLoadLocalActivity` so re-entrancy is unit-testable.
public enum LocalActivityAutoLoadPolicy {
    /// Returns true only when no workout UI is already presenting.
    public static func shouldAttemptAutoLoad(isWorkoutAlreadyPresenting: Bool) -> Bool {
        !isWorkoutAlreadyPresenting
    }

    /// Full detect→load decision used on launch and scenePhase.active.
    /// When `isWorkoutAlreadyPresenting` is true, never loads — even if the store has recoverable state
    /// (e.g. 5s persist mid-session). This prevents duplicating a live workout on become-active.
    public static func decide(
        isWorkoutAlreadyPresenting: Bool,
        loader: LocalActivitySessionLoader
    ) -> LocalActivityAutoLoadDecision {
        guard shouldAttemptAutoLoad(isWorkoutAlreadyPresenting: isWorkoutAlreadyPresenting) else {
            return .skipAlreadyPresenting
        }
        guard let session = loader.detectAndLoad() else {
            return .skipNoRecoverableActivity
        }
        return .autoLoad(session)
    }

    /// Session to auto-load, or nil when auto-load must not run.
    public static func sessionToAutoLoad(
        isWorkoutAlreadyPresenting: Bool,
        loader: LocalActivitySessionLoader
    ) -> RestoredLocalSession? {
        if case .autoLoad(let session) = decide(
            isWorkoutAlreadyPresenting: isWorkoutAlreadyPresenting,
            loader: loader
        ) {
            return session
        }
        return nil
    }
}
