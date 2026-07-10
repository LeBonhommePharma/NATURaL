import Foundation

/// Orchestrates multiple SignalAnalyzers, routing incoming health signals
/// to the appropriate analyzer and maintaining cross-signal context.
///
/// This is the generalized replacement for the single-purpose SCI pipeline.
/// Any number of analyzers can be registered; each receives its primary signals
/// plus read-only context from all other analyzers for cross-domain correlation.
public final class FeedbackEngine: @unchecked Sendable {
    private var analyzers: [SignalType: any SignalAnalyzer] = [:]
    private var signalBuffers: [SignalType: [any HealthSignal]] = [:]
    private var latestInsights: [SignalType: AnalysisInsight] = [:]
    private let lock = NSLock()

    /// Maximum signals retained per type.
    private let bufferLimit: Int
    /// Extra slots before trim — amortizes `removeFirst` cost on high-rate ingest.
    private let bufferTrimSlack: Int

    public init(bufferLimit: Int = 500) {
        self.bufferLimit = bufferLimit
        self.bufferTrimSlack = max(32, bufferLimit / 10)
    }

    /// Register an analyzer for its primary signal type.
    public func register(_ analyzer: any SignalAnalyzer) {
        lock.lock()
        analyzers[analyzer.primarySignalType] = analyzer
        lock.unlock()
    }

    /// Ingest a new health signal. Call this from HealthKit callbacks,
    /// ResearchKit completion handlers, or manual entry flows.
    public func ingest(_ signal: any HealthSignal) {
        let type = Swift.type(of: signal).signalType
        lock.lock()
        var buffer = signalBuffers[type] ?? []
        buffer.append(signal)
        if buffer.count > bufferLimit + bufferTrimSlack {
            buffer.removeFirst(buffer.count - bufferLimit)
        }
        signalBuffers[type] = buffer
        lock.unlock()
    }

    /// Run all registered analyzers and return their insights.
    /// Each analyzer receives its own signal buffer plus cross-signal context.
    public func analyzeAll() -> [SignalType: AnalysisInsight] {
        lock.lock()
        let currentBuffers = signalBuffers
        let priorInsights = latestInsights
        let currentAnalyzers = analyzers
        lock.unlock()

        let context = AnalysisContext(
            signalsByType: currentBuffers,
            priorInsights: priorInsights
        )

        var results: [SignalType: AnalysisInsight] = [:]

        for (signalType, analyzer) in currentAnalyzers {
            let signals = currentBuffers[signalType] ?? []
            let insight = analyzer.analyze(signals: signals, context: context)
            results[signalType] = insight
        }

        lock.lock()
        latestInsights = results
        lock.unlock()

        return results
    }

    /// Run a single analyzer by signal type and return its insight.
    public func analyze(for signalType: SignalType) -> AnalysisInsight? {
        lock.lock()
        let analyzer = analyzers[signalType]
        let signals = signalBuffers[signalType] ?? []
        let context = AnalysisContext(
            signalsByType: signalBuffers,
            priorInsights: latestInsights
        )
        lock.unlock()

        guard let analyzer else { return nil }
        let insight = analyzer.analyze(signals: signals, context: context)

        lock.lock()
        latestInsights[signalType] = insight
        lock.unlock()

        return insight
    }

    /// The most recent insight for a given signal type, if one has been computed.
    public func latestInsight(for signalType: SignalType) -> AnalysisInsight? {
        lock.lock()
        defer { lock.unlock() }
        return latestInsights[signalType]
    }

    /// Snapshot of all cached insights without re-running analyzers (TV / Watch relay).
    public func allLatestInsights() -> [SignalType: AnalysisInsight] {
        lock.lock()
        defer { lock.unlock() }
        return latestInsights
    }

    /// Ensure HRV is fresh, then return all cached insights (other types may be stale).
    /// Prefer this over `analyzeAll()` on high-frequency display paths.
    @discardableResult
    public func refreshHRVAndSnapshot() -> [SignalType: AnalysisInsight] {
        _ = analyze(for: .heartRateVariability)
        return allLatestInsights()
    }

    /// Clear all buffered signals and insights.
    public func reset() {
        lock.lock()
        signalBuffers.removeAll()
        latestInsights.removeAll()
        lock.unlock()
    }
}
