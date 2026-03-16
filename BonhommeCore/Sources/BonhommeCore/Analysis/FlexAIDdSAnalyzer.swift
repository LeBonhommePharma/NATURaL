import Foundation

// MARK: - FlexAID∆S Configurational Entropy Analysis
// Computes ΔS_config = S_bound − S_free from torsional angle distributions

// MARK: - Thermodynamic Constants

/// Shared thermodynamic constants for entropy ↔ energy conversions.
///
/// Used by FlexAIDdSAnalyzer and PharmacokineticProfile to ensure identical
/// conversion between Shannon entropy (bits) and free energy (kcal/mol).
public enum ThermodynamicConstants {
    /// Gas constant in kcal/(mol·K).
    public static let R: Double = 1.987e-3

    /// Standard temperature (25°C) in Kelvin.
    public static let standardTemperatureK: Double = 298.0

    /// Convert Shannon entropy change (bits) to thermodynamic penalty (kcal/mol).
    ///
    /// Formula: -TΔS = -T × ΔS_bits × R × ln(2)
    public static func entropyPenaltyKcal(
        deltaSBits: Double,
        temperatureK: Double = standardTemperatureK
    ) -> Double {
        -temperatureK * deltaSBits * R * log(2.0)
    }

    /// Convert thermodynamic penalty (kcal/mol) back to Shannon entropy (bits).
    ///
    /// Inverse of `entropyPenaltyKcal`.
    public static func kcalToDeltaSBits(
        penaltyKcal: Double,
        temperatureK: Double = standardTemperatureK
    ) -> Double {
        -penaltyKcal / (temperatureK * R * log(2.0))
    }
}

// MARK: - Domain Types

/// Distribution of torsional angle samples for a single rotatable bond.
///
/// In free solution, angles sample broadly across the Ramachandran-like landscape
/// (high entropy — many accessible conformations).
/// In a binding pocket, angles are constrained by steric/electrostatic complementarity
/// (low entropy — few accessible conformations).
///
/// The entropy difference ΔS = S_bound - S_free quantifies the conformational
/// freedom lost upon binding — the configurational entropy penalty.
public struct TorsionalAngleDistribution: Sendable {
    /// Identifier for this rotatable bond (e.g., "C3-C4", "bond_1").
    public let bondId: String

    /// Sampled torsional angles in degrees [-180, 180].
    /// For free-state: typically hundreds to thousands of samples from MD or MC sampling.
    /// For bound-state: samples from docking pose ensemble or restrained MD.
    public let angles: [Double]

    /// Atom names defining the rotatable bond (for display/debugging).
    public let atomNames: [String]

    public init(bondId: String, angles: [Double], atomNames: [String] = []) {
        self.bondId = bondId
        self.angles = angles
        self.atomNames = atomNames
    }
}

/// Collection of torsional angle distributions for all rotatable bonds of a ligand.
/// Represents either the free-state (solution sampling) or bound-state (docking result).
public struct LigandConformation: Sendable {
    /// Substance identifier matching PharmacokineticProfile.substanceId.
    public let substanceId: String

    /// Display name.
    public let name: LocalizedString

    /// Torsional angle distributions for each rotatable bond.
    public let bonds: [TorsionalAngleDistribution]

    /// Total number of rotatable bonds.
    public var rotatableBondCount: Int { bonds.count }

    public init(
        substanceId: String,
        name: LocalizedString,
        bonds: [TorsionalAngleDistribution]
    ) {
        self.substanceId = substanceId
        self.name = name
        self.bonds = bonds
    }
}

/// A single docking result: bound-state conformation from FlexAID.
public struct DockingPose: Sendable {
    /// The bound conformation of the ligand (torsional angles in the binding pocket).
    public let boundConformation: LigandConformation

    /// Receptor/target identifier (e.g., PDB ID, receptor name).
    public let receptorId: String

    /// Docking score from FlexAID (arbitrary units, lower = better binding).
    public let dockingScore: Double

    /// Binding free energy estimate in kcal/mol, if available from scoring function.
    public let bindingFreeEnergy: Double?

    public init(
        boundConformation: LigandConformation,
        receptorId: String,
        dockingScore: Double,
        bindingFreeEnergy: Double? = nil
    ) {
        self.boundConformation = boundConformation
        self.receptorId = receptorId
        self.dockingScore = dockingScore
        self.bindingFreeEnergy = bindingFreeEnergy
    }
}

// MARK: - Result Types

/// Entropy result for a single rotatable bond.
public struct BondEntropyResult: Sendable {
    /// Bond identifier.
    public let bondId: String

    /// Shannon entropy of free-state torsional angles (bits).
    public let freeEntropy: Double

    /// Shannon entropy of bound-state torsional angles (bits).
    public let boundEntropy: Double

    /// ΔS = boundEntropy - freeEntropy (bits).
    /// Negative = constrained by binding (entropy penalty).
    public var deltaSBits: Double { boundEntropy - freeEntropy }

    /// Fractional entropy loss: |ΔS| / freeEntropy.
    /// 1.0 = all conformational freedom lost; 0.0 = no change.
    public var fractionalLoss: Double {
        guard freeEntropy > 0 else { return 0 }
        return min(1.0, abs(min(0, deltaSBits)) / freeEntropy)
    }

    public init(bondId: String, freeEntropy: Double, boundEntropy: Double) {
        self.bondId = bondId
        self.freeEntropy = freeEntropy
        self.boundEntropy = boundEntropy
    }
}

/// Complete result of a FlexAID∆S configurational entropy analysis.
///
/// Contains per-bond and total entropy metrics, enabling both granular
/// (which bonds are most constrained) and aggregate (total binding penalty)
/// interpretation.
public struct FlexAIDdSResult: Sendable {
    /// Substance identifier.
    public let substanceId: String

    /// Receptor/target identifier.
    public let receptorId: String

    /// Per-bond entropy results.
    public let bondResults: [BondEntropyResult]

    /// Docking score from the input pose.
    public let dockingScore: Double

    /// Total free-state entropy (sum over all bonds, bits).
    public var totalFreeEntropy: Double {
        bondResults.reduce(0) { $0 + $1.freeEntropy }
    }

    /// Total bound-state entropy (sum over all bonds, bits).
    public var totalBoundEntropy: Double {
        bondResults.reduce(0) { $0 + $1.boundEntropy }
    }

    /// Total ΔS_config (bits). Negative = binding imposes entropy penalty.
    public var totalDeltaSConfig: Double {
        totalBoundEntropy - totalFreeEntropy
    }

    /// Number of bonds analyzed.
    public var bondCount: Int { bondResults.count }

    /// Mean fractional entropy loss across bonds.
    public var meanFractionalLoss: Double {
        guard !bondResults.isEmpty else { return 0 }
        return bondResults.reduce(0) { $0 + $1.fractionalLoss } / Double(bondResults.count)
    }

    /// Whether a significant binding entropy penalty was detected.
    public var bindingDetected: Bool {
        totalDeltaSConfig < -FlexAIDdSAnalyzer.significanceThreshold
    }

    /// Most constrained bond (largest |ΔS|).
    public var mostConstrainedBond: BondEntropyResult? {
        bondResults.min(by: { $0.deltaSBits < $1.deltaSBits })
    }

    /// Least constrained bond (smallest |ΔS|).
    public var leastConstrainedBond: BondEntropyResult? {
        bondResults.max(by: { $0.deltaSBits < $1.deltaSBits })
    }

    /// Bilingual summary.
    public var summary: LocalizedString {
        let deltaText = String(format: "%.2f", totalDeltaSConfig)
        let freeText = String(format: "%.2f", totalFreeEntropy)
        let boundText = String(format: "%.2f", totalBoundEntropy)
        let lossText = String(format: "%.0f", meanFractionalLoss * 100)

        if bindingDetected {
            return LocalizedString(
                en: "Binding entropy penalty detected: ΔS_config = \(deltaText) bits (\(bondCount) bonds, \(lossText)% mean loss). S_free = \(freeText), S_bound = \(boundText).",
                fr: "Pénalité entropique de liaison détectée : ΔS_config = \(deltaText) bits (\(bondCount) liaisons, \(lossText) % perte moyenne). S_libre = \(freeText), S_lié = \(boundText)."
            )
        } else {
            return LocalizedString(
                en: "No significant binding entropy penalty: ΔS_config = \(deltaText) bits (\(bondCount) bonds).",
                fr: "Aucune pénalité entropique significative : ΔS_config = \(deltaText) bits (\(bondCount) liaisons)."
            )
        }
    }

    public init(
        substanceId: String,
        receptorId: String,
        bondResults: [BondEntropyResult],
        dockingScore: Double
    ) {
        self.substanceId = substanceId
        self.receptorId = receptorId
        self.bondResults = bondResults
        self.dockingScore = dockingScore
    }
}

// MARK: - FlexAIDdSAnalyzer

/// Computes configurational entropy penalty (ΔS_config) for molecular docking.
///
/// Uses the same `EntropyCalculator` as `HRVAnalyzer` and `DrugResponseAnalyzer`,
/// establishing mathematical parity between in-silico and in-vivo entropy domains.
///
/// The isomorphism:
/// ```
/// Domain          | Input distribution      | Entropy unit | Binding signal
/// ─────────────────────────────────────────────────────────────────────────
/// FlexAID∆S       | Torsional angles (°)    | bits         | ΔS_config < 0
/// NATURaL HRV     | RR intervals (ms)       | bits         | ΔH_hrv < 0
/// ```
///
/// Both use Shannon entropy H = -Σ p_i log₂(p_i) over histogram-binned distributions.
/// A significant negative delta indicates a binding event (molecular or autonomic).
public struct FlexAIDdSAnalyzer: Sendable {

    /// Minimum |ΔS_config| (bits) to consider a binding entropy penalty significant.
    /// Set to 0.5 bits (vs. DrugResponseAnalyzer's 0.4 bits for HRV) because molecular
    /// torsional distributions have a lower noise floor than physiological RR-interval
    /// measurements (~0.3 bits intra-session variation).
    public static let significanceThreshold: Double = 0.5

    /// Shared entropy calculator (same bin count as HRVAnalyzer/DrugResponseAnalyzer default).
    private let entropyCalc: EntropyCalculator

    public init(binCount: Int = 32) {
        self.entropyCalc = EntropyCalculator(binCount: binCount)
    }

    // MARK: - Single Bond Analysis

    /// Compute Shannon entropy for a single torsional angle distribution.
    ///
    /// Uses fixed-domain binning over [-180, 180] degrees to ensure reproducible
    /// histograms regardless of sample extremes. This guarantees identical entropy
    /// for identical distributions across platforms and dataset variations.
    ///
    /// - Parameter distribution: Torsional angle samples for one rotatable bond.
    /// - Returns: Entropy in bits. Higher = more conformational freedom.
    public func entropy(of distribution: TorsionalAngleDistribution) -> Double {
        entropyCalc.shannonEntropy(distribution.angles, domainMin: -180.0, domainMax: 180.0)
    }

    // MARK: - Full Ligand Analysis

    /// Compute ΔS_config for a ligand given its free-state and bound-state conformations.
    ///
    /// For each rotatable bond, computes H_free and H_bound using the shared
    /// EntropyCalculator, then aggregates across all bonds.
    ///
    /// - Parameters:
    ///   - freeConformation: Torsional angle distributions from solution/MD sampling.
    ///   - dockingPose: Bound-state conformation from FlexAID docking.
    /// - Returns: FlexAIDdSResult with per-bond and total entropy, or nil if bond counts mismatch.
    public func analyze(
        freeConformation: LigandConformation,
        dockingPose: DockingPose
    ) -> FlexAIDdSResult? {
        let boundConf = dockingPose.boundConformation

        guard freeConformation.bonds.count == boundConf.bonds.count else { return nil }
        guard !freeConformation.bonds.isEmpty else { return nil }

        var bondResults: [BondEntropyResult] = []

        for (freeBond, boundBond) in zip(freeConformation.bonds, boundConf.bonds) {
            let hFree = entropyCalc.shannonEntropy(freeBond.angles, domainMin: -180.0, domainMax: 180.0)
            let hBound = entropyCalc.shannonEntropy(boundBond.angles, domainMin: -180.0, domainMax: 180.0)
            bondResults.append(BondEntropyResult(
                bondId: freeBond.bondId,
                freeEntropy: hFree,
                boundEntropy: hBound
            ))
        }

        return FlexAIDdSResult(
            substanceId: freeConformation.substanceId,
            receptorId: dockingPose.receptorId,
            bondResults: bondResults,
            dockingScore: dockingPose.dockingScore
        )
    }

    // MARK: - Batch Analysis

    /// Analyze multiple docking poses for the same ligand (e.g., top N poses from FlexAID).
    /// Returns results sorted by |ΔS_config| descending (most constrained first).
    public func analyzeBatch(
        freeConformation: LigandConformation,
        dockingPoses: [DockingPose]
    ) -> [FlexAIDdSResult] {
        dockingPoses.compactMap { pose in
            analyze(freeConformation: freeConformation, dockingPose: pose)
        }.sorted { abs($0.totalDeltaSConfig) > abs($1.totalDeltaSConfig) }
    }

    // MARK: - Entropy-to-Energy Conversion

    /// Convert Shannon entropy change (bits) to thermodynamic free energy contribution (kcal/mol).
    ///
    /// Delegates to `ThermodynamicConstants.entropyPenaltyKcal` for a single source of truth.
    ///
    /// - Parameters:
    ///   - deltaSBits: Configurational entropy change in bits (negative for binding).
    ///   - temperatureK: Temperature in Kelvin (default 298K / 25°C).
    /// - Returns: -TΔS contribution to binding free energy in kcal/mol.
    ///   Positive = entropy penalty (unfavorable for binding).
    ///   Negative = entropy benefit (favorable, rare for configurational entropy).
    public func entropyPenaltyKcal(
        deltaSBits: Double,
        temperatureK: Double = ThermodynamicConstants.standardTemperatureK
    ) -> Double {
        ThermodynamicConstants.entropyPenaltyKcal(deltaSBits: deltaSBits, temperatureK: temperatureK)
    }

    /// Convert thermodynamic entropy penalty (kcal/mol) back to Shannon entropy (bits).
    ///
    /// Inverse of `entropyPenaltyKcal`. Delegates to `ThermodynamicConstants`.
    ///
    /// - Parameters:
    ///   - penaltyKcal: -TΔS in kcal/mol (positive = penalty).
    ///   - temperatureK: Temperature in Kelvin (default 298K).
    /// - Returns: ΔS_config in bits (negative for binding).
    public func kcalToDeltaSBits(
        penaltyKcal: Double,
        temperatureK: Double = ThermodynamicConstants.standardTemperatureK
    ) -> Double {
        ThermodynamicConstants.kcalToDeltaSBits(penaltyKcal: penaltyKcal, temperatureK: temperatureK)
    }
}
