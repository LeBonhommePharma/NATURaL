import Foundation

/// Centralized configuration for all computational chemistry analysis thresholds.
///
/// Collects the ~12 magic numbers previously scattered across EntropyCalculator,
/// FlexAIDdSAnalyzer, DrugResponseAnalyzer, CrossDomainValidator, and
/// DockingInsightAnalyzer into a single, runtime-configurable struct.
///
/// Usage:
/// ```swift
/// // Default (all existing behavior preserved):
/// let analyzer = FlexAIDdSAnalyzer()
///
/// // Custom for research experiments:
/// var config = AnalysisConfiguration.default
/// config = AnalysisConfiguration(crossDomainMinPairs: 10, crossDomainSignificanceLevel: 0.01)
/// let validator = CrossDomainValidator(configuration: config)
/// ```
public struct AnalysisConfiguration: Sendable {

    // MARK: - Entropy Calculation

    /// Number of histogram bins for Shannon entropy computation.
    /// Default: 32. Higher values give finer resolution but need more samples.
    public let histogramBinCount: Int

    // MARK: - FlexAIDdS Thresholds

    /// Minimum |ΔS_config| (bits) to consider a binding entropy penalty significant.
    public let dockingSignificanceThreshold: Double

    // MARK: - Drug Response Thresholds

    /// Minimum |ΔH| (bits) to consider a drug-induced entropy change significant.
    public let drugResponseSignificanceThreshold: Double

    /// Minimum number of RR intervals required in a measurement window.
    public let minimumRRCount: Int

    /// Duration of the pre-dose baseline window (seconds).
    public let baselineWindowSeconds: TimeInterval

    /// Half-width of each post-dose measurement window (seconds).
    public let windowRadius: TimeInterval

    /// Minimum confidence score for a pharmacokinetic profile match.
    public let profileMatchMinConfidence: Double

    // MARK: - Cross-Domain Validation

    /// Minimum number of paired observations required for validation.
    /// Raised from 3 to 5: at n < 5, even r = 0.99 can have p > 0.05.
    public let crossDomainMinPairs: Int

    /// p-value threshold for declaring statistical significance.
    public let crossDomainSignificanceLevel: Double

    // MARK: - Docking Insight Analyzer

    /// Minimum |ΔS| change between halves to declare a trend (bits).
    public let dockingTrendThreshold: Double

    /// |ΔS| above which an alert status is raised (bits).
    public let dockingAlertThreshold: Double

    /// |ΔS| above which an advisory status is raised (bits).
    public let dockingAdvisoryThreshold: Double

    /// Maximum |ΔS| for 0–1 score normalization (bits).
    public let dockingNormalizationMax: Double

    // MARK: - Statistics

    /// Maximum value for Cohen's d (caps .infinity when SD = 0).
    public let maxCohensD: Double

    // MARK: - Default

    public static let `default` = AnalysisConfiguration()

    public init(
        histogramBinCount: Int = 32,
        dockingSignificanceThreshold: Double = 0.5,
        drugResponseSignificanceThreshold: Double = 0.4,
        minimumRRCount: Int = 20,
        baselineWindowSeconds: TimeInterval = 1800,
        windowRadius: TimeInterval = 300,
        profileMatchMinConfidence: Double = 0.5,
        crossDomainMinPairs: Int = 5,
        crossDomainSignificanceLevel: Double = 0.05,
        dockingTrendThreshold: Double = 0.3,
        dockingAlertThreshold: Double = 3.0,
        dockingAdvisoryThreshold: Double = 1.5,
        dockingNormalizationMax: Double = 5.0,
        maxCohensD: Double = 10.0
    ) {
        self.histogramBinCount = histogramBinCount
        self.dockingSignificanceThreshold = dockingSignificanceThreshold
        self.drugResponseSignificanceThreshold = drugResponseSignificanceThreshold
        self.minimumRRCount = minimumRRCount
        self.baselineWindowSeconds = baselineWindowSeconds
        self.windowRadius = windowRadius
        self.profileMatchMinConfidence = profileMatchMinConfidence
        self.crossDomainMinPairs = crossDomainMinPairs
        self.crossDomainSignificanceLevel = crossDomainSignificanceLevel
        self.dockingTrendThreshold = dockingTrendThreshold
        self.dockingAlertThreshold = dockingAlertThreshold
        self.dockingAdvisoryThreshold = dockingAdvisoryThreshold
        self.dockingNormalizationMax = dockingNormalizationMax
        self.maxCohensD = maxCohensD
    }
}
