import WatchConnectivity
import Observation
import BonhommeCore

/// iOS-side WatchConnectivity bridge that receives biofeedback data from
/// the Apple Watch companion app and forwards it to the TVDisplayCoordinator.
@Observable
@MainActor
final class PhoneConnectivityBridge: NSObject {
    /// Latest biofeedback snapshot received from the watch.
    private(set) var latestSnapshot: BiofeedbackSnapshot?

    /// Latest workout status from the watch.
    private(set) var watchWorkoutStatus: WatchWorkoutStatus?

    /// Whether the watch is currently reachable.
    private(set) var isWatchReachable = false

    /// Whether a watch workout session was completed and needs processing.
    private(set) var pendingWorkoutResult: WorkoutResult?

    private var wcSession: WCSession?
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    struct WatchWorkoutStatus {
        let planName: String
        let phase: String
        let poseIndex: Int
        let totalPoses: Int
        let elapsedTime: TimeInterval
    }

    override init() {
        super.init()
        activateSession()
    }

    // MARK: - Session Activation

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
        wcSession = session
    }

    // MARK: - Commands to Watch

    /// Requests the watch to start a specific workout plan.
    func requestWatchWorkout(planId: String) {
        guard let session = wcSession, session.isReachable else { return }

        session.sendMessage([
            "type": "startWorkout",
            "planId": planId
        ], replyHandler: nil)
    }

    /// Requests the watch to stop the current workout.
    func requestWatchStop() {
        guard let session = wcSession, session.isReachable else { return }

        session.sendMessage([
            "type": "stopWorkout"
        ], replyHandler: nil)
    }

    /// Pings the watch to check connectivity.
    func pingWatch() {
        guard let session = wcSession, session.isReachable else {
            isWatchReachable = false
            return
        }

        session.sendMessage(["type": "ping"], replyHandler: { _ in
            Task { @MainActor in
                self.isWatchReachable = true
            }
        }, errorHandler: { _ in
            Task { @MainActor in
                self.isWatchReachable = false
            }
        })
    }

    /// Clears the pending workout result after it's been processed.
    func clearPendingResult() {
        pendingWorkoutResult = nil
    }
}

// MARK: - WCSessionDelegate

extension PhoneConnectivityBridge: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate for future pairing
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
        }
    }

    // MARK: - Receive Messages

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        Task { @MainActor in
            handleIncomingMessage(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            handleIncomingMessage(message)
            replyHandler(["status": "ok"])
        }
    }

    // MARK: - Receive User Info (Background Transfer)

    nonisolated func session(
        _ session: WCSession,
        didReceiveUserInfo userInfo: [String: Any] = [:]
    ) {
        Task { @MainActor in
            handleUserInfo(userInfo)
        }
    }

    // MARK: - Receive Application Context

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            handleIncomingMessage(applicationContext)
        }
    }

    // MARK: - Message Handling

    @MainActor
    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "biofeedback":
            if let data = message["data"] as? Data,
               let snapshot = try? decoder.decode(BiofeedbackSnapshot.self, from: data) {
                latestSnapshot = snapshot
            }

        case "workoutStatus":
            if let planName = message["planName"] as? String,
               let phase = message["phase"] as? String,
               let poseIndex = message["poseIndex"] as? Int,
               let totalPoses = message["totalPoses"] as? Int,
               let elapsed = message["elapsedTime"] as? TimeInterval {
                watchWorkoutStatus = WatchWorkoutStatus(
                    planName: planName,
                    phase: phase,
                    poseIndex: poseIndex,
                    totalPoses: totalPoses,
                    elapsedTime: elapsed
                )
            }

        default:
            break
        }
    }

    @MainActor
    private func handleUserInfo(_ userInfo: [String: Any]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "workoutResult":
            if let data = userInfo["data"] as? Data,
               let result = try? decoder.decode(WorkoutResult.self, from: data) {
                pendingWorkoutResult = result
            }

        default:
            break
        }
    }
}
