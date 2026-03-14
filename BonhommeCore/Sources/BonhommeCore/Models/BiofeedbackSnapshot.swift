import Foundation

/// Trend direction of the Shannon Collapse Index over time.
public enum SCITrend: String, Codable, Sendable {
    case improving
    case stable
    case declining
}

/// A point-in-time snapshot of biofeedback sensor data.
public struct BiofeedbackSnapshot: Codable, Sendable {
    public let heartRate: Double?
    public let heartRateVariability: Double?
    public let sciScore: Double?
    public let sciTrend: SCITrend
    public let activeCalories: Double
    public let timestamp: Date

    public init(
        heartRate: Double? = nil,
        heartRateVariability: Double? = nil,
        sciScore: Double? = nil,
        sciTrend: SCITrend = .stable,
        activeCalories: Double = 0,
        timestamp: Date = Date()
    ) {
        self.heartRate = heartRate
        self.heartRateVariability = heartRateVariability
        self.sciScore = sciScore
        self.sciTrend = sciTrend
        self.activeCalories = activeCalories
        self.timestamp = timestamp
    }
}
