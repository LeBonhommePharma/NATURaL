import Foundation

/// Persists in-progress workout state to UserDefaults so the app can resume
/// after being killed by the system (avoiding orphaned HealthKit sessions).
///
/// State is saved every 5 seconds during active workouts and on scene phase
/// transitions to background/inactive. On relaunch, the app detects recoverable
/// local activity and loads the session automatically.
public struct WorkoutStateStore: @unchecked Sendable {
    // UserDefaults is thread-safe for typical read/write of our single key; marked unchecked
    // so the store can be passed across isolation boundaries without false Swift 6 errors.
    private let defaults: UserDefaults
    /// Stable key used for local in-progress session persistence.
    public static let storageKey = "com.natural.activeWorkoutState"

    private var key: String { Self.storageKey }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Persisted State Model

    public struct PersistedWorkoutState: Codable, Sendable, Equatable {
        public let planId: String
        public let phase: PersistedPhase
        public let poseTimeRemaining: TimeInterval
        public let elapsedTime: TimeInterval
        public let sessionStartDate: Date
        public let currentPoseIndex: Int
        public let savedAt: Date

        public init(
            planId: String,
            phase: PersistedPhase,
            poseTimeRemaining: TimeInterval,
            elapsedTime: TimeInterval,
            sessionStartDate: Date,
            currentPoseIndex: Int,
            savedAt: Date = Date()
        ) {
            self.planId = planId
            self.phase = phase
            self.poseTimeRemaining = poseTimeRemaining
            self.elapsedTime = elapsedTime
            self.sessionStartDate = sessionStartDate
            self.currentPoseIndex = currentPoseIndex
            self.savedAt = savedAt
        }

        /// Returns true if the state was saved less than 2 hours ago.
        public var isRecoverable: Bool {
            Date().timeIntervalSince(savedAt) < 7200
        }
    }

    public enum PersistedPhase: Codable, Sendable, Equatable {
        case ready
        case countdown(secondsRemaining: Int)
        case active(poseIndex: Int)
        case transition(nextPoseIndex: Int, secondsRemaining: Int)
        case cooldown
        case complete
    }

    // MARK: - Save

    public func save(
        planId: String,
        phase: PersistedPhase,
        poseTimeRemaining: TimeInterval,
        elapsedTime: TimeInterval,
        sessionStartDate: Date,
        currentPoseIndex: Int
    ) {
        let state = PersistedWorkoutState(
            planId: planId,
            phase: phase,
            poseTimeRemaining: poseTimeRemaining,
            elapsedTime: elapsedTime,
            sessionStartDate: sessionStartDate,
            currentPoseIndex: currentPoseIndex,
            savedAt: Date()
        )
        saveState(state)
    }

    /// Saves a fully-formed state (including custom `savedAt` for tests / migration).
    public func saveState(_ state: PersistedWorkoutState) {
        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: - Load

    /// Loads recoverable local activity, or returns nil (and clears) when absent/expired/unrestorable.
    public func load() -> PersistedWorkoutState? {
        guard let data = defaults.data(forKey: key),
              let state = try? JSONDecoder().decode(PersistedWorkoutState.self, from: data),
              state.isRecoverable else {
            clear()
            return nil
        }

        // Don't restore completed or ready states
        switch state.phase {
        case .complete, .ready:
            clear()
            return nil
        default:
            return state
        }
    }

    /// Returns true if there's a recoverable workout in progress (detect without consuming intent).
    public var hasActiveWorkout: Bool {
        // Peek without double-clear: load() is the single source of truth for recoverability.
        load() != nil
    }

    // MARK: - Clear

    public func clear() {
        defaults.removeObject(forKey: key)
    }
}

// MARK: - Plan Resolution

extension WorkoutStateStore.PersistedWorkoutState {
    /// Resolves the persisted plan ID back to a WorkoutPlan from the catalog.
    public func resolvePlan() -> WorkoutPlan? {
        PoseCatalog.allPlans.first { $0.id == planId }
    }
}
