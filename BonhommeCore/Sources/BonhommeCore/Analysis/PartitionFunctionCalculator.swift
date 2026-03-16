import Foundation

// MARK: - Partition Function from Independent Docking Simulations

/// Computes a global partition function Z from multiple independent FlexAID∆S
/// docking simulations, enabling Boltzmann-weighted ensemble thermodynamics
/// and pose importance attribution for discovery and patent claims.
///
/// ## Statistical Mechanics Foundation
///
/// Each independent docking simulation produces a pose with free energy ΔGᵢ.
/// The global partition function aggregates all poses into a canonical ensemble:
///
/// ```
///   Z = Σᵢ gᵢ · exp(-βΔGᵢ)       where β = 1/(kT)
/// ```
///
/// From Z, we derive:
///   - **Population fraction** (Boltzmann weight): pᵢ = gᵢ · exp(-βΔGᵢ) / Z
///   - **Ensemble free energy**: ΔG_ens = -kT · ln(Z)
///   - **Ensemble entropy**: S_ens = -k · Σᵢ pᵢ · ln(pᵢ)
///   - **Internal energy**: ⟨E⟩ = Σᵢ pᵢ · ΔGᵢ
///
/// ## Massive Parallelism
///
/// Each docking simulation is fully independent — no communication between runs.
/// The partition function is a simple sum of exponentials: embarrassingly parallel.
///
/// ```
/// ┌─────────┐  ┌─────────┐  ┌─────────┐       ┌─────────┐
/// │FlexAID 1│  │FlexAID 2│  │FlexAID 3│  ...  │FlexAID N│   N independent runs
/// │ΔG₁, ΔS₁│  │ΔG₂, ΔS₂│  │ΔG₃, ΔS₃│       │ΔGₙ, ΔSₙ│   (embarrassingly parallel)
/// └────┬────┘  └────┬────┘  └────┬────┘       └────┬────┘
///      │            │            │                  │
///      └────────────┴────────────┴──────────────────┘
///                              │
///                     ┌────────▼────────┐
///                     │  Reduce:        │   O(N) summation
///                     │  Z = Σ exp(-βΔG)│   (map-reduce)
///                     └────────┬────────┘
///                              │
///                     ┌────────▼────────┐
///                     │  Boltzmann wts  │
///                     │  pᵢ = wᵢ / Z   │
///                     └────────┬────────┘
///                              │
///                     ┌────────▼────────┐
///                     │  Importance     │
///                     │  Attribution    │
///                     └─────────────────┘
/// ```
///
/// Parallelism modes (by deployment context):
///   - **On-device** (Apple Silicon): Swift `TaskGroup` over N poses
///   - **Cluster/HPC**: Each FlexAID run on separate node; reduce step trivial
///   - **Cloud**: Map-reduce (e.g., one Lambda/Cloud Function per ligand conformation)
///
/// ## Pose Importance for Discovery / Patent Attribution
///
/// Each pose's Boltzmann weight pᵢ quantifies its thermodynamic importance:
///   - **Dominant pose** (pᵢ → 1): single binding mode drives affinity
///   - **Entropic binder** (many poses with pᵢ ~ 1/N): affinity from conformational diversity
///   - **Shannon importance**: Iᵢ = -log₂(pᵢ) bits (information content of observing pose i)
///   - **Cumulative importance**: poses sorted by pᵢ descending; threshold at Σpᵢ ≥ 0.95
///     defines the "essential pose set" for patent claims
///
/// Each `PoseAttribution` carries a provenance record (timestamps, simulation IDs,
/// receptor targets) suitable for inclusion in patent filings as evidence of
/// computational discovery.
public struct PartitionFunctionCalculator: Sendable {

    /// Boltzmann constant in kcal/(mol·K).
    private static let kB: Double = 1.987e-3  // R gas constant, kcal/(mol·K)

    /// Temperature in Kelvin.
    public let temperatureK: Double

    /// β = 1/(kT) in mol/kcal.
    public var beta: Double { 1.0 / (Self.kB * temperatureK) }

    /// Shared entropy-to-energy converter.
    private let dockingAnalyzer: FlexAIDdSAnalyzer

    public init(temperatureK: Double = 298.0) {
        self.temperatureK = temperatureK
        self.dockingAnalyzer = FlexAIDdSAnalyzer()
    }

    // MARK: - Partition Function Computation

    /// Compute the global partition function and Boltzmann weights from independent
    /// FlexAID∆S docking results.
    ///
    /// Each result contributes one microstate. The free energy ΔGᵢ is derived from
    /// the configurational entropy penalty: ΔGᵢ = -TΔSᵢ (the entropy-dominated term).
    ///
    /// - Parameters:
    ///   - results: FlexAID∆S analysis results from independent simulations.
    ///   - degeneracies: Optional degeneracy factors gᵢ for each pose (default 1.0 each).
    ///     Use > 1.0 when a single representative pose stands for a cluster of similar conformations.
    /// - Returns: `EnsembleResult` with partition function, Boltzmann weights, and thermodynamic summary.
    public func computeEnsemble(
        results: [FlexAIDdSResult],
        degeneracies: [Double]? = nil
    ) -> EnsembleResult? {
        guard !results.isEmpty else { return nil }

        let g = degeneracies ?? [Double](repeating: 1.0, count: results.count)
        guard g.count == results.count else { return nil }

        // Step 1: Compute ΔGᵢ for each pose (kcal/mol)
        let freeEnergies = results.map { result in
            dockingAnalyzer.entropyPenaltyKcal(
                deltaSBits: result.totalDeltaSConfig,
                temperatureK: temperatureK
            )
        }

        // Step 2: Shift energies so the minimum is zero (numerical stability for exp)
        let minG = freeEnergies.min()!
        let shifted = freeEnergies.map { $0 - minG }

        // Step 3: Boltzmann factors  wᵢ = gᵢ · exp(-β · (ΔGᵢ - ΔG_min))
        let boltzmannFactors = zip(g, shifted).map { gi, dGi in
            gi * exp(-beta * dGi)
        }

        // Step 4: Partition function  Z = Σ wᵢ  (Kahan compensated summation)
        let Z = kahanSum(boltzmannFactors)
        guard Z > 0 else { return nil }

        // Step 5: Population fractions  pᵢ = wᵢ / Z
        let populations = boltzmannFactors.map { $0 / Z }

        // Step 6: Ensemble free energy  ΔG_ens = -kT · ln(Z_shifted) + ΔG_min
        // (undo the shift: ln(Z_true) = ln(Z_shifted) + (-β·minG) isn't needed;
        // ΔG_ens = -kT·ln(Z_true) = -kT·ln(Z_shifted) - kT·(-β·minG) = -kT·ln(Z_shifted) + minG)
        let ensembleFreeEnergy = -(Self.kB * temperatureK) * log(Z) + minG

        // Step 7: Ensemble entropy  S_ens = -k · Σ pᵢ · ln(pᵢ)  (Kahan)
        let pLogP = populations.map { p in p > 0 ? p * log(p) : 0.0 }
        let ensembleEntropyKcalPerK = -Self.kB * kahanSum(pLogP)

        // Step 8: Shannon entropy of the population distribution (bits, Kahan)
        let pLog2P = populations.map { p in p > 0 ? p * log2(p) : 0.0 }
        let shannonEntropyBits = -kahanSum(pLog2P)

        // Step 9: Mean internal energy  ⟨E⟩ = Σ pᵢ · ΔGᵢ  (Kahan)
        let pE = zip(populations, freeEnergies).map { $0 * $1 }
        let meanEnergy = kahanSum(pE)

        // Step 10: Build pose-level attributions
        let attributions = buildAttributions(
            results: results,
            freeEnergies: freeEnergies,
            populations: populations,
            degeneracies: g
        )

        // Step 11: Log-space partition function (overflow-safe representation).
        // ln(Z_true) = ln(Z_shifted) - β·minG  →  stored as natural log.
        let logPartitionFunction = log(Z) - beta * minG

        return EnsembleResult(
            logPartitionFunction: logPartitionFunction,
            effectivePartitionFunction: Z,
            ensembleFreeEnergy: ensembleFreeEnergy,
            ensembleEntropyKcalPerK: ensembleEntropyKcalPerK,
            shannonEntropyBits: shannonEntropyBits,
            meanEnergy: meanEnergy,
            temperatureK: temperatureK,
            poseCount: results.count,
            attributions: attributions
        )
    }

    /// Compute the ensemble from raw docking poses and their free-state reference.
    ///
    /// Convenience method that runs `FlexAIDdSAnalyzer.analyze` on each pose first,
    /// then feeds results into `computeEnsemble`.
    ///
    /// This is the entry point for massive parallel workflows: each `DockingPose`
    /// comes from an independent FlexAID simulation that can run on a separate core,
    /// node, or cloud function.
    ///
    /// - Note: Degeneracies are only passed through when all poses produce valid
    ///   analysis results. If any pose fails analysis, degeneracies are dropped
    ///   (count mismatch) and uniform degeneracy g=1 is used for the surviving poses.
    public func computeEnsembleFromPoses(
        freeConformation: LigandConformation,
        dockingPoses: [DockingPose],
        degeneracies: [Double]? = nil
    ) -> EnsembleResult? {
        let results = dockingPoses.compactMap { pose in
            dockingAnalyzer.analyze(freeConformation: freeConformation, dockingPose: pose)
        }
        // Only forward degeneracies if no poses were filtered out (count still matches).
        let effectiveDegeneracies = (degeneracies?.count == results.count) ? degeneracies : nil
        return computeEnsemble(results: results, degeneracies: effectiveDegeneracies)
    }

    // MARK: - Parallel Batch (Swift Concurrency)

    /// Analyze poses in parallel using Swift structured concurrency, then compute
    /// the global partition function from the collected results.
    ///
    /// Each pose analysis runs as an independent `Task` in a `TaskGroup`,
    /// fully exploiting multi-core Apple Silicon (or any platform with Swift concurrency).
    ///
    /// Results are collected with their original indices and re-sorted to preserve
    /// input ordering, ensuring reproducible `poseIndex` values and correct
    /// degeneracy alignment across runs.
    ///
    /// ```swift
    /// let calc = PartitionFunctionCalculator()
    /// let ensemble = await calc.computeEnsembleParallel(
    ///     freeConformation: freeState,
    ///     dockingPoses: thousandsOfPoses  // from N independent FlexAID runs
    /// )
    /// // ensemble.attributions — sorted by Boltzmann weight for patent claims
    /// ```
    public func computeEnsembleParallel(
        freeConformation: LigandConformation,
        dockingPoses: [DockingPose],
        degeneracies: [Double]? = nil
    ) async -> EnsembleResult? {
        let analyzer = dockingAnalyzer

        // Collect (index, result) pairs to restore deterministic input order.
        let indexed: [(Int, FlexAIDdSResult)] = await withTaskGroup(
            of: (Int, FlexAIDdSResult?).self,
            returning: [(Int, FlexAIDdSResult)].self
        ) { group in
            for (i, pose) in dockingPoses.enumerated() {
                group.addTask {
                    let result = analyzer.analyze(
                        freeConformation: freeConformation,
                        dockingPose: pose
                    )
                    return (i, result)
                }
            }

            var collected: [(Int, FlexAIDdSResult)] = []
            for await (index, result) in group {
                if let r = result {
                    collected.append((index, r))
                }
            }
            return collected
        }

        // Sort by original index for reproducible ordering.
        let sorted = indexed.sorted { $0.0 < $1.0 }
        let results = sorted.map(\.1)

        // Align degeneracies to surviving indices.
        let effectiveDegeneracies: [Double]?
        if let g = degeneracies {
            let survivingG = sorted.map { g[$0.0] }
            effectiveDegeneracies = survivingG
        } else {
            effectiveDegeneracies = nil
        }

        return computeEnsemble(results: results, degeneracies: effectiveDegeneracies)
    }

    // MARK: - Pose Importance Attribution

    private func buildAttributions(
        results: [FlexAIDdSResult],
        freeEnergies: [Double],
        populations: [Double],
        degeneracies: [Double]
    ) -> [PoseAttribution] {
        var attributions: [PoseAttribution] = []

        for (i, result) in results.enumerated() {
            let shannonImportance = populations[i] > 0 ? -log2(populations[i]) : .infinity
            attributions.append(PoseAttribution(
                poseIndex: i,
                substanceId: result.substanceId,
                receptorId: result.receptorId,
                dockingScore: result.dockingScore,
                deltaSConfigBits: result.totalDeltaSConfig,
                freeEnergyKcal: freeEnergies[i],
                boltzmannWeight: populations[i],
                degeneracy: degeneracies[i],
                shannonImportanceBits: shannonImportance,
                bondCount: result.bondCount,
                meanFractionalLoss: result.meanFractionalLoss,
                bindingDetected: result.bindingDetected
            ))
        }

        // Sort by Boltzmann weight descending (most important first)
        attributions.sort { $0.boltzmannWeight > $1.boltzmannWeight }

        // Assign cumulative weight and rank
        var cumulative = 0.0
        for i in 0..<attributions.count {
            cumulative += attributions[i].boltzmannWeight
            attributions[i].rank = i + 1
            attributions[i].cumulativeWeight = cumulative
        }

        return attributions
    }

    // MARK: - Essential Pose Set

    /// Extract the minimal set of poses whose cumulative Boltzmann weight
    /// exceeds the given threshold (default 95%).
    ///
    /// This defines the "essential pose set" — the smallest number of binding modes
    /// that account for ≥ threshold of the thermodynamic population.
    /// Useful for patent claims: these are the poses that matter.
    ///
    /// Uses the pre-computed `cumulativeWeight` on each attribution (which is
    /// accumulated in Boltzmann-weight-descending order). A pose is included if
    /// its predecessor's cumulative weight has not yet reached the threshold.
    public func essentialPoseSet(
        from ensemble: EnsembleResult,
        threshold: Double = 0.95
    ) -> [PoseAttribution] {
        // Attributions are already sorted by Boltzmann weight descending
        // with cumulativeWeight pre-computed. Include all poses up to and
        // including the one whose cumulative weight crosses the threshold.
        var essential: [PoseAttribution] = []
        for attribution in ensemble.attributions {
            essential.append(attribution)
            if attribution.cumulativeWeight >= threshold { break }
        }
        return essential
    }

    // MARK: - Kahan Compensated Summation

    /// Kahan summation for reduced floating-point accumulation error.
    ///
    /// Critical for reproducibility across platforms when N is large:
    /// naive `reduce(0, +)` accumulates O(N·ε) rounding error;
    /// Kahan summation keeps it at O(ε) regardless of N.
    private func kahanSum(_ values: [Double]) -> Double {
        var sum = 0.0
        var c = 0.0   // compensation for lost low-order bits
        for v in values {
            let y = v - c
            let t = sum + y
            c = (t - sum) - y
            sum = t
        }
        return sum
    }
}

// MARK: - Result Types

/// Complete result of a global partition function calculation over an ensemble
/// of independent docking simulations.
public struct EnsembleResult: Sendable {
    /// Natural logarithm of the global partition function: ln(Z).
    ///
    /// Stored in log-space to avoid overflow for large ensembles or extreme energies.
    /// The true Z can be recovered as `exp(logPartitionFunction)` when the value
    /// is within representable range, but for most downstream uses (free energy,
    /// population fractions) log-space is sufficient and numerically safer.
    ///
    /// Relationship: ΔG_ens = -kT · logPartitionFunction.
    public let logPartitionFunction: Double

    /// Numerically-stabilized Z (shifted so ΔG_min = 0). Used internally.
    /// This is always representable because it equals Σ gᵢ·exp(-β·(ΔGᵢ - ΔG_min))
    /// where all exponents are ≤ 0.
    public let effectivePartitionFunction: Double

    /// Ensemble binding free energy: ΔG_ens = -kT · ln(Z) in kcal/mol.
    /// Always ≤ min(ΔGᵢ) because the ensemble captures all accessible states.
    public let ensembleFreeEnergy: Double

    /// Ensemble entropy in kcal/(mol·K): S = -k · Σ pᵢ · ln(pᵢ).
    /// Higher = more evenly distributed population (entropic binding).
    public let ensembleEntropyKcalPerK: Double

    /// Shannon entropy of the Boltzmann population in bits: H = -Σ pᵢ · log₂(pᵢ).
    /// Connects to the information-theoretic framework used elsewhere in NATURaL.
    /// H = 0 → single dominant pose; H = log₂(N) → all poses equally populated.
    public let shannonEntropyBits: Double

    /// Mean internal energy ⟨E⟩ = Σ pᵢ · ΔGᵢ in kcal/mol.
    public let meanEnergy: Double

    /// Temperature used in the calculation (Kelvin).
    public let temperatureK: Double

    /// Total number of poses (microstates) in the ensemble.
    public let poseCount: Int

    /// Per-pose attributions sorted by Boltzmann weight descending.
    /// The first entry is the most thermodynamically important pose.
    public var attributions: [PoseAttribution]

    /// Effective number of poses: N_eff = exp(H · ln(2)) = 2^H.
    /// Ranges from 1 (single dominant) to N (uniform distribution).
    public var effectivePoseCount: Double {
        pow(2.0, shannonEntropyBits)
    }

    /// Whether the ensemble is dominated by a single pose (N_eff < 2).
    public var isSinglePoseDominant: Bool {
        effectivePoseCount < 2.0
    }

    /// Whether binding is "entropically driven" — many poses contribute significantly.
    /// Defined as N_eff ≥ 0.3 × N (at least 30% of poses are meaningfully populated).
    public var isEntropicBinder: Bool {
        effectivePoseCount >= 0.3 * Double(poseCount) && poseCount >= 3
    }

    /// Bilingual summary.
    public var summary: LocalizedString {
        let zText = String(format: "%.2f", logPartitionFunction)
        let gText = String(format: "%.2f", ensembleFreeEnergy)
        let hText = String(format: "%.2f", shannonEntropyBits)
        let nEffText = String(format: "%.1f", effectivePoseCount)
        let topPct = attributions.first.map {
            String(format: "%.1f", $0.boltzmannWeight * 100)
        } ?? "0.0"

        let bindingMode: String
        let bindingModeFr: String
        if isSinglePoseDominant {
            bindingMode = "single dominant pose"
            bindingModeFr = "pose dominante unique"
        } else if isEntropicBinder {
            bindingMode = "entropically driven (multiple poses)"
            bindingModeFr = "entropiquement dirigé (poses multiples)"
        } else {
            bindingMode = "mixed binding mode"
            bindingModeFr = "mode de liaison mixte"
        }

        return LocalizedString(
            en: "Partition function ln(Z) = \(zText) over \(poseCount) poses. ΔG_ens = \(gText) kcal/mol. " +
                "Shannon H = \(hText) bits (N_eff = \(nEffText)). " +
                "Top pose: \(topPct)% population. Binding mode: \(bindingMode).",
            fr: "Fonction de partition ln(Z) = \(zText) sur \(poseCount) poses. ΔG_ens = \(gText) kcal/mol. " +
                "Shannon H = \(hText) bits (N_eff = \(nEffText)). " +
                "Pose principale : \(topPct) % de la population. Mode de liaison : \(bindingModeFr)."
        )
    }
}

/// Attribution of thermodynamic importance to a single docking pose.
///
/// Provides the evidence chain for discovery and patent claims:
///   - **What**: substance, receptor, binding mode (ΔS, ΔG)
///   - **How important**: Boltzmann weight pᵢ, rank, cumulative contribution
///   - **Why it matters**: Shannon importance (information content of this pose)
///
/// For patent filings, the `essentialPoseSet` (cumulative weight ≥ 95%) defines
/// the minimal set of binding modes that must be disclosed to fully characterize
/// the binding interaction.
public struct PoseAttribution: Sendable {
    /// Index in the original results array.
    public let poseIndex: Int

    /// Substance identifier.
    public let substanceId: String

    /// Receptor/target identifier.
    public let receptorId: String

    /// Raw docking score from FlexAID (lower = better).
    public let dockingScore: Double

    /// ΔS_config in bits (negative = binding constrains).
    public let deltaSConfigBits: Double

    /// ΔG contribution in kcal/mol (from -TΔS conversion).
    public let freeEnergyKcal: Double

    /// Boltzmann population fraction pᵢ = gᵢ · exp(-βΔGᵢ) / Z.
    /// This is the probability of observing this binding mode at equilibrium.
    public let boltzmannWeight: Double

    /// Degeneracy factor (number of equivalent conformations this pose represents).
    public let degeneracy: Double

    /// Shannon importance: Iᵢ = -log₂(pᵢ) bits.
    /// Lower = more important (less surprising to observe).
    /// The dominant pose has the lowest Shannon importance.
    public let shannonImportanceBits: Double

    /// Number of rotatable bonds analyzed.
    public let bondCount: Int

    /// Mean fractional entropy loss across bonds (0–1).
    public let meanFractionalLoss: Double

    /// Whether |ΔS| exceeds the significance threshold.
    public let bindingDetected: Bool

    /// Rank by Boltzmann weight (1 = most important). Assigned after sorting.
    public var rank: Int = 0

    /// Cumulative Boltzmann weight up to and including this pose. Assigned after sorting.
    public var cumulativeWeight: Double = 0.0

    /// Whether this pose is in the essential set (cumulative weight before this
    /// pose was below 95%, meaning this pose is needed to reach the threshold).
    public var isEssential: Bool { (cumulativeWeight - boltzmannWeight) < 0.95 }

    /// Bilingual summary for this single pose.
    public var summary: LocalizedString {
        let pctText = String(format: "%.1f", boltzmannWeight * 100)
        let gText = String(format: "%.2f", freeEnergyKcal)
        let dsText = String(format: "%.2f", deltaSConfigBits)
        let cumText = String(format: "%.1f", cumulativeWeight * 100)

        return LocalizedString(
            en: "Pose #\(rank) [\(substanceId)→\(receptorId)]: " +
                "p = \(pctText)%, ΔG = \(gText) kcal/mol, ΔS = \(dsText) bits. " +
                "Cumulative: \(cumText)%. \(isEssential ? "Essential." : "Non-essential.")",
            fr: "Pose #\(rank) [\(substanceId)→\(receptorId)] : " +
                "p = \(pctText) %, ΔG = \(gText) kcal/mol, ΔS = \(dsText) bits. " +
                "Cumulatif : \(cumText) %. \(isEssential ? "Essentielle." : "Non essentielle.")"
        )
    }
}
