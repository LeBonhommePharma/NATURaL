import Foundation

/// Pharmacovigilance safety flag for an evolution step.
public enum SafetyFlag: String, Sendable {
    /// HP unchanged or improved.
    case safe
    /// HP decreased by 1 star.
    case caution
    /// HP decreased by 2+ stars, or HP decreased while Attack increased.
    case danger
}

/// How the enthalpy/entropy binding signature shifts across an evolution step.
public enum BindingShiftType: String, Sendable {
    case moreEnthalpyDriven
    case moreEntropyDriven
    case balanced
}

/// Enthalpy-entropy decomposition shift between two evolution partners (when both have ITC data).
public struct EnthalpyEntropyShift: Sendable {
    /// Change in enthalpy contribution: ΔΔH = ΔH(product) - ΔH(precursor).
    public let deltaDeltaHKcal: Double
    /// Change in entropy contribution: Δ(-TΔS) = (-TΔS)(product) - (-TΔS)(precursor).
    public let deltaMinusTDeltaSKcal: Double
    /// Classification of the shift direction.
    public let shiftType: BindingShiftType

    public init(deltaDeltaHKcal: Double, deltaMinusTDeltaSKcal: Double) {
        self.deltaDeltaHKcal = deltaDeltaHKcal
        self.deltaMinusTDeltaSKcal = deltaMinusTDeltaSKcal
        if abs(deltaDeltaHKcal) > abs(deltaMinusTDeltaSKcal) + 0.5 {
            self.shiftType = .moreEnthalpyDriven
        } else if abs(deltaMinusTDeltaSKcal) > abs(deltaDeltaHKcal) + 0.5 {
            self.shiftType = .moreEntropyDriven
        } else {
            self.shiftType = .balanced
        }
    }
}

/// Thermodynamic analysis of a single evolution step, connecting chemical
/// modification to binding affinity changes and pharmacovigilance flags.
public struct EvolutionThermodynamicStep: Sendable {
    /// The underlying chemical modification step.
    public let step: EvolutionStep

    /// Primary-target thermodynamic profile of the precursor (nil if not in catalog).
    public let fromProfile: ThermodynamicBindingProfile?

    /// Primary-target thermodynamic profile of the product (nil if not in catalog).
    public let toProfile: ThermodynamicBindingProfile?

    /// ΔΔG = ΔG(product) - ΔG(precursor). Negative = product binds tighter.
    public let deltaDeltaGKcal: Double?

    /// Ki(precursor) / Ki(product). >1 = potency increase.
    public let affinityFoldChange: Double?

    /// PokeDrug stats of the precursor (nil if not a PokeDrug species).
    public let fromStats: PokeDrugStats?

    /// PokeDrug stats of the product (nil if not a PokeDrug species).
    public let toStats: PokeDrugStats?

    /// HP(product) - HP(precursor). Negative = safety worsened.
    public let hpDelta: Int?

    /// Attack(product) - Attack(precursor). Positive = potency increased.
    public let attackDelta: Int?

    /// Enthalpy-entropy decomposition shift (only when both have ITC data).
    public let enthalpyEntropyShift: EnthalpyEntropyShift?

    /// Pharmacovigilance safety flag.
    public let safetyFlag: SafetyFlag

    /// Bilingual summary.
    public let summary: LocalizedString
}

// MARK: - Analyzer

/// Connects PokeDrug evolution chains to thermodynamic binding data for
/// pharmacovigilance research.
///
/// For each chemical modification step, computes:
/// - ΔΔG (change in binding free energy)
/// - Affinity fold change (potency ratio)
/// - HP/Attack stat deltas
/// - Enthalpy-entropy shift (when ITC data available)
/// - Safety flags (HP decrease + Attack increase = danger)
public struct EvolutionThermodynamics: Sendable {

    public init() {}

    /// Analyze all steps in an evolution chain.
    public static func analyzeChain(_ chain: EvolutionChain) -> [EvolutionThermodynamicStep] {
        chain.steps.map { analyzeStep($0) }
    }

    /// Analyze all known evolution chains.
    public static func analyzeAllChains() -> [(chain: EvolutionChain, steps: [EvolutionThermodynamicStep])] {
        EvolutionChain.knownChains.map { chain in
            (chain: chain, steps: analyzeChain(chain))
        }
    }

    /// Return all evolution steps flagged as dangerous for pharmacovigilance.
    public static func flagDangerousEvolutions() -> [EvolutionThermodynamicStep] {
        EvolutionChain.knownChains.flatMap { analyzeChain($0) }.filter { $0.safetyFlag == .danger }
    }

    /// Correlate Attack delta with HP delta across all evolution steps with data.
    /// Negative correlation = potency increases as safety decreases.
    public static func potencyVsSafetyCorrelation() -> (pearsonR: Double, n: Int)? {
        var attackDeltas: [Double] = []
        var hpDeltas: [Double] = []

        for chain in EvolutionChain.knownChains {
            for step in analyzeChain(chain) {
                if let ad = step.attackDelta, let hd = step.hpDelta {
                    attackDeltas.append(Double(ad))
                    hpDeltas.append(Double(hd))
                }
            }
        }

        guard attackDeltas.count >= 3 else { return nil }
        return (pearsonR: pearsonCorrelation(attackDeltas, hpDeltas), n: attackDeltas.count)
    }

    // MARK: - Private

    private static func analyzeStep(_ step: EvolutionStep) -> EvolutionThermodynamicStep {
        let fromProfile = ThermodynamicBindingProfile.profile(for: step.fromSubstanceId)
        let toProfile = ThermodynamicBindingProfile.profile(for: step.toSubstanceId)

        let fromSpecies = PokeDrugSpecies.species(for: step.fromSubstanceId)
        let toSpecies = PokeDrugSpecies.species(for: step.toSubstanceId)

        // Compute ΔΔG and fold change
        let ddG: Double?
        let foldChange: Double?
        if let fromG = fromProfile?.affinity.computedDeltaGKcal,
           let toG = toProfile?.affinity.computedDeltaGKcal {
            ddG = toG - fromG
        } else {
            ddG = nil
        }

        if let fromKi = fromProfile?.affinity.bestAffinityNM,
           let toKi = toProfile?.affinity.bestAffinityNM, toKi > 0 {
            foldChange = fromKi / toKi
        } else {
            foldChange = nil
        }

        // Stat deltas
        let hpDelta: Int?
        let attackDelta: Int?
        if let fs = fromSpecies?.stats, let ts = toSpecies?.stats {
            hpDelta = ts.hp - fs.hp
            attackDelta = ts.attack - fs.attack
        } else {
            hpDelta = nil
            attackDelta = nil
        }

        // Enthalpy-entropy shift
        let eeShift: EnthalpyEntropyShift?
        if let fromThermo = fromProfile?.thermodynamics,
           let toThermo = toProfile?.thermodynamics {
            eeShift = EnthalpyEntropyShift(
                deltaDeltaHKcal: toThermo.deltaHKcal - fromThermo.deltaHKcal,
                deltaMinusTDeltaSKcal: toThermo.minusTDeltaSKcal - fromThermo.minusTDeltaSKcal
            )
        } else {
            eeShift = nil
        }

        // Safety flag
        let flag: SafetyFlag
        if let hp = hpDelta, let atk = attackDelta {
            if hp <= -2 || (hp < 0 && atk > 0) {
                flag = .danger
            } else if hp < 0 {
                flag = .caution
            } else {
                flag = .safe
            }
        } else {
            flag = .safe // No data to flag
        }

        // Summary
        let from = step.fromSubstanceId
        let to = step.toSubstanceId
        let ddGText = ddG.map { String(format: "%+.1f", $0) } ?? "N/A"
        let foldText = foldChange.map { String(format: "%.1fx", $0) } ?? "N/A"

        return EvolutionThermodynamicStep(
            step: step,
            fromProfile: fromProfile,
            toProfile: toProfile,
            deltaDeltaGKcal: ddG,
            affinityFoldChange: foldChange,
            fromStats: fromSpecies?.stats,
            toStats: toSpecies?.stats,
            hpDelta: hpDelta,
            attackDelta: attackDelta,
            enthalpyEntropyShift: eeShift,
            safetyFlag: flag,
            summary: LocalizedString(
                en: "\(from) → \(to): ΔΔG = \(ddGText) kcal/mol, fold change = \(foldText). Safety: \(flag.rawValue).",
                fr: "\(from) → \(to) : ΔΔG = \(ddGText) kcal/mol, changement = \(foldText). Sécurité : \(flag.rawValue)."
            )
        )
    }

    private static func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        let n = Double(x.count)
        guard n >= 2, x.count == y.count else { return 0 }
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n
        var sumXY = 0.0, sumX2 = 0.0, sumY2 = 0.0
        for i in 0..<x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            sumXY += dx * dy
            sumX2 += dx * dx
            sumY2 += dy * dy
        }
        let denom = sqrt(sumX2 * sumY2)
        return denom > 0 ? sumXY / denom : 0
    }
}
