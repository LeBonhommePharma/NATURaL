import Foundation

// MARK: - SCI Trend

/// Directional trend of the Shannon Collapse Index over the analysis window.
/// Mirrors `InsightTrend` but is a standalone Codable type for TV relay payload.
public enum SCITrend: String, Codable, Sendable, Equatable {
    case improving
    case stable
    case declining
}

// MARK: - Biofeedback Snapshot

/// Lightweight, Codable snapshot of real-time biofeedback metrics.
/// Sent from iOS/Watch to TV via Bonjour relay or WatchConnectivity.
public struct BiofeedbackSnapshot: Codable, Sendable {
    /// Current heart rate in BPM, or nil if unavailable.
    public var heartRate: Double?
    /// Current HRV (SDNN/RMSSD) in ms, or nil if unavailable.
    public var heartRateVariability: Double?
    /// Normalized 0.0–1.0 Shannon Collapse Index score, or nil if unavailable.
    public var sciScore: Double?
    /// Directional trend of the SCI.
    public var sciTrend: SCITrend
    /// Cumulative active energy burned (kcal) this session.
    public var activeCalories: Double
    /// When this snapshot was captured.
    public var timestamp: Date?

    /// Full analysis insights keyed by signal type, when available.
    public var insights: [SignalType: AnalysisInsight]

    // MARK: - Full Initializer

    public init(
        heartRate: Double? = nil,
        heartRateVariability: Double? = nil,
        sciScore: Double? = nil,
        sciTrend: SCITrend = .stable,
        activeCalories: Double = 0,
        timestamp: Date? = nil,
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

    // MARK: - Convenience Initializer from FeedbackEngine Insights

    /// Builds a snapshot by extracting SCI score/trend from the HRV insight.
    public init(
        heartRate: Double? = nil,
        activeCalories: Double = 0,
        feedbackInsights: [SignalType: AnalysisInsight]
    ) {
        let hrvInsight = feedbackInsights[.heartRateVariability]
        self.init(
            heartRate: heartRate,
            sciScore: hrvInsight?.score,
            sciTrend: hrvInsight?.trend.asSCITrend ?? .stable,
            activeCalories: activeCalories,
            timestamp: Date(),
            insights: feedbackInsights
        )
    }
}

// MARK: - InsightTrend → SCITrend Bridge

public extension InsightTrend {
    /// Convert the analyzer's generic trend to the TV-specific SCI trend.
    var asSCITrend: SCITrend {
        switch self {
        case .improving: return .improving
        case .stable: return .stable
        case .declining: return .declining
        }
    }
}

// MARK: - TV Display Payload

/// Codable message sent from the iPhone workout session to the TV display
/// (native tvOS via Bonjour or AirPlay second-screen). Contains everything
/// the TV needs to render the current workout state without any HealthKit access.
public struct TVDisplayPayload: Codable, Sendable {
    /// The current chair yoga pose being performed.
    public let currentPose: Pose
    /// Seconds remaining in the current pose hold.
    public let poseTimeRemaining: TimeInterval
    /// Total duration of the current pose hold.
    public let totalPoseTime: TimeInterval
    /// Real-time biofeedback metrics.
    public let biofeedback: BiofeedbackSnapshot
    /// Total elapsed time since the workout session started.
    public let sessionElapsed: TimeInterval
    /// Whether the workout is currently paused.
    public let isPaused: Bool
    /// Zero-based index of the current pose in the sequence.
    public let sequenceIndex: Int
    /// Total number of poses in the sequence.
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
