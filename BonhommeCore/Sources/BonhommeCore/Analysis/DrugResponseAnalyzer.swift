import Foundation

/// Result of entropy analysis around a single dose event.
///
/// Contains the full ΔH time series (entropy delta relative to baseline)
/// along with peak detection and optional pharmacokinetic profile matching.
/// This is the physiological analog of FlexAID∆S binding free energy output.
public struct DrugResponseResult: Sendable {
    /// The medication dose event that triggered this analysis.
    public let doseEvent: DoseEventSummary

    /// Baseline Shannon entropy computed from pre-dose RR intervals (bits).
    public let baselineEntropy: Double

    /// Number of RR intervals in the baseline window.
    public let baselineRRCount: Int

    /// Time-series of entropy measurements at post-dose windows.
    public let measurements: [EntropyMeasurement]

    /// Peak entropy delta (most extreme ΔH from baseline).
    /// Negative = entropy collapse (sympathomimetic binding detected).
    /// Positive = entropy expansion (parasympathomimetic / vagotonic detected).
    public let peakDeltaH: Double

    /// Time (minutes post-dose) at which peak ΔH occurred.
    public let peakTimeMinutes: Double

    /// If a pharmacokinetic profile was matched, the match result.
    public let profileMatch: ProfileMatchResult?

    /// Whether a statistically meaningful entropy change was detected.
    /// Analogous to FlexAID∆S reporting a binding event when |ΔS_config| exceeds noise.
    public var bindingDetected: Bool {
        abs(peakDeltaH) >= DrugResponseAnalyzer.significanceThreshold
    }

    /// Direction of the autonomic shift.
    public var responseDirection: ResponseDirection {
        if peakDeltaH < -DrugResponseAnalyzer.significanceThreshold {
            return .sympathomimeticCollapse
        } else if peakDeltaH > DrugResponseAnalyzer.significanceThreshold {
            return .parasympathomimeticExpansion
        }
        return .noSignificantChange
    }

    /// Effect size: |ΔH| / baseline_H. Dimensionless measure of response magnitude.
    /// Analogous to FlexAID∆S ΔΔG normalization.
    public var effectSize: Double {
        guard baselineEntropy > 0 else { return 0 }
        return abs(peakDeltaH) / baselineEntropy
    }

    /// Area under the ΔH curve (bits·minutes). Cumulative autonomic exposure.
    /// Analogous to AUC in pharmacokinetics.
    public var deltaHAUC: Double {
        guard measurements.count >= 2 else { return 0 }
        var auc = 0.0
        for i in 1..<measurements.count {
            let dt = measurements[i].minutesPostDose - measurements[i - 1].minutesPostDose
            let avgDH = (measurements[i].deltaH + measurements[i - 1].deltaH) / 2
            auc += avgDH * dt
        }
        return auc
    }

    /// Time to onset: first measurement where |ΔH| crosses significance threshold (minutes).
    public var onsetMinutes: Double? {
        measurements.first { abs($0.deltaH) >= DrugResponseAnalyzer.significanceThreshold }?.minutesPostDose
    }

    /// Time to recovery: first measurement after peak where |ΔH| drops back below threshold (minutes).
    public var recoveryMinutes: Double? {
        guard let peakIdx = measurements.firstIndex(where: {
            $0.minutesPostDose == peakTimeMinutes
        }) else { return nil }

        return measurements[peakIdx...].first(where: {
            $0.minutesPostDose > peakTimeMinutes &&
            abs($0.deltaH) < DrugResponseAnalyzer.significanceThreshold
        })?.minutesPostDose
    }

    /// Human-readable bilingual summary.
    public var summary: LocalizedString {
        let deltaText = String(format: "%+.2f", peakDeltaH)
        let timeText = String(format: "%.0f", peakTimeMinutes)
        let baseText = String(format: "%.2f", baselineEntropy)
        let effectText = String(format: "%.0f", effectSize * 100)

        if bindingDetected {
            let direction = peakDeltaH < 0 ? "collapse" : "expansion"
            let directionFr = peakDeltaH < 0 ? "effondrement" : "expansion"
            var en = "Entropy \(direction) detected: ΔH = \(deltaText) bits at +\(timeText) min "
            en += "(effect size: \(effectText)%). "
            en += "Baseline: \(baseText) bits (\(baselineRRCount) intervals)."
            var fr = "\(directionFr.capitalized) d'entropie détecté : ΔH = \(deltaText) bits à +\(timeText) min "
            fr += "(taille d'effet : \(effectText) %). "
            fr += "Base : \(baseText) bits (\(baselineRRCount) intervalles)."

            if let match = profileMatch {
                let conf = String(format: "%.0f", match.confidence * 100)
                en += " Profile match: \(match.profile.name.localized) (\(conf)% confidence)."
                fr += " Profil : \(match.profile.name.localized) (\(conf) % confiance)."
            }

            return LocalizedString(en: en, fr: fr)
        } else {
            return LocalizedString(
                en: "No significant entropy change: ΔH = \(deltaText) bits. Baseline: \(baseText) bits.",
                fr: "Aucun changement significatif : ΔH = \(deltaText) bits. Base : \(baseText) bits."
            )
        }
    }
}

/// Direction of the observed autonomic response.
public enum ResponseDirection: String, Codable, Sendable {
    /// ΔH < 0: RR variability compressed → sympathomimetic drug binding.
    /// FlexAID∆S analog: torsional entropy loss → ligand binding.
    case sympathomimeticCollapse

    /// ΔH > 0: RR variability expanded → parasympathomimetic / vagotonic drug binding.
    /// FlexAID∆S analog: conformational relaxation → allosteric modulation.
    case parasympathomimeticExpansion

    /// |ΔH| below significance threshold.
    case noSignificantChange
}

/// Summary of the dose event that triggered analysis.
public struct DoseEventSummary: Sendable {
    public let medicationId: String
    public let name: String
    public let doseValue: Double
    public let doseUnit: String
    public let timestamp: Date

    public init(
        medicationId: String,
        name: String,
        doseValue: Double,
        doseUnit: String,
        timestamp: Date
    ) {
        self.medicationId = medicationId
        self.name = name
        self.doseValue = doseValue
        self.doseUnit = doseUnit
        self.timestamp = timestamp
    }
}

/// A single entropy measurement at a specific post-dose time point.
public struct EntropyMeasurement: Sendable {
    /// Minutes after dose administration.
    public let minutesPostDose: Double

    /// Shannon entropy of RR intervals in this window (bits).
    public let entropy: Double

    /// ΔH = entropy - baselineEntropy (bits).
    /// Negative = entropy collapsed (less variability than baseline).
    /// Positive = entropy expanded (more variability than baseline).
    public let deltaH: Double

    /// Number of RR intervals used for this measurement.
    public let rrCount: Int

    /// Coherence score (0–1) derived from entropy. 1 = maximally coherent.
    public let coherenceScore: Double

    public init(
        minutesPostDose: Double,
        entropy: Double,
        deltaH: Double,
        rrCount: Int,
        coherenceScore: Double
    ) {
        self.minutesPostDose = minutesPostDose
        self.entropy = entropy
        self.deltaH = deltaH
        self.rrCount = rrCount
        self.coherenceScore = coherenceScore
    }
}

/// Result of matching an observed ΔH curve against a pharmacokinetic profile.
public struct ProfileMatchResult: Sendable {
    /// The matched profile.
    public let profile: PharmacokineticProfile

    /// Match confidence (0–1).
    /// Based on: ΔH magnitude within expected range, peak timing near Tmax,
    /// ΔH sign matching mechanism direction.
    public let confidence: Double

    /// Whether the observed peak ΔH falls within the profile's expected range.
    public let deltaHInRange: Bool

    /// Whether the observed peak time is near the profile's Tmax (within 50%).
    public let timingMatch: Bool

    /// Whether the ΔH direction matches the mechanism
    /// (negative for sympathomimetic, positive for parasympathomimetic).
    public let directionMatch: Bool

    public init(
        profile: PharmacokineticProfile,
        confidence: Double,
        deltaHInRange: Bool,
        timingMatch: Bool,
        directionMatch: Bool
    ) {
        self.profile = profile
        self.confidence = confidence
        self.deltaHInRange = deltaHInRange
        self.timingMatch = timingMatch
        self.directionMatch = directionMatch
    }
}

/// Aggregate statistics from multiple dose-response analyses.
public struct DrugResponseAggregate: Sendable {
    /// Medication identifier.
    public let medicationId: String

    /// Medication display name.
    public let medicationName: String

    /// Number of dose events analyzed.
    public let n: Int

    /// Mean peak ΔH across all events (bits).
    public let meanDeltaH: Double

    /// Standard deviation of peak ΔH (bits).
    public let sdDeltaH: Double

    /// Mean time to peak (minutes).
    public let meanPeakTime: Double

    /// Mean effect size (dimensionless).
    public let meanEffectSize: Double

    /// Proportion of events where binding was detected.
    public let detectionRate: Double

    /// Mean ΔH AUC (bits·minutes).
    public let meanAUC: Double

    public init(
        medicationId: String = "",
        medicationName: String = "",
        n: Int,
        meanDeltaH: Double,
        sdDeltaH: Double,
        meanPeakTime: Double,
        meanEffectSize: Double,
        detectionRate: Double,
        meanAUC: Double
    ) {
        self.medicationId = medicationId
        self.medicationName = medicationName
        self.n = n
        self.meanDeltaH = meanDeltaH
        self.sdDeltaH = sdDeltaH
        self.meanPeakTime = meanPeakTime
        self.meanEffectSize = meanEffectSize
        self.detectionRate = detectionRate
        self.meanAUC = meanAUC
    }

    /// Cohen's d effect size: |mean(ΔH)| / SD(ΔH).
    /// Measures how reliably the drug produces an entropy shift.
    /// Capped at 10.0 (values above this are not meaningfully interpretable).
    public var cohensD: Double {
        guard sdDeltaH > 0 else { return abs(meanDeltaH) > 0 ? AnalysisConfiguration.default.maxCohensD : 0 }
        return min(AnalysisConfiguration.default.maxCohensD, abs(meanDeltaH) / sdDeltaH)
    }

    /// Bilingual summary.
    public var summary: LocalizedString {
        let meanText = String(format: "%+.2f", meanDeltaH)
        let sdText = String(format: "%.2f", sdDeltaH)
        let dText = String(format: "%.2f", cohensD)
        let rateText = String(format: "%.0f", detectionRate * 100)

        return LocalizedString(
            en: "\(n) dose events: mean ΔH = \(meanText) ± \(sdText) bits, Cohen's d = \(dText), detection rate = \(rateText)%.",
            fr: "\(n) événements : ΔH moyen = \(meanText) ± \(sdText) bits, d de Cohen = \(dText), taux de détection = \(rateText) %."
        )
    }
}

// MARK: - DrugResponseAnalyzer

/// Analyzes Shannon entropy changes in HRV RR-interval distributions around medication
/// dose events to detect autonomic drug response signatures.
///
/// This is the bridge between FlexAID∆S molecular docking entropy and real-world
/// physiological measurement:
///
/// ```
/// FlexAID∆S (in silico):
///   Ligand torsional angle distributions → Shannon entropy H
///   Binding event → H collapses (fewer rotatable conformations)
///   ΔS_config = S_bound - S_free < 0  →  binding detected
///
/// NATURaL (in vivo):
///   RR-interval distributions → Shannon entropy H
///   Drug binding to autonomic receptors → H changes
///   ΔH_hrv = H_post - H_pre < 0  →  sympathomimetic binding detected
///   ΔH_hrv = H_post - H_pre > 0  →  parasympathomimetic binding detected
/// ```
///
/// The identical `EntropyCalculator` is used in both domains, making NATURaL
/// an independent physiological validation of the FlexAID∆S entropy framework.
public struct DrugResponseAnalyzer: Sendable {

    /// Minimum |ΔH| in bits to consider a drug response detected.
    /// Calibrated against resting HRV noise floor (~0.3 bits intra-session variation).
    /// Exceeding this threshold with p < 0.05 requires |ΔH| > 2σ of resting noise.
    /// Set to 0.4 bits — slightly below FlexAIDdSAnalyzer's 0.5-bit threshold because
    /// physiological RR-interval measurements have a higher noise floor (~0.3 bits from
    /// measurement artifacts) than molecular torsional distributions, requiring a lower
    /// detection threshold to capture genuine drug responses.
    public static let significanceThreshold: Double = 0.4

    /// Width of each measurement window in seconds.
    /// RR intervals within ±windowRadius of each time point are collected.
    public let windowRadius: TimeInterval

    /// Minimum RR intervals required for a valid entropy measurement.
    public let minimumRRCount: Int

    /// Duration of baseline window before dose (seconds).
    public let baselineWindowSeconds: TimeInterval

    /// Entropy calculator (shared with HRVAnalyzer for mathematical parity).
    private let entropyCalc: EntropyCalculator

    public init(
        binCount: Int = 32,
        windowRadius: TimeInterval = 300,       // ±5 minutes
        minimumRRCount: Int = 20,
        baselineWindowSeconds: TimeInterval = 1800  // 30 minutes
    ) {
        self.entropyCalc = EntropyCalculator(binCount: binCount)
        self.windowRadius = windowRadius
        self.minimumRRCount = minimumRRCount
        self.baselineWindowSeconds = baselineWindowSeconds
    }

    // MARK: - Single Dose Analysis

    /// Analyze entropy response around a single dose event.
    ///
    /// - Parameters:
    ///   - doseEvent: The medication dose event with timestamp.
    ///   - rrTimeSeries: Time-stamped RR intervals spanning pre-dose baseline through
    ///     post-dose observation period. Each element is (timestamp, rrInterval in ms).
    ///   - profile: Optional pharmacokinetic profile for curve matching.
    ///   - customWindows: Optional custom measurement windows (minutes post-dose).
    ///     Defaults to profile's analysis windows or a standard set.
    /// - Returns: DrugResponseResult, or nil if insufficient baseline data.
    public func analyze(
        doseEvent: DoseEventSummary,
        rrTimeSeries: [(timestamp: Date, rrInterval: Double)],
        profile: PharmacokineticProfile? = nil,
        customWindows: [Double]? = nil
    ) -> DrugResponseResult? {
        let doseTime = doseEvent.timestamp

        // 1. Compute baseline entropy from pre-dose window
        let baselineStart = doseTime.addingTimeInterval(-baselineWindowSeconds)
        let baselineRR = rrTimeSeries
            .filter { $0.timestamp >= baselineStart && $0.timestamp < doseTime }
            .map(\.rrInterval)

        guard baselineRR.count >= minimumRRCount else { return nil }

        let baselineEntropy = entropyCalc.shannonEntropy(baselineRR)

        // 2. Determine measurement windows
        let windows: [Double]
        if let custom = customWindows {
            windows = custom.sorted()
        } else if let prof = profile {
            windows = prof.analysisWindows
        } else {
            // Default windows: 15, 30, 60, 90, 120, 180, 240, 360 minutes
            windows = [15, 30, 60, 90, 120, 180, 240, 360]
        }

        // 3. Compute entropy at each post-dose window
        var measurements: [EntropyMeasurement] = []

        for windowMinutes in windows {
            let windowCenter = doseTime.addingTimeInterval(windowMinutes * 60)
            let windowStart = windowCenter.addingTimeInterval(-windowRadius)
            let windowEnd = windowCenter.addingTimeInterval(windowRadius)

            let windowRR = rrTimeSeries
                .filter { $0.timestamp >= windowStart && $0.timestamp <= windowEnd }
                .map(\.rrInterval)

            guard windowRR.count >= minimumRRCount else { continue }

            let entropy = entropyCalc.shannonEntropy(windowRR)
            let deltaH = entropy - baselineEntropy
            let coherence = entropyCalc.entropyToScore(entropy)

            measurements.append(EntropyMeasurement(
                minutesPostDose: windowMinutes,
                entropy: entropy,
                deltaH: deltaH,
                rrCount: windowRR.count,
                coherenceScore: coherence
            ))
        }

        guard !measurements.isEmpty else { return nil }

        // 4. Find peak ΔH (most extreme deviation from baseline)
        let peakMeasurement = measurements.max(by: { abs($0.deltaH) < abs($1.deltaH) })!

        // 5. Match against pharmacokinetic profile
        let matchResult: ProfileMatchResult?
        if let prof = profile {
            matchResult = matchProfile(
                profile: prof,
                peakDeltaH: peakMeasurement.deltaH,
                peakTimeMinutes: peakMeasurement.minutesPostDose,
                measurements: measurements
            )
        } else {
            matchResult = bestProfileMatch(
                peakDeltaH: peakMeasurement.deltaH,
                peakTimeMinutes: peakMeasurement.minutesPostDose,
                measurements: measurements
            )
        }

        return DrugResponseResult(
            doseEvent: doseEvent,
            baselineEntropy: baselineEntropy,
            baselineRRCount: baselineRR.count,
            measurements: measurements,
            peakDeltaH: peakMeasurement.deltaH,
            peakTimeMinutes: peakMeasurement.minutesPostDose,
            profileMatch: matchResult
        )
    }

    // MARK: - Batch Analysis

    /// Analyze multiple dose events and return individual results.
    /// Useful for building dose-response evidence across multiple administrations.
    public func analyzeBatch(
        doseEvents: [DoseEventSummary],
        rrTimeSeries: [(timestamp: Date, rrInterval: Double)],
        profile: PharmacokineticProfile? = nil
    ) -> [DrugResponseResult] {
        doseEvents.compactMap { event in
            analyze(
                doseEvent: event,
                rrTimeSeries: rrTimeSeries,
                profile: profile
            )
        }
    }

    /// Compute aggregate statistics across multiple dose-response results.
    ///
    /// The aggregate provides:
    /// - Mean ΔH: expected entropy shift for this substance
    /// - SD ΔH: measurement reliability
    /// - Cohen's d: standardized effect size (d > 0.8 = large, d > 1.2 = very large)
    /// - Detection rate: proportion of doses that produced measurable entropy change
    /// - Mean AUC: cumulative autonomic exposure per dose
    public func aggregate(_ results: [DrugResponseResult]) -> DrugResponseAggregate? {
        guard !results.isEmpty else { return nil }

        let n = results.count
        let deltas = results.map(\.peakDeltaH)
        let meanDelta = deltas.reduce(0, +) / Double(n)

        let variance: Double
        if n >= 2 {
            variance = deltas.reduce(0.0) { sum, val in
                sum + (val - meanDelta) * (val - meanDelta)
            } / Double(n - 1)
        } else {
            variance = 0
        }

        let peakTimes = results.map(\.peakTimeMinutes)
        let meanPeakTime = peakTimes.reduce(0, +) / Double(n)

        let effectSizes = results.map(\.effectSize)
        let meanEffect = effectSizes.reduce(0, +) / Double(n)

        let detected = results.filter(\.bindingDetected).count
        let detectionRate = Double(detected) / Double(n)

        let aucs = results.map(\.deltaHAUC)
        let meanAUC = aucs.reduce(0, +) / Double(n)

        return DrugResponseAggregate(
            medicationId: results.first?.doseEvent.medicationId ?? "",
            medicationName: results.first?.doseEvent.name.en ?? "",
            n: n,
            meanDeltaH: meanDelta,
            sdDeltaH: sqrt(variance),
            meanPeakTime: meanPeakTime,
            meanEffectSize: meanEffect,
            detectionRate: detectionRate,
            meanAUC: meanAUC
        )
    }

    // MARK: - Dose-Response Curve

    /// Analyze dose-response relationship: does higher dose produce larger |ΔH|?
    ///
    /// Groups results by dose value and computes mean |ΔH| per dose level.
    /// A positive correlation supports the hypothesis that entropy collapse
    /// is dose-dependent (analogous to FlexAID∆S showing stronger binding
    /// entropy at higher ligand concentrations).
    ///
    /// - Returns: Array of (dose, mean |ΔH|) pairs sorted by dose, plus Pearson r.
    public func doseResponseCurve(
        _ results: [DrugResponseResult]
    ) -> (points: [(dose: Double, meanAbsDeltaH: Double)], pearsonR: Double)? {
        guard results.count >= 3 else { return nil }

        // Group by dose value
        var groups: [Double: [Double]] = [:]
        for result in results {
            let dose = result.doseEvent.doseValue
            groups[dose, default: []].append(abs(result.peakDeltaH))
        }

        let points = groups.map { dose, deltas in
            (dose: dose, meanAbsDeltaH: deltas.reduce(0, +) / Double(deltas.count))
        }.sorted(by: { $0.dose < $1.dose })

        guard points.count >= 2 else { return (points: points, pearsonR: 0) }

        // Pearson correlation coefficient
        let doses = points.map(\.dose)
        let deltas = points.map(\.meanAbsDeltaH)
        let r = pearsonCorrelation(doses, deltas)

        return (points: points, pearsonR: r)
    }

    // MARK: - Profile Matching

    /// Match observed ΔH curve against a specific pharmacokinetic profile.
    private func matchProfile(
        profile: PharmacokineticProfile,
        peakDeltaH: Double,
        peakTimeMinutes: Double,
        measurements: [EntropyMeasurement]
    ) -> ProfileMatchResult {
        // Direction match: sympathomimetic → negative ΔH, parasympathomimetic → positive
        let directionMatch: Bool
        switch profile.mechanism {
        case .sympathomimetic:
            directionMatch = peakDeltaH < 0
        case .parasympathomimetic:
            directionMatch = peakDeltaH > 0
        case .mixed, .unknown:
            directionMatch = true // any direction acceptable
        }

        // ΔH magnitude within expected range
        let deltaHInRange = profile.expectedDeltaHRange.contains(peakDeltaH)

        // Timing match: peak within 50% of expected Tmax
        let timingTolerance = profile.tmaxMinutes * 0.5
        let timingMatch = abs(peakTimeMinutes - profile.tmaxMinutes) <= timingTolerance

        // Confidence score (0–1) with weighted components
        var confidence = 0.0

        // Direction: 40% weight (most important — wrong direction strongly contradicts)
        if directionMatch { confidence += 0.4 }

        // ΔH magnitude: 35% weight
        if deltaHInRange {
            confidence += 0.35
        } else {
            // Partial credit: how close to the expected range?
            let rangeCenter = (profile.expectedDeltaHRange.lowerBound +
                               profile.expectedDeltaHRange.upperBound) / 2
            let rangeWidth = profile.expectedDeltaHRange.upperBound -
                             profile.expectedDeltaHRange.lowerBound
            let distance = abs(peakDeltaH - rangeCenter) / max(rangeWidth, 0.1)
            confidence += max(0, 0.35 * (1 - distance / 3))
        }

        // Timing: 25% weight
        if timingMatch {
            confidence += 0.25
        } else {
            let timingDistance = abs(peakTimeMinutes - profile.tmaxMinutes) / max(profile.tmaxMinutes, 1)
            confidence += max(0, 0.25 * (1 - timingDistance))
        }

        return ProfileMatchResult(
            profile: profile,
            confidence: confidence,
            deltaHInRange: deltaHInRange,
            timingMatch: timingMatch,
            directionMatch: directionMatch
        )
    }

    /// Try all known profiles and return the best match (if confidence > 0.5).
    private func bestProfileMatch(
        peakDeltaH: Double,
        peakTimeMinutes: Double,
        measurements: [EntropyMeasurement]
    ) -> ProfileMatchResult? {
        let matches = PharmacokineticProfile.knownProfiles.map { profile in
            matchProfile(
                profile: profile,
                peakDeltaH: peakDeltaH,
                peakTimeMinutes: peakTimeMinutes,
                measurements: measurements
            )
        }

        guard let best = matches.max(by: { $0.confidence < $1.confidence }),
              best.confidence > 0.5 else {
            return nil
        }

        return best
    }

    // MARK: - Statistics Helpers

    /// Pearson correlation coefficient between two arrays.
    /// Filters out non-finite value pairs before computation.
    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        guard x.count >= 2, x.count == y.count else { return 0 }

        // Filter pairs where both values are finite
        var cleanX: [Double] = []
        var cleanY: [Double] = []
        for i in 0..<x.count {
            if x[i].isFinite && y[i].isFinite {
                cleanX.append(x[i])
                cleanY.append(y[i])
            }
        }

        let n = Double(cleanX.count)
        guard n >= 2 else { return 0 }

        let meanX = cleanX.reduce(0, +) / n
        let meanY = cleanY.reduce(0, +) / n

        var sumXY = 0.0
        var sumX2 = 0.0
        var sumY2 = 0.0

        for i in 0..<cleanX.count {
            let dx = cleanX[i] - meanX
            let dy = cleanY[i] - meanY
            sumXY += dx * dy
            sumX2 += dx * dx
            sumY2 += dy * dy
        }

        let denom = sqrt(sumX2 * sumY2)
        guard denom > 0 else { return 0 }
        return sumXY / denom
    }
}
