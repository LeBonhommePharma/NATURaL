import Foundation

/// The Codable message sent from the iOS hub to any TV display surface
/// (native tvOS app via NWConnection, or AirPlay second-screen via UIScene).
public struct TVDisplayPayload: Codable, Sendable {
    public let currentPose: Pose
    public let poseTimeRemaining: TimeInterval
    public let totalPoseTime: TimeInterval
    public let biofeedback: BiofeedbackSnapshot
    public let sessionElapsed: TimeInterval
    public let isPaused: Bool
    public let sequenceIndex: Int
    public let sequenceTotal: Int

    public init(
        currentPose: Pose,
        poseTimeRemaining: TimeInterval,
        totalPoseTime: TimeInterval,
        biofeedback: BiofeedbackSnapshot,
        sessionElapsed: TimeInterval,
        isPaused: Bool,
        sequenceIndex: Int,
        sequenceTotal: Int
    ) {
        self.currentPose = currentPose
        self.poseTimeRemaining = poseTimeRemaining
        self.totalPoseTime = totalPoseTime
        self.biofeedback = biofeedback
        self.sessionElapsed = sessionElapsed
        self.isPaused = isPaused
        self.sequenceIndex = sequenceIndex
        self.sequenceTotal = sequenceTotal
    }
}
