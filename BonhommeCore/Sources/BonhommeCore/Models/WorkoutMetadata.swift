import Foundation

/// Metadata attached to completed HKWorkout records for Apple Health/Fitness integration.
/// Contains NATURaL-specific identifiers that make workouts appear with rich context
/// in the Health app and Fitness app workout history.
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
