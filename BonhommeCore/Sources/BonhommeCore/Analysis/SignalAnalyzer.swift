import Foundation

// MARK: - Analyzer Protocol

/// Consumes a window of health signals and produces a typed analysis result.
/// Each analyzer is specialized to one signal type but can cross-reference
/// other signal types for context (e.g., medication effects on HRV).
public protocol SignalAnalyzer: Sendable {
    /// The primary signal type this analyzer processes.
    var primarySignalType: SignalType { get }

    /// Analyze a window of signals and return an insight.
    /// The `context` parameter provides signals from other analyzers
    /// for cross-domain correlation (e.g., medication timing vs. HRV response).
    func analyze(
        signals: [any HealthSignal],
        context: AnalysisContext
    ) -> AnalysisInsight
}

/// Read-only context passed to analyzers for cross-signal correlation.
public struct AnalysisContext: Sendable {
    /// Recent signals grouped by type, from all active sources.
    public let signalsByType: [SignalType: [any HealthSignal]]
    /// Most recent insight from each analyzer, keyed by signal type.
    public let priorInsights: [SignalType: AnalysisInsight]

    public init(
        signalsByType: [SignalType: [any HealthSignal]] = [:],
        priorInsights: [SignalType: AnalysisInsight] = [:]
    ) {
        self.signalsByType = signalsByType
        self.priorInsights = priorInsights
    }
}

// MARK: - Analysis Output

/// The unified output of any SignalAnalyzer.
public struct AnalysisInsight: Codable, Sendable {
    /// Which signal type produced this insight.
    public let signalType: SignalType
    /// Normalized 0.0–1.0 score (higher = better).
    public let score: Double?
    /// Directional trend over the analysis window.
    public let trend: InsightTrend
    /// Machine-readable status for UI coloring / alerts.
    public let status: InsightStatus
    /// Short human-readable summary (1-2 sentences) suitable for display.
    public let summary: LocalizedString
    /// When this insight was computed.
    public let computedAt: Date

    public init(
        signalType: SignalType,
        score: Double?,
        trend: InsightTrend,
        status: InsightStatus,
        summary: LocalizedString,
        computedAt: Date = Date()
    ) {
        self.signalType = signalType
        self.score = score
        self.trend = trend
        self.status = status
        self.summary = summary
        self.computedAt = computedAt
    }
}

public enum InsightTrend: String, Codable, Sendable {
    case improving
    case stable
    case declining
}

public enum InsightStatus: String, Codable, Sendable {
    /// Everything looks normal.
    case normal
    /// Warrants attention but not urgent.
    case advisory
    /// Needs prompt attention (e.g., missed critical dose, HRV drop).
    case alert
}
