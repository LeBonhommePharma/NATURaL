import Foundation

/// Metadata attached to a completed HKWorkout record for richer HealthKit integration.
public struct WorkoutMetadata: Codable, Sendable {
    public let planId: String
    public let planName: String
    public let styleName: String
    public let sciScore: Double?

    public init(planId: String, planName: String, styleName: String, sciScore: Double?) {
        self.planId = planId
        self.planName = planName
        self.styleName = styleName
        self.sciScore = sciScore
    }
}
