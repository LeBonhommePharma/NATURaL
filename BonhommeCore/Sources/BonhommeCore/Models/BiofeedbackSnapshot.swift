import Foundation

/// Trend direction of the Shannon Collapse Index over time.
public enum SCITrend: String, Codable, Sendable {
    case improving
    case stable
    case declining
}

/// A point-in-time snapshot of biofeedback sensor data.
///
/// Retains the original HR/SCI fields for backward compatibility with TV display views,
/// and adds an `insights` dictionary populated by the generalized FeedbackEngine.
public struct BiofeedbackSnapshot: Codable, Sendable {
    public let heartRate: Double?
    public let heartRateVariability: Double?
    public let sciScore: Double?
    public let sciTrend: SCITrend
    public let activeCalories: Double
    public let timestamp: Date

    /// Multi-signal analysis insights from FeedbackEngine, keyed by signal type.
    /// Populated when a FeedbackEngine is active; empty in legacy/minimal mode.
    public let insights: [SignalType: AnalysisInsight]

    public init(
        heartRate: Double? = nil,
        heartRateVariability: Double? = nil,
        sciScore: Double? = nil,
        sciTrend: SCITrend = .stable,
        activeCalories: Double = 0,
        timestamp: Date = Date(),
        insights: [SignalType: AnalysisInsight] = [:]
    ) {
        self.heartRate = heartRate
        self.heartRateVariability = heartRateVariability
        self.sciScore = sciScore
        self.sciTrend = sciTrend
        self.activeCalories = activeCalories
        self.timestamp = timestamp
        self.insights = insights
    }

    /// Convenience: creates a snapshot from FeedbackEngine output,
    /// mapping HRV insight back to the legacy sciScore/sciTrend fields.
    public init(
        heartRate: Double?,
        activeCalories: Double,
        feedbackInsights: [SignalType: AnalysisInsight],
        timestamp: Date = Date()
    ) {
        let hrvInsight = feedbackInsights[.heartRateVariability]
        self.heartRate = heartRate
        self.heartRateVariability = nil
        self.sciScore = hrvInsight?.score
        self.sciTrend = hrvInsight.map { insight in
            switch insight.trend {
            case .improving: return .improving
            case .stable: return .stable
            case .declining: return .declining
            }
        } ?? .stable
        self.activeCalories = activeCalories
        self.timestamp = timestamp
        self.insights = feedbackInsights
    }
}
