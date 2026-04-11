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
        guard WCSession.isSupported() else {
            print("⚠️ WatchConnectivity is not supported on this device")
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        
        // FIX: Check if session is already activated to prevent pairing ID conflicts
        if session.activationState == .activated {
            print("✅ WCSession already activated")
            wcSession = session
            isReachable = session.isReachable
            return
        }
        
        session.activate()
        wcSession = session
        print("🔄 WCSession activation requested")
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
            "type": WCMessageType.biofeedback.rawValue,
            "data": data.base64EncodedString()
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
            "type": WCMessageType.workoutStatus.rawValue,
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
            "type": WCMessageType.workoutResult.rawValue,
            "data": data.base64EncodedString()
        ]

        session.transferUserInfo(userInfo)
        lastSyncDate = Date()
    }

    // MARK: - Application Context

    private func updateContext(with snapshot: BiofeedbackSnapshot) {
        guard let data = try? encoder.encode(snapshot),
              let session = wcSession else { return }

        try? session.updateApplicationContext([
            "type": WCMessageType.biofeedback.rawValue,
            "data": data.base64EncodedString()
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
            if let error = error {
                print("❌ WCSession activation failed: \(error.localizedDescription)")
                isReachable = false
                return
            }
            
            switch activationState {
            case .activated:
                print("✅ WCSession activated successfully")
                isReachable = session.isReachable
                if !session.isReachable {
                    print("⚠️ Watch is not reachable (may be disconnected or out of range)")
                }
            case .inactive:
                print("⚠️ WCSession is inactive")
                isReachable = false
            case .notActivated:
                print("⚠️ WCSession is not activated")
                isReachable = false
            @unknown default:
                print("⚠️ WCSession unknown activation state")
                isReachable = false
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            if session.isReachable {
                print("✅ Watch became reachable")
            } else {
                print("⚠️ Watch became unreachable")
            }
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
        guard let typeRaw = message["type"] as? String,
              let type = WCMessageType(rawValue: typeRaw) else { return }

        switch type {
        case .ping:
            break
        case .startWorkout:
            NotificationCenter.default.post(
                name: .watchStartWorkoutRequested,
                object: nil,
                userInfo: message
            )
        case .stopWorkout:
            NotificationCenter.default.post(
                name: .watchStopWorkoutRequested,
                object: nil
            )
        default:
            break
        }
    }
}

// MARK: - Shared Message Types

/// Type-safe message types for WatchConnectivity communication.
/// Shared between watch and phone bridges to prevent string typos.
enum WCMessageType: String {
    case biofeedback
    case workoutStatus
    case workoutResult
    case ping
    case startWorkout
    case stopWorkout
}

// MARK: - Notification Names

extension Notification.Name {
    static let watchStartWorkoutRequested = Notification.Name("natural.watch.startWorkout")
    static let watchStopWorkoutRequested = Notification.Name("natural.watch.stopWorkout")
}
