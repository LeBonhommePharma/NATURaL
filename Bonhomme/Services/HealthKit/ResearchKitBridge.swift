import Foundation
import BonhommeCore

/// Bridges ResearchKit survey results into the FeedbackEngine signal pipeline.
///
/// ResearchKit (ORKTaskViewController) collects structured survey responses
/// via standardized instruments (Likert scales, VAS, validated questionnaires).
/// This service normalizes those results into SurveySignal instances and
/// ingests them for cross-analysis with HRV and medication data.
///
/// Supported instruments:
/// - Pain VAS (0-10 visual analog scale)
/// - Mood Likert (1-5 scale)
/// - Well-being WHO-5 (0-25 raw, 0-100 percentage)
/// - Custom single-question scales
///
/// Note: ResearchKit framework must be linked at the app target level.
/// BonhommeCore remains framework-independent; only this service layer
/// imports ResearchKit types.
@MainActor
final class ResearchKitBridge: ObservableObject {
    @Published var latestSurveys: [SurveySignal] = []

    /// Cap in-memory survey history (long programs + re-tests).
    private static let maxSurveys = 100

    private let feedbackEngine: FeedbackEngine

    init(feedbackEngine: FeedbackEngine) {
        self.feedbackEngine = feedbackEngine
    }

    private func appendSurvey(_ signal: SurveySignal) {
        latestSurveys.append(signal)
        if latestSurveys.count > Self.maxSurveys {
            latestSurveys.removeFirst(latestSurveys.count - Self.maxSurveys)
        }
        feedbackEngine.ingest(signal)
    }

    // MARK: - Survey Result Processing

    /// Process a completed survey result from ResearchKit's ORKTaskResult.
    /// Call this from the ORKTaskViewControllerDelegate completion handler.
    ///
    /// - Parameters:
    ///   - instrumentId: Identifier for the survey instrument (e.g. "pain-vas").
    ///   - stepResults: Dictionary of step identifier → answer value pairs.
    ///   - scaleRange: The instrument's native scale range (e.g. 0...10 for VAS).
    func processSurveyResult(
        instrumentId: String,
        stepResults: [String: String],
        scaleRange: ClosedRange<Double>
    ) {
        let numericValues = stepResults.values.compactMap(Double.init)
        let rawScore = numericValues.isEmpty ? 0 : numericValues.reduce(0, +) / Double(numericValues.count)

        let normalizedScore = normalizeScore(
            rawScore,
            from: scaleRange
        )

        let signal = SurveySignal(
            timestamp: Date(),
            instrumentId: instrumentId,
            normalizedScore: normalizedScore,
            responses: stepResults
        )

        appendSurvey(signal)
    }

    // MARK: - Pre-built Instrument Helpers

    /// Process a pain VAS result (0-10 scale, lower = better → inverted for normalization).
    func processPainVAS(score: Double) {
        let inverted = 1.0 - (score / 10.0) // 0 pain = 1.0, 10 pain = 0.0
        let signal = SurveySignal(
            timestamp: Date(),
            instrumentId: "pain-vas",
            normalizedScore: max(0, min(1, inverted)),
            responses: ["pain_score": String(format: "%.1f", score)]
        )
        appendSurvey(signal)
    }

    /// Process a mood Likert result (1-5 scale, higher = better).
    func processMoodLikert(score: Int) {
        let normalized = Double(score - 1) / 4.0 // 1→0.0, 5→1.0
        let signal = SurveySignal(
            timestamp: Date(),
            instrumentId: "mood-likert",
            normalizedScore: max(0, min(1, normalized)),
            responses: ["mood_score": "\(score)"]
        )
        appendSurvey(signal)
    }

    /// Process a WHO-5 Well-Being Index (0-25 raw score, percentage = raw × 4).
    func processWHO5(rawScore: Int) {
        let normalized = Double(rawScore) / 25.0
        let signal = SurveySignal(
            timestamp: Date(),
            instrumentId: "well-being-5",
            normalizedScore: max(0, min(1, normalized)),
            responses: ["who5_raw": "\(rawScore)", "who5_pct": "\(rawScore * 4)"]
        )
        appendSurvey(signal)
    }

    // MARK: - Normalization

    /// Linearly normalize a raw score from its instrument range to 0.0–1.0.
    private func normalizeScore(
        _ raw: Double,
        from range: ClosedRange<Double>
    ) -> Double {
        let span = range.upperBound - range.lowerBound
        guard span > 0 else { return 0 }
        let clamped = max(range.lowerBound, min(range.upperBound, raw))
        return (clamped - range.lowerBound) / span
    }
}
