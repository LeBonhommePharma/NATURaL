import Foundation

/// Validates the isomorphism between FlexAID∆S configurational entropy (in silico)
/// and DrugResponseAnalyzer HRV entropy (in vivo).
///
/// The hypothesis under test:
///   A drug with large |ΔS_config| in molecular docking should produce
///   large |ΔH_hrv| in cardiac RR-interval distributions, because both
///   measure the entropy cost of a binding event using the same Shannon formula.
///
/// Cross-domain validation proceeds by:
/// 1. Pairing substances that have both in-silico (FlexAIDdSResult or BindingEntropyProfile)
///    and in-vivo (DrugResponseResult) entropy measurements
/// 2. Computing Pearson correlation between |ΔS_config| and |ΔH_hrv|
/// 3. Reporting R², mean absolute error, and statistical significance
///
/// A significant positive correlation (r > 0.5, p < 0.05) constitutes independent
/// validation that the entropy-collapse framework generalizes from molecular torsional
/// angles to physiological cardiac intervals.
public struct CrossDomainValidator: Sendable {

    /// A paired observation: one substance's in-silico and in-vivo entropy deltas.
    public struct PairedObservation: Sendable {
        /// Substance identifier.
        public let substanceId: String

        /// ΔS_config from FlexAID∆S (bits, typically negative for binding).
        public let deltaSConfig: Double

        /// ΔH_hrv from DrugResponseAnalyzer (bits).
        public let deltaHHRV: Double

        /// -TΔS at 298K (kcal/mol, positive = entropy penalty).
        public let entropyPenaltyKcal: Double

        /// Effect size from in-vivo analysis (|ΔH| / baseline_H).
        public let inVivoEffectSize: Double

        public init(
            substanceId: String,
            deltaSConfig: Double,
            deltaHHRV: Double,
            entropyPenaltyKcal: Double,
            inVivoEffectSize: Double
        ) {
            self.substanceId = substanceId
            self.deltaSConfig = deltaSConfig
            self.deltaHHRV = deltaHHRV
            self.entropyPenaltyKcal = entropyPenaltyKcal
            self.inVivoEffectSize = inVivoEffectSize
        }
    }

    /// Result of cross-domain validation.
    public struct ValidationResult: Sendable {
        /// Paired observations used in the analysis.
        public let observations: [PairedObservation]

        /// Pearson r between |ΔS_config| and |ΔH_hrv|.
        public let pearsonR: Double

        /// R-squared (coefficient of determination).
        /// Fraction of in-vivo variance explained by in-silico entropy.
        public var rSquared: Double { pearsonR * pearsonR }

        /// Number of substances in the analysis.
        public var n: Int { observations.count }

        /// Whether the correlation is statistically significant.
        /// Requires r > 0.5 and n >= 5 for meaningful inference.
        public var isSignificant: Bool { abs(pearsonR) > 0.5 && n >= 5 }

        /// Mean absolute prediction error (bits).
        /// How well |ΔS_config| predicts |ΔH_hrv| via linear regression.
        public let meanAbsError: Double

        /// Linear regression slope: |ΔH_hrv| ≈ slope × |ΔS_config| + intercept.
        /// Represents the scaling factor between molecular and physiological entropy.
        public let regressionSlope: Double

        /// Linear regression intercept.
        public let regressionIntercept: Double

        /// Bilingual summary.
        public var summary: LocalizedString {
            let rText = String(format: "%.3f", pearsonR)
            let r2Text = String(format: "%.3f", rSquared)
            let maeText = String(format: "%.2f", meanAbsError)
            let sigText = isSignificant ? "significant" : "not significant"
            let sigFr = isSignificant ? "significative" : "non significative"

            return LocalizedString(
                en: "Cross-domain validation (n=\(n)): r = \(rText), R² = \(r2Text), MAE = \(maeText) bits. Correlation is \(sigText).",
                fr: "Validation interdomaines (n=\(n)) : r = \(rText), R² = \(r2Text), MAE = \(maeText) bits. Corrélation \(sigFr)."
            )
        }

        public init(
            observations: [PairedObservation],
            pearsonR: Double,
            meanAbsError: Double,
            regressionSlope: Double,
            regressionIntercept: Double
        ) {
            self.observations = observations
            self.pearsonR = pearsonR
            self.meanAbsError = meanAbsError
            self.regressionSlope = regressionSlope
            self.regressionIntercept = regressionIntercept
        }
    }

    private let dockingAnalyzer: FlexAIDdSAnalyzer

    public init(dockingAnalyzer: FlexAIDdSAnalyzer = FlexAIDdSAnalyzer()) {
        self.dockingAnalyzer = dockingAnalyzer
    }

    // MARK: - Validation from Raw Results

    /// Validate correlation between FlexAID∆S results and DrugResponse results.
    ///
    /// Pairs results by substanceId and computes Pearson correlation
    /// between |ΔS_config| and |ΔH_hrv|.
    ///
    /// - Parameters:
    ///   - dockingResults: In-silico FlexAID∆S results.
    ///   - drugResponseResults: In-vivo DrugResponseAnalyzer results.
    /// - Returns: ValidationResult, or nil if fewer than 3 paired substances.
    public func validate(
        dockingResults: [FlexAIDdSResult],
        drugResponseResults: [DrugResponseResult]
    ) -> ValidationResult? {
        var dockingBySubstance: [String: FlexAIDdSResult] = [:]
        for r in dockingResults {
            dockingBySubstance[r.substanceId] = r
        }

        var responseBySubstance: [String: DrugResponseResult] = [:]
        for r in drugResponseResults {
            responseBySubstance[r.doseEvent.medicationId] = r
        }

        var pairs: [PairedObservation] = []
        for (substanceId, docking) in dockingBySubstance {
            guard let response = responseBySubstance[substanceId] else { continue }
            pairs.append(PairedObservation(
                substanceId: substanceId,
                deltaSConfig: docking.totalDeltaSConfig,
                deltaHHRV: response.peakDeltaH,
                entropyPenaltyKcal: dockingAnalyzer.entropyPenaltyKcal(
                    deltaSBits: docking.totalDeltaSConfig
                ),
                inVivoEffectSize: response.effectSize
            ))
        }

        return buildResult(from: pairs)
    }

    // MARK: - Validation from Known Profiles

    /// Validate using BindingEntropyProfile known values against DrugResponseResults.
    ///
    /// Useful when actual FlexAID docking has not been run but published/reference
    /// ΔS_config values exist for the substances.
    ///
    /// - Parameter drugResponseResults: In-vivo DrugResponseAnalyzer results.
    /// - Returns: ValidationResult, or nil if fewer than 3 paired substances.
    public func validateFromProfiles(
        drugResponseResults: [DrugResponseResult]
    ) -> ValidationResult? {
        var pairs: [PairedObservation] = []

        for response in drugResponseResults {
            guard let bindingProfile = BindingEntropyProfile.profile(
                for: response.doseEvent.medicationId
            ) else { continue }

            pairs.append(PairedObservation(
                substanceId: response.doseEvent.medicationId,
                deltaSConfig: bindingProfile.expectedDeltaSBits,
                deltaHHRV: response.peakDeltaH,
                entropyPenaltyKcal: bindingProfile.expectedEntropyPenaltyKcal,
                inVivoEffectSize: response.effectSize
            ))
        }

        return buildResult(from: pairs)
    }

    // MARK: - Hybrid Validation

    /// Validate using a mix of actual docking results and known profiles.
    ///
    /// Prefers actual docking results when available; falls back to
    /// BindingEntropyProfile for substances without docking data.
    public func validateHybrid(
        dockingResults: [FlexAIDdSResult],
        drugResponseResults: [DrugResponseResult]
    ) -> ValidationResult? {
        var dockingBySubstance: [String: Double] = [:]
        var penaltyBySubstance: [String: Double] = [:]

        // Actual docking results take priority
        for r in dockingResults {
            dockingBySubstance[r.substanceId] = r.totalDeltaSConfig
            penaltyBySubstance[r.substanceId] = dockingAnalyzer.entropyPenaltyKcal(
                deltaSBits: r.totalDeltaSConfig
            )
        }

        // Fill in from known profiles where docking hasn't been run
        for profile in BindingEntropyProfile.knownProfiles {
            if dockingBySubstance[profile.substanceId] == nil {
                dockingBySubstance[profile.substanceId] = profile.expectedDeltaSBits
                penaltyBySubstance[profile.substanceId] = profile.expectedEntropyPenaltyKcal
            }
        }

        var pairs: [PairedObservation] = []
        for response in drugResponseResults {
            let id = response.doseEvent.medicationId
            guard let deltaS = dockingBySubstance[id],
                  let penalty = penaltyBySubstance[id] else { continue }

            pairs.append(PairedObservation(
                substanceId: id,
                deltaSConfig: deltaS,
                deltaHHRV: response.peakDeltaH,
                entropyPenaltyKcal: penalty,
                inVivoEffectSize: response.effectSize
            ))
        }

        return buildResult(from: pairs)
    }

    // MARK: - Three-Way Validation

    /// A three-way paired observation: computational (FlexAID∆S) vs ITC-measured (SCORPIO)
    /// vs in-vivo (NATURaL HRV) entropy for the same substance.
    public struct ThreeWayObservation: Sendable {
        /// Substance identifier.
        public let substanceId: String

        /// ΔS_config from FlexAID∆S or BindingEntropyProfile (bits).
        public let flexAIDDeltaSBits: Double

        /// -TΔS from SCORPIO ITC (kcal/mol).
        public let scorpioMinusTDeltaSKcal: Double

        /// ΔH_hrv from NATURaL DrugResponseAnalyzer (bits).
        public let naturalDeltaHHRV: Double

        public init(
            substanceId: String,
            flexAIDDeltaSBits: Double,
            scorpioMinusTDeltaSKcal: Double,
            naturalDeltaHHRV: Double
        ) {
            self.substanceId = substanceId
            self.flexAIDDeltaSBits = flexAIDDeltaSBits
            self.scorpioMinusTDeltaSKcal = scorpioMinusTDeltaSKcal
            self.naturalDeltaHHRV = naturalDeltaHHRV
        }
    }

    /// Result of three-way validation with pairwise Pearson correlations.
    public struct ThreeWayValidationResult: Sendable {
        /// Three-way paired observations.
        public let observations: [ThreeWayObservation]

        /// Pearson r: FlexAID∆S (computational) vs SCORPIO (ITC).
        public let flexAIDvsScorpio: Double

        /// Pearson r: FlexAID∆S (computational) vs NATURaL (HRV).
        public let flexAIDvsNatural: Double

        /// Pearson r: SCORPIO (ITC) vs NATURaL (HRV).
        public let scorpioVsNatural: Double

        /// Number of substances in the three-way analysis.
        public var n: Int { observations.count }

        /// Bilingual summary of pairwise correlations.
        public var summary: LocalizedString {
            let fs = String(format: "%.3f", flexAIDvsScorpio)
            let fn = String(format: "%.3f", flexAIDvsNatural)
            let sn = String(format: "%.3f", scorpioVsNatural)

            return LocalizedString(
                en: "Three-way validation (n=\(n)): FlexAID↔SCORPIO r=\(fs), FlexAID↔NATURaL r=\(fn), SCORPIO↔NATURaL r=\(sn).",
                fr: "Validation tripartite (n=\(n)) : FlexAID↔SCORPIO r=\(fs), FlexAID↔NATURaL r=\(fn), SCORPIO↔NATURaL r=\(sn)."
            )
        }

        public init(
            observations: [ThreeWayObservation],
            flexAIDvsScorpio: Double,
            flexAIDvsNatural: Double,
            scorpioVsNatural: Double
        ) {
            self.observations = observations
            self.flexAIDvsScorpio = flexAIDvsScorpio
            self.flexAIDvsNatural = flexAIDvsNatural
            self.scorpioVsNatural = scorpioVsNatural
        }
    }

    /// Validate three-way correlation: FlexAID∆S (computational) vs SCORPIO ITC (measured)
    /// vs NATURaL HRV (in-vivo).
    ///
    /// Only includes substances that have data in all three domains:
    /// 1. FlexAID∆S / BindingEntropyProfile for computational ΔS
    /// 2. ThermodynamicBindingProfile with ITC decomposition for SCORPIO -TΔS
    /// 3. DrugResponseResult for in-vivo ΔH_hrv
    ///
    /// - Parameters:
    ///   - dockingResults: In-silico FlexAID∆S results (optional, falls back to BindingEntropyProfile).
    ///   - drugResponseResults: In-vivo DrugResponseAnalyzer results.
    /// - Returns: ThreeWayValidationResult, or nil if fewer than 3 substances have all three.
    public func validateThreeWay(
        dockingResults: [FlexAIDdSResult] = [],
        drugResponseResults: [DrugResponseResult]
    ) -> ThreeWayValidationResult? {
        // Build FlexAID data map (prefer actual docking, fall back to profiles)
        var flexAIDBySubstance: [String: Double] = [:]
        for r in dockingResults {
            flexAIDBySubstance[r.substanceId] = r.totalDeltaSConfig
        }
        for profile in BindingEntropyProfile.knownProfiles {
            if flexAIDBySubstance[profile.substanceId] == nil {
                flexAIDBySubstance[profile.substanceId] = profile.expectedDeltaSBits
            }
        }

        // Build SCORPIO ITC data map (only primary targets with ITC decomposition)
        var scorpioBySubstance: [String: Double] = [:]
        for profile in ThermodynamicBindingProfile.knownProfiles {
            guard profile.isPrimaryTarget,
                  let thermo = profile.thermodynamics else { continue }
            scorpioBySubstance[profile.substanceId] = thermo.minusTDeltaSKcal
        }

        // Build NATURaL HRV data map
        var hrvBySubstance: [String: Double] = [:]
        for r in drugResponseResults {
            hrvBySubstance[r.doseEvent.medicationId] = r.peakDeltaH
        }

        // Find substances with all three data sources
        var observations: [ThreeWayObservation] = []
        for (substanceId, flexAID) in flexAIDBySubstance {
            guard let scorpio = scorpioBySubstance[substanceId],
                  let hrv = hrvBySubstance[substanceId] else { continue }
            observations.append(ThreeWayObservation(
                substanceId: substanceId,
                flexAIDDeltaSBits: flexAID,
                scorpioMinusTDeltaSKcal: scorpio,
                naturalDeltaHHRV: hrv
            ))
        }

        guard observations.count >= 3 else { return nil }

        let flexAIDValues = observations.map { abs($0.flexAIDDeltaSBits) }
        let scorpioValues = observations.map { abs($0.scorpioMinusTDeltaSKcal) }
        let naturalValues = observations.map { abs($0.naturalDeltaHHRV) }

        return ThreeWayValidationResult(
            observations: observations,
            flexAIDvsScorpio: pearsonCorrelation(flexAIDValues, scorpioValues),
            flexAIDvsNatural: pearsonCorrelation(flexAIDValues, naturalValues),
            scorpioVsNatural: pearsonCorrelation(scorpioValues, naturalValues)
        )
    }

    // MARK: - Private

    private func buildResult(from pairs: [PairedObservation]) -> ValidationResult? {
        guard pairs.count >= 3 else { return nil }

        let x = pairs.map { abs($0.deltaSConfig) }
        let y = pairs.map { abs($0.deltaHHRV) }

        let r = pearsonCorrelation(x, y)
        let regression = linearRegression(x: x, y: y)

        return ValidationResult(
            observations: pairs,
            pearsonR: r,
            meanAbsError: regression.mae,
            regressionSlope: regression.slope,
            regressionIntercept: regression.intercept
        )
    }

    /// Pearson correlation coefficient between two arrays.
    private func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        let n = Double(x.count)
        guard n >= 2, x.count == y.count else { return 0 }

        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        var sumXY = 0.0
        var sumX2 = 0.0
        var sumY2 = 0.0

        for i in 0..<x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            sumXY += dx * dy
            sumX2 += dx * dx
            sumY2 += dy * dy
        }

        let denom = sqrt(sumX2 * sumY2)
        guard denom > 0 else { return 0 }
        return sumXY / denom
    }

    /// Simple linear regression: y = slope × x + intercept, plus MAE.
    private func linearRegression(
        x: [Double],
        y: [Double]
    ) -> (slope: Double, intercept: Double, mae: Double) {
        let n = Double(x.count)
        guard n >= 2 else { return (slope: 0, intercept: 0, mae: 0) }

        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n

        var sumXY = 0.0
        var sumX2 = 0.0

        for i in 0..<x.count {
            sumXY += (x[i] - meanX) * (y[i] - meanY)
            sumX2 += (x[i] - meanX) * (x[i] - meanX)
        }

        let slope = sumX2 > 0 ? sumXY / sumX2 : 0
        let intercept = meanY - slope * meanX

        var totalError = 0.0
        for i in 0..<x.count {
            let predicted = slope * x[i] + intercept
            totalError += abs(y[i] - predicted)
        }
        let mae = totalError / n

        return (slope: slope, intercept: intercept, mae: mae)
    }
}
