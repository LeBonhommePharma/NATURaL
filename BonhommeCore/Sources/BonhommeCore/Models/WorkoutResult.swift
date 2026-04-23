import Foundation

// MARK: - HeartRateSample

/// A single heart-rate measurement captured during a workout.
public struct HeartRateSample: Codable, Sendable, Hashable {
    public let bpm: Double
    public let timestamp: Date

    public init(bpm: Double, timestamp: Date = Date()) {
        self.bpm = bpm
        self.timestamp = timestamp
    }
}

// MARK: - WorkoutResult

/// Summary of a completed guided workout session.
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
    public let yogaStyle: YogaStyle
    public let yogaStyleName: String

    public init(
        workoutPlanId: String,
        workoutPlanName: String,
        startDate: Date,
        endDate: Date,
        totalDuration: TimeInterval,
        posesCompleted: Int,
        totalPoses: Int,
        activeCalories: Double,
        averageHeartRate: Double?,
        maxHeartRate: Double?,
        heartRateSamples: [HeartRateSample],
        yogaStyle: YogaStyle = .chairYoga,
        yogaStyleName: String = ""
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
        self.yogaStyle = yogaStyle
        self.yogaStyleName = yogaStyleName
    }
}
