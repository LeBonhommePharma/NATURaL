import Foundation

/// A structured sequence of poses forming a complete chair yoga session.
public struct WorkoutPlan: Codable, Sendable, Identifiable {
    public let id: String
    public let name: LocalizedString
    public let description: LocalizedString
    public let poses: [Pose]
    public let transitionSeconds: TimeInterval
    public let isFree: Bool

    public var totalDuration: TimeInterval {
        let poseDuration = poses.reduce(0) { $0 + $1.durationSeconds }
        let transitions = TimeInterval(max(0, poses.count - 1)) * transitionSeconds
        return poseDuration + transitions
    }

    public var poseCount: Int { poses.count }

    public init(
        id: String,
        name: LocalizedString,
        description: LocalizedString,
        poses: [Pose],
        transitionSeconds: TimeInterval = 5,
        isFree: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.poses = poses
        self.transitionSeconds = transitionSeconds
        self.isFree = isFree
    }
}
