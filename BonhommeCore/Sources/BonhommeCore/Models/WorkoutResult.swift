import Foundation

/// Summary data produced at the end of a completed workout session.
public struct WorkoutResult: Codable, Sendable {
    public let workoutPlanId: String
    public let workoutPlanName: String
    public let startDate: Date
    public let endDate: Date
    public let totalDuration: TimeInterval
    public let posesCompleted: Int
    public let totalPoses: Int
    public let activeCalories: Double
    public let averageHeartRate: Double?
    public let maxHeartRate: Double?
    public let heartRateSamples: [HeartRateSample]

    public init(
        workoutPlanId: String,
        workoutPlanName: String,
        startDate: Date,
        endDate: Date,
        totalDuration: TimeInterval,
        posesCompleted: Int,
        totalPoses: Int,
        activeCalories: Double,
        averageHeartRate: Double? = nil,
        maxHeartRate: Double? = nil,
        heartRateSamples: [HeartRateSample] = []
    ) {
        self.workoutPlanId = workoutPlanId
        self.workoutPlanName = workoutPlanName
        self.startDate = startDate
        self.endDate = endDate
        self.totalDuration = totalDuration
        self.posesCompleted = posesCompleted
        self.totalPoses = totalPoses
        self.activeCalories = activeCalories
        self.averageHeartRate = averageHeartRate
        self.maxHeartRate = maxHeartRate
        self.heartRateSamples = heartRateSamples
    }
}

/// A timestamped heart rate reading for post-workout charting.
public struct HeartRateSample: Codable, Sendable {
    public let bpm: Double
    public let timestamp: Date

    public init(bpm: Double, timestamp: Date) {
        self.bpm = bpm
        self.timestamp = timestamp
    }
}
