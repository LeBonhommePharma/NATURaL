import Foundation
#if BONHOMME_ACCEL
import BonhommeAccelSwift
#endif

/// Exploratory association between molecular configurational-model entropy and
/// HRV-distribution entropy. Sharing the Shannon formula does not establish that
/// these quantities measure the same process or identify receptor binding.
///
/// Pearson r and its nominal two-tailed p-value describe the supplied sample.
/// They do not establish causality, independent validation, or generalization.
/// MAE is an in-sample regression residual, not held-out prediction performance.
public struct CrossDomainValidator: Sendable {

    public enum MolecularInputSource: String, Sendable {
        case dockingResult
        case unverifiedCatalog
        case unspecified
    }

    /// A paired observation: one substance's in-silico and in-vivo entropy deltas.
    public struct PairedObservation: Sendable {
        /// Substance identifier.
        public let substanceId: String

        /// Provenance of the molecular input; never inferred from its numeric value.
        public let molecularSource: MolecularInputSource

        /// Molecular configurational-model entropy (bits).
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
            inVivoEffectSize: Double,
            molecularSource: MolecularInputSource = .unspecified
        ) {
            self.molecularSource = molecularSource
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

        /// Two-tailed p-value for the Pearson correlation.
        /// Computed via t-distribution: t = r × √(n-2) / √(1-r²).
        public let pValue: Double

        /// R-squared (coefficient of determination).
        /// In-sample linear association; not a causal or held-out validation metric.
        public var rSquared: Double { pearsonR * pearsonR }

        /// Number of substances in the analysis.
        public var n: Int { observations.count }

        /// p-value threshold for statistical significance (from AnalysisConfiguration).
        public let significanceLevel: Double

        /// Minimum paired observations required for significance (from AnalysisConfiguration).
        public let minPairs: Int

        /// Whether the correlation is statistically significant.
        /// Uses proper p-value testing against the configured significance level.
        public var isSignificant: Bool {
            pValue < significanceLevel && n >= minPairs
        }

        /// Mean absolute in-sample regression residual (bits).
        public let meanAbsError: Double

        /// Linear regression slope: |ΔH_hrv| ≈ slope × |ΔS_config| + intercept.
        /// Represents the scaling factor between molecular and physiological entropy.
        public let regressionSlope: Double

        /// Linear regression intercept.
        public let regressionIntercept: Double

        public var dockingPairCount: Int { observations.filter { $0.molecularSource == .dockingResult }.count }
        public var catalogPairCount: Int { observations.filter { $0.molecularSource == .unverifiedCatalog }.count }
        public var unspecifiedPairCount: Int { observations.filter { $0.molecularSource == .unspecified }.count }

        /// Summary of nominal association and explicit molecular input provenance.
        public var summary: LocalizedString {
            let rText = String(format: "%.3f", pearsonR)
            let r2Text = String(format: "%.3f", rSquared)
            let pText = String(format: "%.4f", pValue)
            let maeText = String(format: "%.2f", meanAbsError)
            let sigText = isSignificant ? "significant" : "not significant"
            let sigFr = isSignificant ? "significative" : "non significative"

            let sigEs = isSignificant ? "significativa" : "no significativa"
            let sigJa = isSignificant ? "有意" : "非有意"
            let sigZh = isSignificant ? "显著" : "不显著"
            let sigKo = isSignificant ? "유의미함" : "유의미하지 않음"
            let sigRu = isSignificant ? "значимая" : "незначимая"
            let sigDe = isSignificant ? "signifikant" : "nicht signifikant"
            let sigAr = isSignificant ? "ذات دلالة إحصائية" : "غير ذات دلالة إحصائية"

            return LocalizedString(
                en: "Exploratory association (n=\(n)): r = \(rText), R² = \(r2Text), p = \(pText), MAE (in-sample) = \(maeText) bits. Correlation is \(sigText). Molecular inputs: \(dockingPairCount) docking, \(catalogPairCount) unverified catalog, \(unspecifiedPairCount) unspecified. Nominal p-value; no causal validation.",
                fr: "Association exploratoire (n=\(n)) : r = \(rText), R² = \(r2Text), p = \(pText), MAE (dans l’échantillon) = \(maeText) bits. Corrélation \(sigFr). Entrées moléculaires : \(dockingPairCount) amarrage, \(catalogPairCount) catalogue non vérifié, \(unspecifiedPairCount) non précisées. Valeur p nominale ; aucune validation causale.",
                es: "Asociación exploratoria (n=\(n)): r = \(rText), R² = \(r2Text), p = \(pText), MAE (en la muestra) = \(maeText) bits. Correlación \(sigEs). Entradas moleculares: \(dockingPairCount) acoplamiento, \(catalogPairCount) catálogo sin verificar, \(unspecifiedPairCount) sin especificar. Valor p nominal; sin validación causal.",
                ja: "探索的関連（n=\(n)）：r = \(rText)、R² = \(r2Text)、p = \(pText)、MAE (標本内) = \(maeText) ビット。相関は\(sigJa)。 分子入力：ドッキング \(dockingPairCount)、未検証カタログ \(catalogPairCount)、不明 \(unspecifiedPairCount)。名目上のp値であり、因果関係の検証ではありません。",
                zh: "探索性关联（n=\(n)）：r = \(rText)，R² = \(r2Text)，p = \(pText)，MAE (样本内) = \(maeText) 比特。相关性\(sigZh)。 分子输入：对接 \(dockingPairCount)，未核实目录 \(catalogPairCount)，未指定 \(unspecifiedPairCount)。名义p值，不构成因果验证。",
                ko: "탐색적 연관성 (n=\(n)): r = \(rText), R² = \(r2Text), p = \(pText), MAE (표본 내) = \(maeText) 비트. 상관관계 \(sigKo). 분자 입력: 도킹 \(dockingPairCount), 미검증 목록 \(catalogPairCount), 미지정 \(unspecifiedPairCount). 명목 p값이며 인과 검증이 아닙니다.",
                ru: "Исследовательская связь (n=\(n)): r = \(rText), R² = \(r2Text), p = \(pText), MAE (на обучающей выборке) = \(maeText) бит. Корреляция \(sigRu). Молекулярные данные: докинг \(dockingPairCount), непроверенный каталог \(catalogPairCount), не указано \(unspecifiedPairCount). Номинальное p; причинность не подтверждена.",
                de: "Explorative Assoziation (n=\(n)): r = \(rText), R² = \(r2Text), p = \(pText), MAE (in der Stichprobe) = \(maeText) Bits. Korrelation \(sigDe). Molekulare Eingaben: \(dockingPairCount) Docking, \(catalogPairCount) ungeprüfter Katalog, \(unspecifiedPairCount) unbestimmt. Nominaler p-Wert; keine kausale Validierung.",
                ar: "ارتباط استكشافي (n=\(n)): r = \(rText)، R² = \(r2Text)، p = \(pText)، MAE (داخل العينة) = \(maeText) بت. الارتباط \(sigAr). المدخلات الجزيئية: \(dockingPairCount) إرساء، \(catalogPairCount) كتالوج غير متحقق، \(unspecifiedPairCount) غير محدد. قيمة p اسمية؛ لا تحقق سببي."
            )
        }

        public init(
            observations: [PairedObservation],
            pearsonR: Double,
            pValue: Double,
            meanAbsError: Double,
            regressionSlope: Double,
            regressionIntercept: Double,
            significanceLevel: Double = AnalysisConfiguration.default.crossDomainSignificanceLevel,
            minPairs: Int = AnalysisConfiguration.default.crossDomainMinPairs
        ) {
            self.observations = observations
            self.pearsonR = pearsonR
            self.pValue = pValue
            self.meanAbsError = meanAbsError
            self.regressionSlope = regressionSlope
            self.regressionIntercept = regressionIntercept
            self.significanceLevel = significanceLevel
            self.minPairs = minPairs
        }
    }

    private let dockingAnalyzer: FlexAIDdSAnalyzer
    private let configuration: AnalysisConfiguration

    public init(dockingAnalyzer: FlexAIDdSAnalyzer = FlexAIDdSAnalyzer()) {
        self.dockingAnalyzer = dockingAnalyzer
        self.configuration = .default
    }

    public init(configuration: AnalysisConfiguration, dockingAnalyzer: FlexAIDdSAnalyzer = FlexAIDdSAnalyzer()) {
        self.dockingAnalyzer = dockingAnalyzer
        self.configuration = configuration
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
    /// - Returns: ValidationResult, or nil if fewer than `crossDomainMinPairs` paired substances.
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
                inVivoEffectSize: response.effectSize,
                molecularSource: .dockingResult
            ))
        }

        return buildResult(from: pairs)
    }

    // MARK: - Validation from Known Profiles

    /// Compare unverified catalog estimates with DrugResponseResults.
    ///
    /// Catalog inputs are not actual docking runs or independently verified measurements.
    ///
    /// - Parameter drugResponseResults: In-vivo DrugResponseAnalyzer results.
    /// - Returns: ValidationResult, or nil if fewer than `crossDomainMinPairs` paired substances.
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
                inVivoEffectSize: response.effectSize,
                molecularSource: .unverifiedCatalog
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
        let actualDockingIDs = Set(dockingResults.map(\.substanceId))
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
                inVivoEffectSize: response.effectSize,
                molecularSource: actualDockingIDs.contains(id) ? .dockingResult : .unverifiedCatalog
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

    /// Result of three-way validation with pairwise Pearson correlations and p-values.
    public struct ThreeWayValidationResult: Sendable {
        /// Three-way paired observations.
        public let observations: [ThreeWayObservation]

        /// Pearson r: FlexAID∆S (computational) vs SCORPIO (ITC).
        public let flexAIDvsScorpio: Double

        /// Two-tailed p-value for FlexAID vs SCORPIO (t-distribution / incomplete beta).
        public let flexAIDvsScorpioPValue: Double

        /// Pearson r: FlexAID∆S (computational) vs NATURaL (HRV).
        public let flexAIDvsNatural: Double

        /// Two-tailed p-value for FlexAID vs NATURaL.
        public let flexAIDvsNaturalPValue: Double

        /// Pearson r: SCORPIO (ITC) vs NATURaL (HRV).
        public let scorpioVsNatural: Double

        /// Two-tailed p-value for SCORPIO vs NATURaL.
        public let scorpioVsNaturalPValue: Double

        /// Number of substances in the three-way analysis.
        public var n: Int { observations.count }

        /// Bilingual summary of pairwise correlations and p-values.
        public var summary: LocalizedString {
            let fs = String(format: "%.3f", flexAIDvsScorpio)
            let fn = String(format: "%.3f", flexAIDvsNatural)
            let sn = String(format: "%.3f", scorpioVsNatural)
            let pfs = String(format: "%.4f", flexAIDvsScorpioPValue)
            let pfn = String(format: "%.4f", flexAIDvsNaturalPValue)
            let psn = String(format: "%.4f", scorpioVsNaturalPValue)

            return LocalizedString(
                en: "Three-way validation (n=\(n)): FlexAID↔SCORPIO r=\(fs) (p=\(pfs)), FlexAID↔NATURaL r=\(fn) (p=\(pfn)), SCORPIO↔NATURaL r=\(sn) (p=\(psn)).",
                fr: "Validation tripartite (n=\(n)) : FlexAID↔SCORPIO r=\(fs) (p=\(pfs)), FlexAID↔NATURaL r=\(fn) (p=\(pfn)), SCORPIO↔NATURaL r=\(sn) (p=\(psn)).",
                es: "Validación tripartita (n=\(n)): FlexAID↔SCORPIO r=\(fs) (p=\(pfs)), FlexAID↔NATURaL r=\(fn) (p=\(pfn)), SCORPIO↔NATURaL r=\(sn) (p=\(psn)).",
                ja: "三者間検証（n=\(n)）：FlexAID↔SCORPIO r=\(fs) (p=\(pfs))、FlexAID↔NATURaL r=\(fn) (p=\(pfn))、SCORPIO↔NATURaL r=\(sn) (p=\(psn))。",
                zh: "三方验证（n=\(n)）：FlexAID↔SCORPIO r=\(fs) (p=\(pfs))，FlexAID↔NATURaL r=\(fn) (p=\(pfn))，SCORPIO↔NATURaL r=\(sn) (p=\(psn))。",
                ko: "삼자 검증 (n=\(n)): FlexAID↔SCORPIO r=\(fs) (p=\(pfs)), FlexAID↔NATURaL r=\(fn) (p=\(pfn)), SCORPIO↔NATURaL r=\(sn) (p=\(psn)).",
                ru: "Трёхсторонняя валидация (n=\(n)): FlexAID↔SCORPIO r=\(fs) (p=\(pfs)), FlexAID↔NATURaL r=\(fn) (p=\(pfn)), SCORPIO↔NATURaL r=\(sn) (p=\(psn)).",
                de: "Drei-Wege-Validierung (n=\(n)): FlexAID↔SCORPIO r=\(fs) (p=\(pfs)), FlexAID↔NATURaL r=\(fn) (p=\(pfn)), SCORPIO↔NATURaL r=\(sn) (p=\(psn)).",
                ar: "التحقق الثلاثي (n=\(n)): FlexAID↔SCORPIO r=\(fs) (p=\(pfs))، FlexAID↔NATURaL r=\(fn) (p=\(pfn))، SCORPIO↔NATURaL r=\(sn) (p=\(psn))."
            )
        }

        public init(
            observations: [ThreeWayObservation],
            flexAIDvsScorpio: Double,
            flexAIDvsScorpioPValue: Double,
            flexAIDvsNatural: Double,
            flexAIDvsNaturalPValue: Double,
            scorpioVsNatural: Double,
            scorpioVsNaturalPValue: Double
        ) {
            self.observations = observations
            self.flexAIDvsScorpio = flexAIDvsScorpio
            self.flexAIDvsScorpioPValue = flexAIDvsScorpioPValue
            self.flexAIDvsNatural = flexAIDvsNatural
            self.flexAIDvsNaturalPValue = flexAIDvsNaturalPValue
            self.scorpioVsNatural = scorpioVsNatural
            self.scorpioVsNaturalPValue = scorpioVsNaturalPValue
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

        guard observations.count >= configuration.crossDomainMinPairs else { return nil }

        let flexAIDValues = observations.map { abs($0.flexAIDDeltaSBits) }
        let scorpioValues = observations.map { abs($0.scorpioMinusTDeltaSKcal) }
        let naturalValues = observations.map { abs($0.naturalDeltaHHRV) }
        let n = observations.count

        let rFS = pearsonCorrelation(flexAIDValues, scorpioValues)
        let rFN = pearsonCorrelation(flexAIDValues, naturalValues)
        let rSN = pearsonCorrelation(scorpioValues, naturalValues)

        return ThreeWayValidationResult(
            observations: observations,
            flexAIDvsScorpio: rFS,
            flexAIDvsScorpioPValue: Self.computePValue(r: rFS, n: n),
            flexAIDvsNatural: rFN,
            flexAIDvsNaturalPValue: Self.computePValue(r: rFN, n: n),
            scorpioVsNatural: rSN,
            scorpioVsNaturalPValue: Self.computePValue(r: rSN, n: n)
        )
    }

    // MARK: - Private

    private func buildResult(from pairs: [PairedObservation]) -> ValidationResult? {
        guard pairs.count >= configuration.crossDomainMinPairs else { return nil }

        // One pair per substance, matching validate(dockingResults:...). Repeated
        // doses must not inflate the substance count or nominal degrees of freedom.
        // Keep the last supplied pair; callers control ordering, not timestamp inference.
        var bySubstance: [String: PairedObservation] = [:]
        for pair in pairs { bySubstance[pair.substanceId] = pair }
        let cleanPairs = bySubstance.values.filter {
            $0.deltaSConfig.isFinite && $0.deltaHHRV.isFinite
        }.sorted { $0.substanceId < $1.substanceId }
        guard cleanPairs.count >= configuration.crossDomainMinPairs else { return nil }

        let x = cleanPairs.map { abs($0.deltaSConfig) }
        let y = cleanPairs.map { abs($0.deltaHHRV) }

        let r = pearsonCorrelation(x, y)

        let regression = linearRegression(x: x, y: y)

        let p = Self.computePValue(r: r, n: cleanPairs.count)

        return ValidationResult(
            observations: cleanPairs,
            pearsonR: r,
            pValue: p,
            meanAbsError: regression.mae,
            regressionSlope: regression.slope,
            regressionIntercept: regression.intercept,
            significanceLevel: configuration.crossDomainSignificanceLevel,
            minPairs: configuration.crossDomainMinPairs
        )
    }

    // MARK: - Statistical Significance

    /// Compute two-tailed p-value for Pearson r using the t-distribution.
    ///
    /// Delegates to C++ accelerator when available, with Swift fallback.
    static func computePValue(r: Double, n: Int) -> Double {
        #if BONHOMME_ACCEL
        if let pval = AccelCorrelation.pearsonPValue(r: r, n: n) {
            return pval
        }
        #endif

        guard n > 2 else { return 1.0 }
        let absR = abs(r)
        guard absR < 1.0 else { return absR >= 1.0 ? 0.0 : 1.0 }

        let df = Double(n - 2)
        let t = absR * sqrt(df) / sqrt(1.0 - absR * absR)

        let x = df / (df + t * t)
        let ibeta = regularizedIncompleteBeta(x: x, a: df / 2.0, b: 0.5)
        return ibeta
    }

    /// Regularized incomplete beta function I_x(a, b) — delegates to C++ when available.
    private static func regularizedIncompleteBeta(x: Double, a: Double, b: Double) -> Double {
        #if BONHOMME_ACCEL
        if let result = AccelCorrelation.regularizedIncompleteBeta(x: x, a: a, b: b) {
            return result
        }
        #endif

        guard x > 0 else { return 0.0 }
        guard x < 1 else { return 1.0 }

        if x > (a + 1.0) / (a + b + 2.0) {
            return 1.0 - regularizedIncompleteBeta(x: 1.0 - x, a: b, b: a)
        }

        let lnPrefactor = a * log(x) + b * log(1.0 - x) - log(a) - lnBeta(a: a, b: b)
        let prefactor = exp(lnPrefactor)

        let maxIterations = 200
        let epsilon = 1.0e-10
        let tiny = 1.0e-30

        var c = 1.0
        var d = 1.0 / max(tiny, 1.0 - (a + b) * x / (a + 1.0))
        var h = d

        for m in 1...maxIterations {
            let dm = Double(m)

            var numerator = dm * (b - dm) * x / ((a + 2.0 * dm - 1.0) * (a + 2.0 * dm))
            d = 1.0 / max(tiny, 1.0 + numerator * d)
            c = max(tiny, 1.0 + numerator / c)
            h *= d * c

            numerator = -(a + dm) * (a + b + dm) * x / ((a + 2.0 * dm) * (a + 2.0 * dm + 1.0))
            d = 1.0 / max(tiny, 1.0 + numerator * d)
            c = max(tiny, 1.0 + numerator / c)
            let delta = d * c
            h *= delta

            if abs(delta - 1.0) < epsilon {
                break
            }
        }

        return prefactor * h
    }

    /// Log of the beta function: ln B(a, b) = ln Γ(a) + ln Γ(b) - ln Γ(a+b).
    private static func lnBeta(a: Double, b: Double) -> Double {
        return lgamma(a) + lgamma(b) - lgamma(a + b)
    }
}
