import Foundation

/// Result of information-theoretic selectivity analysis for a substance.
///
/// Uses Shannon entropy across a substance's target binding panel to quantify
/// receptor promiscuity. Lower entropy = more selective (one dominant target);
/// higher entropy = more promiscuous (even binding across targets).
///
/// This provides a data-driven alternative to the simple ratio-based Sp.Atk
/// stat in PokeDrugStats.
public struct SelectivityEntropyResult: Sendable {
    /// Substance identifier.
    public let substanceId: String

    /// Number of targets in the binding panel.
    public let targetCount: Int

    /// Shannon entropy of the pKi distribution across targets (bits).
    /// H = -Σ (p_j × log₂(p_j)) where p_j = pKi_j / Σ pKi.
    /// 0 = perfectly selective (single target), log₂(n) = maximally promiscuous.
    public let selectivityEntropy: Double

    /// Maximum possible entropy for this number of targets: log₂(targetCount).
    public let maxPossibleEntropy: Double

    /// Normalized selectivity: 1 - (H / Hmax).
    /// 1.0 = perfectly selective, 0.0 = maximally promiscuous.
    public let normalizedSelectivity: Double

    /// Target with the highest pKi weight (strongest binding).
    public let dominantTargetId: String

    /// Fraction of total pKi weight held by the dominant target.
    public let dominantTargetFraction: Double

    /// Sp.Atk star rating derived from normalizedSelectivity.
    public let derivedSpecialAttack: Int

    /// Existing hand-curated Sp.Atk from PokeDrugSpecies (nil if not a PokeDrug species).
    public let existingSpecialAttack: Int?

    /// Bilingual summary.
    public let summary: LocalizedString
}

// MARK: - Analyzer

/// Computes information-theoretic receptor selectivity from thermodynamic binding panels.
///
/// For each substance, converts Ki values to pKi (-log10 of molar Ki),
/// normalizes into a probability distribution, and computes Shannon entropy.
/// This unifies the selectivity concept with the entropy framework used
/// throughout NATURaL (FlexAID∆S, HRV, CrossDomainValidator).
public struct SelectivityEntropyAnalyzer: Sendable {

    public init() {}

    /// Analyze selectivity entropy for a single substance.
    ///
    /// - Parameter substanceId: Substance identifier.
    /// - Returns: SelectivityEntropyResult, or nil if no thermodynamic profiles found.
    public static func analyze(substanceId: String) -> SelectivityEntropyResult? {
        let profiles = ThermodynamicBindingProfile.profiles(for: substanceId)
        guard !profiles.isEmpty else { return nil }

        // Compute pKi for each target: pKi = -log10(Ki_M) = 9 - log10(Ki_nM)
        var targetPKi: [(targetId: String, pKi: Double)] = []
        for profile in profiles {
            guard let kiNM = profile.affinity.bestAffinityNM, kiNM > 0 else { continue }
            let pKi = 9.0 - log10(kiNM)
            targetPKi.append((targetId: profile.targetId, pKi: max(0, pKi)))
        }

        guard !targetPKi.isEmpty else { return nil }

        let totalPKi = targetPKi.reduce(0.0) { $0 + $1.pKi }
        guard totalPKi > 0 else { return nil }

        // Shannon entropy over normalized pKi distribution
        var entropy = 0.0
        for (_, pKi) in targetPKi {
            let p = pKi / totalPKi
            if p > 0 {
                entropy -= p * log2(p)
            }
        }

        let n = targetPKi.count
        let maxEntropy = n > 1 ? log2(Double(n)) : 1.0
        let normalized = n > 1 ? max(0, 1.0 - (entropy / maxEntropy)) : 1.0

        // Find dominant target
        let dominant = targetPKi.max(by: { $0.pKi < $1.pKi })!
        let dominantFraction = dominant.pKi / totalPKi

        // Derive star rating from normalized selectivity
        let stars: Int
        switch normalized {
        case 0.8...: stars = 5
        case 0.6..<0.8: stars = 4
        case 0.4..<0.6: stars = 3
        case 0.2..<0.4: stars = 2
        default: stars = 1
        }

        // Look up existing PokeDrug Sp.Atk for comparison
        let existingStat = PokeDrugSpecies.species(for: substanceId)?.stats.specialAttack

        let hText = String(format: "%.3f", entropy)
        let normText = String(format: "%.0f", normalized * 100)

        return SelectivityEntropyResult(
            substanceId: substanceId,
            targetCount: n,
            selectivityEntropy: entropy,
            maxPossibleEntropy: maxEntropy,
            normalizedSelectivity: normalized,
            dominantTargetId: dominant.targetId,
            dominantTargetFraction: dominantFraction,
            derivedSpecialAttack: stars,
            existingSpecialAttack: existingStat,
            summary: LocalizedString(
                en: "\(substanceId): H_selectivity = \(hText) bits across \(n) targets. Normalized selectivity: \(normText)%. Dominant: \(dominant.targetId).",
                fr: "\(substanceId) : H_sélectivité = \(hText) bits sur \(n) cibles. Sélectivité normalisée : \(normText) %. Dominante : \(dominant.targetId).",
                es: "\(substanceId): H_selectividad = \(hText) bits en \(n) dianas. Selectividad normalizada: \(normText)%. Dominante: \(dominant.targetId).",
                ja: "\(substanceId): H_選択性 = \(hText)ビット（\(n)標的）。正規化選択性: \(normText)%。主要標的: \(dominant.targetId)。",
                zh: "\(substanceId)：H_选择性 = \(hText)比特，跨\(n)个靶点。归一化选择性：\(normText)%。主要靶点：\(dominant.targetId)。",
                ko: "\(substanceId): H_선택성 = \(hText)비트, \(n)개 표적. 정규화 선택성: \(normText)%. 주요 표적: \(dominant.targetId).",
                ru: "\(substanceId): H_селективность = \(hText) бит по \(n) мишеням. Нормализованная селективность: \(normText)%. Доминантная: \(dominant.targetId).",
                de: "\(substanceId): H_Selektivität = \(hText) Bit über \(n) Ziele. Normalisierte Selektivität: \(normText)%. Dominant: \(dominant.targetId).",
                ar: "\(substanceId): H_الانتقائية = \(hText) بت عبر \(n) أهداف. الانتقائية المعيارية: \(normText)%. السائد: \(dominant.targetId)."
            )
        )
    }

    /// Analyze selectivity entropy for all substances with thermodynamic profiles.
    public static func analyzeAll() -> [SelectivityEntropyResult] {
        ThermodynamicBindingProfile.knownSubstanceIds.compactMap { analyze(substanceId: $0) }
    }

    /// Compare information-theoretic Sp.Atk with hand-curated PokeDrug Sp.Atk.
    public static func compareWithPokeDrugStats() -> [(substanceId: String, informationTheoretic: Int, existing: Int, delta: Int)] {
        var results: [(substanceId: String, informationTheoretic: Int, existing: Int, delta: Int)] = []
        for species in PokeDrugSpecies.knownSpecies {
            guard let result = analyze(substanceId: species.substanceId) else { continue }
            results.append((
                substanceId: species.substanceId,
                informationTheoretic: result.derivedSpecialAttack,
                existing: species.stats.specialAttack,
                delta: result.derivedSpecialAttack - species.stats.specialAttack
            ))
        }
        return results
    }
}
