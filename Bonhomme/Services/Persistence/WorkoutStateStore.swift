import Foundation
import BonhommeCore

/// Persists in-progress workout state to UserDefaults so the app can resume
/// after being killed by the system (avoiding orphaned HealthKit sessions).
///
/// State is saved every 5 seconds during active workouts and on scene phase
/// transitions to background/inactive. On relaunch, the app checks for
/// persisted state and offers to resume.
struct WorkoutStateStore {
    private let defaults: UserDefaults
    private let key = "com.natural.activeWorkoutState"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Persisted State Model

    struct PersistedWorkoutState: Codable {
        let planId: String
        let phase: PersistedPhase
        let poseTimeRemaining: TimeInterval
        let elapsedTime: TimeInterval
        let sessionStartDate: Date
        let currentPoseIndex: Int
        let savedAt: Date

        /// Returns true if the state was saved less than 2 hours ago.
        var isRecoverable: Bool {
            Date().timeIntervalSince(savedAt) < 7200
        }
    }

    enum PersistedPhase: Codable {
        case ready
        case countdown(secondsRemaining: Int)
        case active(poseIndex: Int)
        case transition(nextPoseIndex: Int, secondsRemaining: Int)
        case cooldown
        case complete
    }

    // MARK: - Save

    func save(
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

        if let data = try? JSONEncoder().encode(state) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: - Load

    func load() -> PersistedWorkoutState? {
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

    /// Returns true if there's a recoverable workout in progress.
    var hasActiveWorkout: Bool {
        load() != nil
    }

    // MARK: - Clear

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

// MARK: - Plan Resolution

extension WorkoutStateStore.PersistedWorkoutState {
    /// Resolves the persisted plan ID back to a WorkoutPlan from the catalog.
    func resolvePlan() -> WorkoutPlan? {
        PoseCatalog.allPlans.first { $0.id == planId }
    }
}
