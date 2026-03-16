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
    /// Each result contributes one microstate. The energy ΔGᵢ used for Boltzmann
    /// weighting is the docking score from the FlexAID scoring function (lower = better
    /// binding = higher Boltzmann weight). Configurational entropy data (ΔS_config)
    /// is preserved in each `PoseAttribution` as metadata.
    ///
    /// - Parameters:
    ///   - results: FlexAID∆S analysis results from independent simulations.
    ///   - degeneracies: Optional degeneracy factors gᵢ for each pose (default 1.0 each).
    ///     Use > 1.0 when a single representative pose stands for a cluster of similar conformations.
    ///     All values must be positive.
    /// - Returns: `EnsembleResult` with partition function, Boltzmann weights, and thermodynamic summary.
    public func computeEnsemble(
        results: [FlexAIDdSResult],
        degeneracies: [Double]? = nil
    ) -> EnsembleResult? {
        guard !results.isEmpty else { return nil }
        guard temperatureK > 0 else { return nil }

        let g = degeneracies ?? [Double](repeating: 1.0, count: results.count)
        guard g.count == results.count else { return nil }
        guard g.allSatisfy({ $0 > 0 }) else { return nil }

        // Step 1: Energy for Boltzmann weighting — docking score (lower = better binding)
        let freeEnergies = results.map { $0.dockingScore }

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

        // Steps 7-9 fused: ensemble entropy, Shannon entropy, mean energy.
        // Single pass with inline Kahan accumulators (eliminates 3×N allocations).
        var sumPLogP = 0.0, cPLogP = 0.0
        var sumPLog2P = 0.0, cPLog2P = 0.0
        var sumPE = 0.0, cPE = 0.0

        for i in 0..<populations.count {
            let p = populations[i]
            if p > 0 {
                kahanAccumulate(&sumPLogP, &cPLogP, p * log(p))
                kahanAccumulate(&sumPLog2P, &cPLog2P, p * log2(p))
            }
            kahanAccumulate(&sumPE, &cPE, p * freeEnergies[i])
        }

        let ensembleEntropyKcalPerK = -Self.kB * sumPLogP
        let shannonEntropyBits = -sumPLog2P
        let meanEnergy = sumPE

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
            attributions: attributions,
            sourceResults: results,
            sourceDegeneracies: g
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
    /// - Note: Degeneracies are aligned to surviving poses by original index.
    ///   If some poses fail analysis, only their corresponding degeneracy entries
    ///   are dropped (matching the parallel path's behavior).
    public func computeEnsembleFromPoses(
        freeConformation: LigandConformation,
        dockingPoses: [DockingPose],
        degeneracies: [Double]? = nil
    ) -> EnsembleResult? {
        var results: [FlexAIDdSResult] = []
        var survivingIndices: [Int] = []
        for (i, pose) in dockingPoses.enumerated() {
            if let r = dockingAnalyzer.analyze(freeConformation: freeConformation, dockingPose: pose) {
                results.append(r)
                survivingIndices.append(i)
            }
        }
        let effectiveDegeneracies: [Double]?
        if let g = degeneracies {
            effectiveDegeneracies = survivingIndices.map { g[$0] }
        } else {
            effectiveDegeneracies = nil
        }
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

        // Sort by Boltzmann weight descending (most important first).
        // Use poseIndex as tiebreaker for deterministic ordering when weights are equal.
        attributions.sort {
            if $0.boltzmannWeight != $1.boltzmannWeight {
                return $0.boltzmannWeight > $1.boltzmannWeight
            }
            return $0.poseIndex < $1.poseIndex
        }

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

    /// Inline Kahan accumulation step for fused multi-sum loops.
    private func kahanAccumulate(_ sum: inout Double, _ c: inout Double, _ value: Double) {
        let y = value - c
        let t = sum + y
        c = (t - sum) - y
        sum = t
    }

    // MARK: - Auto-Degeneracy via Energy Binning (FOPTICS Analogy)

    /// Compute the ensemble with automatic degeneracy factors derived from energy binning.
    ///
    /// Inspired by FlexAID's FOPTICS clustering (`FOPTICS.cpp`), which groups docking
    /// poses into `BindingMode` objects by density-based reachability. Here, poses are
    /// grouped by docking score proximity: poses within the same energy bin are treated
    /// as degenerate microstates of the same binding mode.
    ///
    /// This converts the sum Z = Σ exp(-βEᵢ) from a sum over N poses to a sum over
    /// B energy bins with degeneracy g(E) = count: Z ≈ Σ_bins g(Eₖ)·exp(-βEₖ).
    ///
    /// - Parameters:
    ///   - results: FlexAID∆S analysis results.
    ///   - binWidth: Energy bin width in kcal/mol. Default: kT at current temperature
    ///     (≈ 0.59 kcal/mol at 298K), meaning poses within one thermal fluctuation
    ///     are grouped together.
    /// - Returns: `EnsembleResult` with degeneracies derived from bin counts.
    public func computeEnsembleWithAutoDegeneracy(
        results: [FlexAIDdSResult],
        binWidth: Double? = nil
    ) -> EnsembleResult? {
        guard !results.isEmpty else { return nil }

        let width = binWidth ?? (Self.kB * temperatureK)
        guard width > 0 else { return nil }

        // Sort by docking score for binning
        let sorted = results.sorted { $0.dockingScore < $1.dockingScore }

        // Bin poses by energy proximity
        var bins: [(representative: FlexAIDdSResult, count: Double)] = []
        var currentBinStart = sorted[0].dockingScore
        var currentBinResults: [FlexAIDdSResult] = [sorted[0]]

        for result in sorted.dropFirst() {
            if result.dockingScore - currentBinStart <= width {
                currentBinResults.append(result)
            } else {
                // Use the result closest to the bin mean as representative
                let meanScore = currentBinResults.reduce(0.0) { $0 + $1.dockingScore } / Double(currentBinResults.count)
                let representative = currentBinResults.min { abs($0.dockingScore - meanScore) < abs($1.dockingScore - meanScore) }!
                bins.append((representative, Double(currentBinResults.count)))
                currentBinResults = [result]
                currentBinStart = result.dockingScore
            }
        }
        // Flush final bin
        let meanScore = currentBinResults.reduce(0.0) { $0 + $1.dockingScore } / Double(currentBinResults.count)
        let representative = currentBinResults.min { abs($0.dockingScore - meanScore) < abs($1.dockingScore - meanScore) }!
        bins.append((representative, Double(currentBinResults.count)))

        let representatives = bins.map(\.representative)
        let degeneracies = bins.map(\.count)
        return computeEnsemble(results: representatives, degeneracies: degeneracies)
    }

    // MARK: - Incremental Partition Function (GetCleft Merge Analogy)

    /// Absorb new results into an existing ensemble by combining and recomputing.
    ///
    /// Inspired by GetCleft's `merge_clefts()` which splices overlapping sphere lists
    /// into existing clefts. Here, new results are concatenated with the original
    /// results (preserved in `existing.sourceResults`) and the partition function
    /// is recomputed over the combined set.
    ///
    /// - Parameters:
    ///   - newResults: Additional FlexAID∆S results to absorb.
    ///   - existing: The current ensemble to extend.
    ///   - newDegeneracies: Optional degeneracy factors for the new results.
    /// - Returns: Updated ensemble incorporating both old and new results.
    public func absorb(
        newResults: [FlexAIDdSResult],
        into existing: EnsembleResult,
        newDegeneracies: [Double]? = nil
    ) -> EnsembleResult? {
        guard !newResults.isEmpty else { return existing }

        let newG = newDegeneracies ?? [Double](repeating: 1.0, count: newResults.count)
        guard newG.count == newResults.count else { return nil }

        // Use preserved original results and degeneracies instead of reconstructing stubs.
        // This ensures full FlexAIDdSResult metadata (bondResults, totalDeltaSConfig, etc.)
        // is carried through to the new ensemble.
        let combinedResults = existing.sourceResults + newResults
        let combinedDegeneracies = existing.sourceDegeneracies + newG

        return computeEnsemble(results: combinedResults, degeneracies: combinedDegeneracies)
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
    let effectivePartitionFunction: Double

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

    /// Original results used to compute this ensemble (preserved for incremental absorb).
    internal let sourceResults: [FlexAIDdSResult]

    /// Degeneracy factors used to compute this ensemble (preserved for incremental absorb).
    internal let sourceDegeneracies: [Double]

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

    // MARK: - Binding Mode Clustering (GetCleft Connected-Component Analogy)

    /// Group essential poses into distinct binding modes by energy proximity.
    ///
    /// Inspired by GetCleft's connected-component analysis where overlapping spheres
    /// form clefts. Here, poses whose docking scores are within `energyRadius` of
    /// each other are "connected" and grouped into the same binding mode.
    ///
    /// Uses greedy sequential merging (like GetCleft's `merge_clefts()`): poses
    /// sorted by energy, consecutive poses within radius are grouped.
    ///
    /// - Parameter energyRadius: Maximum energy difference (kcal/mol) to consider
    ///   two poses as "connected" (same binding mode). Default: 2·kT.
    /// - Returns: Array of binding mode groups, each containing connected poses
    ///   sorted by Boltzmann weight. Groups are sorted by total weight descending.
    public func bindingModes(energyRadius: Double? = nil) -> [[PoseAttribution]] {
        let kT = 1.987e-3 * temperatureK
        let radius = energyRadius ?? (2.0 * kT)
        let essential = attributions.filter(\.isEssential)
        guard !essential.isEmpty else { return [] }

        // Sort by energy for greedy sequential merge
        let sorted = essential.sorted { $0.freeEnergyKcal < $1.freeEnergyKcal }

        var modes: [[PoseAttribution]] = [[sorted[0]]]
        for pose in sorted.dropFirst() {
            if let lastPose = modes[modes.count - 1].last,
               abs(pose.freeEnergyKcal - lastPose.freeEnergyKcal) <= radius {
                modes[modes.count - 1].append(pose)
            } else {
                modes.append([pose])
            }
        }

        // Sort groups by total Boltzmann weight descending
        modes.sort { a, b in
            a.reduce(0.0) { $0 + $1.boltzmannWeight } > b.reduce(0.0) { $0 + $1.boltzmannWeight }
        }

        return modes
    }

    // MARK: - Energy-Entropy Landscape Fingerprint (Cube Grid Analogy)

    /// Discretize the binding landscape into a 2D (energy × entropy) grid.
    ///
    /// Inspired by FlexAID's cube grid which discretizes 3D space into vertices
    /// at 0.375 Å spacing. Here, the "space" is the (dockingScore, ΔS_config) plane,
    /// and each grid cell summarizes a class of poses.
    ///
    /// Enables rapid comparison of binding landscapes across ligands or targets.
    ///
    /// - Parameters:
    ///   - energyBinWidth: Energy bin width in kcal/mol (default: 1.0).
    ///   - entropyBinWidth: Entropy bin width in bits (default: 0.5).
    /// - Returns: A `BindingLandscapeFingerprint` summarizing the pose distribution.
    public func landscapeFingerprint(
        energyBinWidth: Double = 1.0,
        entropyBinWidth: Double = 0.5
    ) -> BindingLandscapeFingerprint {
        guard !attributions.isEmpty, energyBinWidth > 0, entropyBinWidth > 0 else {
            return BindingLandscapeFingerprint(cells: [], energyBinWidth: energyBinWidth, entropyBinWidth: entropyBinWidth)
        }

        let minEnergy = attributions.map(\.dockingScore).min()!
        let minEntropy = attributions.map(\.deltaSConfigBits).min()!

        // Bin each pose into a 2D cell
        var cellMap: [Int: [Int: (count: Int, weight: Double)]] = [:]
        for attr in attributions {
            let eBin = Int(floor((attr.dockingScore - minEnergy) / energyBinWidth))
            let sBin = Int(floor((attr.deltaSConfigBits - minEntropy) / entropyBinWidth))
            var row = cellMap[eBin] ?? [:]
            let existing = row[sBin] ?? (count: 0, weight: 0.0)
            row[sBin] = (count: existing.count + 1, weight: existing.weight + attr.boltzmannWeight)
            cellMap[eBin] = row
        }

        // Flatten to array
        var cells: [BindingLandscapeFingerprint.Cell] = []
        for (eBin, row) in cellMap {
            for (sBin, data) in row {
                cells.append(BindingLandscapeFingerprint.Cell(
                    energyBin: eBin,
                    entropyBin: sBin,
                    poseCount: data.count,
                    totalWeight: data.weight
                ))
            }
        }

        // Sort by total weight descending for convenient access
        cells.sort { $0.totalWeight > $1.totalWeight }

        return BindingLandscapeFingerprint(
            cells: cells,
            energyBinWidth: energyBinWidth,
            entropyBinWidth: entropyBinWidth
        )
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

    /// Docking score used for Boltzmann weighting (lower = better binding).
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

// MARK: - Binding Landscape Fingerprint (Cube Grid Analogy)

/// 2D energy–entropy fingerprint of the binding landscape.
///
/// Inspired by FlexAID's cube grid which discretizes 3D space into vertices
/// at 0.375 Å spacing, each serving as an anchor point for the ligand reference
/// atom. Here, the "space" is the (dockingScore, ΔS_config) plane, and each
/// grid cell summarizes a class of thermodynamically similar poses.
///
/// Enables rapid comparison of binding landscapes across ligands or targets
/// without comparing individual poses — analogous to how cube grids enable
/// fast ligand placement without continuous translation search.
public struct BindingLandscapeFingerprint: Sendable {
    /// A single cell in the 2D grid.
    public struct Cell: Sendable {
        /// Energy bin index (0 = lowest energy, i.e., best binder).
        public let energyBin: Int
        /// Entropy bin index (0 = most negative ΔS, i.e., most constrained).
        public let entropyBin: Int
        /// Number of poses falling in this cell.
        public let poseCount: Int
        /// Total Boltzmann weight of poses in this cell.
        public let totalWeight: Double
    }

    /// All non-empty cells, sorted by total Boltzmann weight descending.
    public let cells: [Cell]
    /// Energy bin width (kcal/mol).
    public let energyBinWidth: Double
    /// Entropy bin width (bits).
    public let entropyBinWidth: Double

    /// Total number of non-empty cells (distinct landscape regions).
    public var occupiedCellCount: Int { cells.count }
}
