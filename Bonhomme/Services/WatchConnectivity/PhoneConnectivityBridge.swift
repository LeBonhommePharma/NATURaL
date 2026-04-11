import WatchConnectivity
import Observation
import BonhommeCore

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
        guard WCSession.isSupported() else {
            print("⚠️ WatchConnectivity is not supported on this device")
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        
        // Check if session is already activated to prevent pairing ID conflicts
        if session.activationState == .activated {
            print("✅ WCSession already activated (iOS)")
            wcSession = session
            isWatchReachable = session.isReachable
            return
        }
        
        session.activate()
        wcSession = session
        print("🔄 WCSession activation requested (iOS)")
    }

    // MARK: - Commands to Watch

    /// Requests the watch to start a specific workout plan.
    func requestWatchWorkout(planId: String) {
        guard let session = wcSession, session.isReachable else { return }

        session.sendMessage([
            "type": WCMessageType.startWorkout.rawValue,
            "planId": planId
        ], replyHandler: nil)
    }

    /// Requests the watch to stop the current workout.
    func requestWatchStop() {
        guard let session = wcSession, session.isReachable else { return }

        session.sendMessage([
            "type": WCMessageType.stopWorkout.rawValue
        ], replyHandler: nil)
    }

    /// Pings the watch to check connectivity.
    func pingWatch() {
        guard let session = wcSession, session.isReachable else {
            isWatchReachable = false
            return
        }

        session.sendMessage(
            ["type": WCMessageType.ping.rawValue],
            replyHandler: { _ in
                Task { @MainActor in
                    self.isWatchReachable = true
                }
            },
            errorHandler: { _ in
                Task { @MainActor in
                    self.isWatchReachable = false
                }
            }
        )
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
            if let error = error {
                print("❌ WCSession activation failed (iOS): \(error.localizedDescription)")
                isWatchReachable = false
                return
            }
            
            switch activationState {
            case .activated:
                print("✅ WCSession activated successfully (iOS)")
                isWatchReachable = session.isReachable
                if session.isPaired {
                    print("✅ Watch is paired")
                } else {
                    print("⚠️ No watch is paired")
                }
                if !session.isReachable {
                    print("⚠️ Watch is not reachable (may be disconnected or out of range)")
                }
            case .inactive:
                print("⚠️ WCSession is inactive (iOS)")
                isWatchReachable = false
            case .notActivated:
                print("⚠️ WCSession is not activated (iOS)")
                isWatchReachable = false
            @unknown default:
                print("⚠️ WCSession unknown activation state (iOS)")
                isWatchReachable = false
            }
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ WCSession became inactive (iOS)")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ WCSession deactivated (iOS) - reactivating...")
        session.activate()
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
            if session.isReachable {
                print("✅ Watch became reachable (iOS)")
            } else {
                print("⚠️ Watch became unreachable (iOS)")
            }
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
        guard let typeRaw = message["type"] as? String,
              let type = WCMessageType(rawValue: typeRaw) else { return }

        switch type {
        case .biofeedback:
            if let base64 = message["data"] as? String,
               let data = Data(base64Encoded: base64),
               let snapshot = try? decoder.decode(BiofeedbackSnapshot.self, from: data) {
                latestSnapshot = snapshot
            }

        case .workoutStatus:
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
        guard let typeRaw = userInfo["type"] as? String,
              let type = WCMessageType(rawValue: typeRaw) else { return }

        switch type {
        case .workoutResult:
            if let base64 = userInfo["data"] as? String,
               let data = Data(base64Encoded: base64),
               let result = try? decoder.decode(WorkoutResult.self, from: data) {
                pendingWorkoutResult = result
            }

        default:
            break
        }
    }
}
