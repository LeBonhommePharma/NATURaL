import Foundation

/// Computes the Shannon Collapse Index (SCI) from HRV signals.
///
/// The SCI measures autonomic coherence by calculating the Shannon entropy
/// of RR-interval distributions. Lower entropy indicates higher coherence
/// (focused breathing), while higher entropy indicates variability
/// (distracted or stressed state).
///
/// Methodology ported from the configurational entropy engine in FlexAIDdS,
/// adapted from molecular torsional distributions to cardiac interval distributions.
public struct HRVAnalyzer: SignalAnalyzer, Sendable {
    public let primarySignalType: SignalType = .heartRateVariability

    /// Number of histogram bins for entropy calculation.
    private let binCount: Int
    /// Window size in seconds for sliding entropy.
    private let windowSeconds: TimeInterval
    /// Entropy threshold (bits) below which we consider "focused".
    private let collapseThreshold: Double

    public init(
        binCount: Int = 32,
        windowSeconds: TimeInterval = 60,
        collapseThreshold: Double = 3.2
    ) {
        self.binCount = binCount
        self.windowSeconds = windowSeconds
        self.collapseThreshold = collapseThreshold
    }

    public func analyze(
        signals: [any HealthSignal],
        context: AnalysisContext
    ) -> AnalysisInsight {
        let hrvSignals = signals.compactMap { $0 as? HRVSignal }

        guard !hrvSignals.isEmpty else {
            return AnalysisInsight(
                signalType: .heartRateVariability,
                score: nil,
                trend: .stable,
                status: .normal,
                summary: LocalizedString(
                    en: "No HRV data available yet.",
                    fr: "Aucune donnée VRC disponible pour le moment."
                )
            )
        }

        // Collect all RR intervals within the window
        let cutoff = Date().addingTimeInterval(-windowSeconds)
        let windowedSignals = hrvSignals.filter { $0.timestamp >= cutoff }

        let allRR = windowedSignals.flatMap(\.rrIntervals)
        let entropy = allRR.count >= 4 ? shannonEntropy(allRR) : nil
        let sciScore = entropy.map { entropyToScore($0) }

        // Trend: compare first half vs second half
        let trend = computeTrend(signals: windowedSignals)

        // Cross-reference medication context if available
        let medNote = medicationContextNote(context: context)

        let status: InsightStatus
        if let score = sciScore {
            status = score >= 0.6 ? .normal : (score >= 0.3 ? .advisory : .alert)
        } else {
            status = .normal
        }

        let scoreText = sciScore.map { String(format: "%.0f", $0 * 100) } ?? "--"
        return AnalysisInsight(
            signalType: .heartRateVariability,
            score: sciScore,
            trend: trend,
            status: status,
            summary: LocalizedString(
                en: "Focus coherence: \(scoreText)%.\(medNote)",
                fr: "Cohérence de concentration : \(scoreText) %.\(medNote)"
            )
        )
    }

    // MARK: - Entropy Math

    /// Shannon entropy of a distribution of RR intervals, binned into a histogram.
    /// H = -sum(p_i * log2(p_i)) for each bin with p_i > 0.
    func shannonEntropy(_ intervals: [Double]) -> Double {
        guard intervals.count >= 2 else { return 0 }

        let minRR = intervals.min()!
        let maxRR = intervals.max()!
        let range = maxRR - minRR
        guard range > 0 else { return 0 }

        let binWidth = range / Double(binCount)
        var bins = [Int](repeating: 0, count: binCount)

        for rr in intervals {
            let idx = min(binCount - 1, Int((rr - minRR) / binWidth))
            bins[idx] += 1
        }

        let total = Double(intervals.count)
        var entropy = 0.0
        for count in bins where count > 0 {
            let p = Double(count) / total
            entropy -= p * log2(p)
        }
        return entropy
    }

    /// Map entropy (bits) to a 0–1 score where 1 = maximally focused.
    /// Normal resting: H ~ 6-8 bits → score ~ 0.0-0.3
    /// Focused breathing: H ~ 2-4 bits → score ~ 0.6-1.0
    private func entropyToScore(_ entropy: Double) -> Double {
        // Linear mapping: 8 bits → 0.0, 0 bits → 1.0
        let clamped = max(0, min(8, entropy))
        return 1.0 - (clamped / 8.0)
    }

    private func computeTrend(signals: [HRVSignal]) -> InsightTrend {
        guard signals.count >= 4 else { return .stable }
        let mid = signals.count / 2
        let firstHalf = signals[..<mid].map(\.rmssd)
        let secondHalf = signals[mid...].map(\.rmssd)

        let avgFirst = firstHalf.reduce(0, +) / Double(firstHalf.count)
        let avgSecond = secondHalf.reduce(0, +) / Double(secondHalf.count)
        let delta = avgSecond - avgFirst

        if delta > 5 { return .improving }
        if delta < -5 { return .declining }
        return .stable
    }

    /// If medication signals exist in context, note potential correlation.
    private func medicationContextNote(context: AnalysisContext) -> String {
        guard let medSignals = context.signalsByType[.medication],
              let latest = medSignals.last as? MedicationSignal,
              latest.event == .taken,
              Date().timeIntervalSince(latest.timestamp) < 3600 else {
            return ""
        }
        return " Recent \(latest.name.localized) dose may affect readings."
    }
}
