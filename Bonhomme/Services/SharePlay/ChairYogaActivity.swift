import GroupActivities
import BonhommeCore

/// GroupActivity for SharePlay group workout sessions via FaceTime.
/// Each participant sees synchronized pose transitions.
struct ChairYogaActivity: GroupActivity {
    let workoutPlanId: String
    let workoutPlanName: String

    var metadata: GroupActivityMetadata {
        var meta = GroupActivityMetadata()
        meta.title = "Chair Yoga with NATURaL"
        meta.subtitle = workoutPlanName
        meta.type = .generic
        return meta
    }

    static var activityIdentifier: String {
        "com.bonhomme.natural.chairyoga"
    }
}

/// Message types for synchronizing workout state across SharePlay participants.
struct WorkoutSyncMessage: Codable, Sendable {
    enum Action: String, Codable {
        case startPose
        case pause
        case resume
        case complete
    }

    let action: Action
    let poseIndex: Int?
    let timestamp: Double
}
