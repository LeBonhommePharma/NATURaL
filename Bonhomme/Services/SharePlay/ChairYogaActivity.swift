import Foundation
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
/// Keep this payload tiny — GroupSessionMessenger is not for bulk data.
struct WorkoutSyncMessage: Codable, Sendable {
    enum Action: String, Codable {
        case startPose
        case pause
        case resume
        case complete
    }

    let action: Action
    let poseIndex: Int?
    /// Wall-clock seconds since reference date for last-writer / ordering.
    let timestamp: Double

    init(action: Action, poseIndex: Int? = nil, timestamp: Double = Date().timeIntervalSince1970) {
        self.action = action
        self.poseIndex = poseIndex
        self.timestamp = timestamp
    }
}
