import WatchConnectivity
import Observation
import BonhommeCore

/// WatchConnectivity bridge for relaying biofeedback data from Apple Watch
/// to the iOS hub. Sends real-time BiofeedbackSnapshot during workouts
/// and transfers WorkoutResult after session completion.
@Observable
@MainActor
final class WatchConnectivityBridge: NSObject {
    private(set) var isReachable = false
    private(set) var lastSyncDate: Date?

    private var wcSession: WCSession?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Minimum interval between real-time biofeedback sends (prevents flooding).
    private let sendInterval: TimeInterval = 2.0
    private var lastSendDate: Date = .distantPast

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

    // MARK: - Real-Time Biofeedback Relay

    /// Sends a BiofeedbackSnapshot to the paired iPhone in real-time.
    /// Throttled to one send per `sendInterval` seconds.
    /// Uses `sendMessage` for immediate delivery when reachable,
    /// falls back to `updateApplicationContext` otherwise.
    func sendBiofeedback(_ snapshot: BiofeedbackSnapshot) {
        let now = Date()
        guard now.timeIntervalSince(lastSendDate) >= sendInterval else { return }
        lastSendDate = now

        guard let data = try? encoder.encode(snapshot) else { return }
        let message: [String: Any] = [
            "type": "biofeedback",
            "data": data
        ]

        guard let session = wcSession else { return }

        if session.isReachable {
            session.sendMessage(message, replyHandler: nil) { [weak self] error in
                // If message send fails, fall back to application context
                Task { @MainActor in
                    self?.updateContext(with: snapshot)
                }
            }
        } else {
            updateContext(with: snapshot)
        }
    }

    /// Sends the current workout phase info for iOS status display.
    func sendWorkoutStatus(
        planName: String,
        phase: String,
        poseIndex: Int,
        totalPoses: Int,
        elapsedTime: TimeInterval
    ) {
        guard let session = wcSession else { return }

        let status: [String: Any] = [
            "type": "workoutStatus",
            "planName": planName,
            "phase": phase,
            "poseIndex": poseIndex,
            "totalPoses": totalPoses,
            "elapsedTime": elapsedTime
        ]

        if session.isReachable {
            session.sendMessage(status, replyHandler: nil)
        } else {
            try? session.updateApplicationContext(status)
        }
    }

    // MARK: - Background Result Transfer

    /// Transfers a completed WorkoutResult to iOS for persistence.
    /// Uses `transferUserInfo` for guaranteed background delivery.
    func transferWorkoutResult(_ result: WorkoutResult) {
        guard let data = try? encoder.encode(result),
              let session = wcSession else { return }

        let userInfo: [String: Any] = [
            "type": "workoutResult",
            "data": data
        ]

        session.transferUserInfo(userInfo)
        lastSyncDate = Date()
    }

    // MARK: - Application Context

    private func updateContext(with snapshot: BiofeedbackSnapshot) {
        guard let data = try? encoder.encode(snapshot),
              let session = wcSession else { return }

        try? session.updateApplicationContext([
            "type": "biofeedback",
            "data": data
        ])
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityBridge: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            isReachable = session.isReachable
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        // Handle messages from iOS (e.g., start/stop commands)
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

    @MainActor
    private func handleIncomingMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "ping":
            // iOS checking if watch is available
            break
        case "startWorkout":
            // iOS requesting watch to start a workout
            // The WatchHomeView handles this via notification
            NotificationCenter.default.post(
                name: .watchStartWorkoutRequested,
                object: nil,
                userInfo: message
            )
        case "stopWorkout":
            NotificationCenter.default.post(
                name: .watchStopWorkoutRequested,
                object: nil
            )
        default:
            break
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchStartWorkoutRequested = Notification.Name("natural.watch.startWorkout")
    static let watchStopWorkoutRequested = Notification.Name("natural.watch.stopWorkout")
}
