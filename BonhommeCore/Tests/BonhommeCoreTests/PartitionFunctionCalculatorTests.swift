import XCTest
@testable import BonhommeCore

/// Tests validating the global partition function calculation from independent
/// FlexAID∆S docking simulations.
///
/// Validates:
/// 1. Boltzmann weight calculation and normalization (Σpᵢ = 1)
/// 2. Ensemble free energy ΔG_ens ≤ min(ΔGᵢ)
/// 3. Shannon entropy bounds: 0 ≤ H ≤ log₂(N)
/// 4. Effective pose count N_eff consistency
/// 5. Essential pose set extraction (cumulative ≥ 95%)
/// 6. Single-pose dominance vs. entropic binder classification
/// 7. Degeneracy factors
/// 8. Parallel computation consistency
/// 9. Pose importance attribution and ranking
final class PartitionFunctionCalculatorTests: XCTestCase {

    // MARK: - Helpers

    /// Generate a torsional angle distribution with known spread.
    private func makeAngles(
        bondId: String = "bond_1",
        center: Double = 0.0,
        spread: Double = 180.0,
        count: Int = 200
    ) -> TorsionalAngleDistribution {
        guard count > 1, spread > 0 else {
            let constAngles = (0..<max(count, 2)).map { center + Double($0 % 2) * 0.5 }
            return TorsionalAngleDistribution(bondId: bondId, angles: constAngles)
        }
        let step = (spread * 2) / Double(count - 1)
        let angles = (0..<count).map { i in
            (center - spread) + step * Double(i)
        }
        return TorsionalAngleDistribution(bondId: bondId, angles: angles)
    }

    /// Build a LigandConformation with N bonds, all sharing the same spread.
    private func makeConformation(
        substanceId: String = "test-ligand",
        name: String = "Test Ligand",
        bondCount: Int,
        spread: Double
    ) -> LigandConformation {
        let bonds = (0..<bondCount).map { i in
            makeAngles(bondId: "bond_\(i)", spread: spread)
        }
        return LigandConformation(
            substanceId: substanceId,
            name: LocalizedString(en: name, fr: name),
            bonds: bonds
        )
    }

    /// Build a DockingPose from a bound conformation.
    private func makePose(
        conformation: LigandConformation,
        receptorId: String = "1ABC",
        dockingScore: Double = -8.5,
        bindingFreeEnergy: Double? = nil
    ) -> DockingPose {
        DockingPose(
            boundConformation: conformation,
            receptorId: receptorId,
            dockingScore: dockingScore,
            bindingFreeEnergy: bindingFreeEnergy
        )
    }

    /// Build FlexAIDdSResult directly with known values for controlled testing.
    private func makeResult(
        substanceId: String = "test-ligand",
        receptorId: String = "1ABC",
        deltaSBits: Double,
        dockingScore: Double = -8.5,
        bondCount: Int = 3
    ) -> FlexAIDdSResult {
        // Create bond results that sum to the desired total ΔS
        let perBond = deltaSBits / Double(bondCount)
        let bondResults = (0..<bondCount).map { i in
            BondEntropyResult(
                bondId: "bond_\(i)",
                freeEntropy: 4.0,                    // ~uniform free state
                boundEntropy: 4.0 + perBond          // shifted by ΔS/N
            )
        }
        return FlexAIDdSResult(
            substanceId: substanceId,
            receptorId: receptorId,
            bondResults: bondResults,
            dockingScore: dockingScore
        )
    }

    // MARK: - Basic Partition Function

    /// Single pose: Z should have one state, p₁ = 1.0, H = 0.
    func testSinglePose() {
        let calc = PartitionFunctionCalculator()
        let results = [makeResult(deltaSBits: -3.0)]

        let ensemble = calc.computeEnsemble(results: results)
        XCTAssertNotNil(ensemble)
        guard let ens = ensemble else { return }

        // Single state: population must be 1.0
        XCTAssertEqual(ens.attributions.count, 1)
        XCTAssertEqual(ens.attributions[0].boltzmannWeight, 1.0, accuracy: 1e-10)

        // Shannon entropy of single state = 0
        XCTAssertEqual(ens.shannonEntropyBits, 0.0, accuracy: 1e-10)

        // Effective pose count = 1
        XCTAssertEqual(ens.effectivePoseCount, 1.0, accuracy: 1e-6)

        // Single pose dominant
        XCTAssertTrue(ens.isSinglePoseDominant)
        XCTAssertFalse(ens.isEntropicBinder)

        // Rank = 1, cumulative = 1.0
        XCTAssertEqual(ens.attributions[0].rank, 1)
        XCTAssertEqual(ens.attributions[0].cumulativeWeight, 1.0, accuracy: 1e-10)
    }

    /// Two identical poses: each should have p = 0.5, H = 1.0 bit.
    func testTwoIdenticalPoses() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -3.0),
            makeResult(deltaSBits: -3.0)
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        // Equal populations
        XCTAssertEqual(ensemble.attributions[0].boltzmannWeight, 0.5, accuracy: 1e-6)
        XCTAssertEqual(ensemble.attributions[1].boltzmannWeight, 0.5, accuracy: 1e-6)

        // Shannon entropy = log₂(2) = 1.0
        XCTAssertEqual(ensemble.shannonEntropyBits, 1.0, accuracy: 1e-6)

        // N_eff = 2
        XCTAssertEqual(ensemble.effectivePoseCount, 2.0, accuracy: 1e-4)
    }

    /// Boltzmann weights must sum to exactly 1.0.
    func testBoltzmannWeightsNormalize() {
        let calc = PartitionFunctionCalculator()
        let results = (0..<10).map { i in
            makeResult(deltaSBits: -Double(i + 1) * 0.5, dockingScore: -Double(i + 1) * 1.0)
        }

        let ensemble = calc.computeEnsemble(results: results)!
        let totalWeight = ensemble.attributions.reduce(0.0) { $0 + $1.boltzmannWeight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 1e-10)
    }

    // MARK: - Ensemble Free Energy

    /// ΔG_ens must be ≤ min(ΔGᵢ) because the ensemble has more accessible states.
    func testEnsembleFreeEnergyLowerBound() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -1.0, dockingScore: -5.0),
            makeResult(deltaSBits: -3.0, dockingScore: -8.0),
            makeResult(deltaSBits: -5.0, dockingScore: -12.0)
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        // Energy for Boltzmann weighting is now the docking score
        let minDeltaG = results.map { $0.dockingScore }.min()!

        // Ensemble ΔG must be ≤ best single-state ΔG
        XCTAssertLessThanOrEqual(ensemble.ensembleFreeEnergy, minDeltaG + 1e-10)
    }

    // MARK: - Shannon Entropy Bounds

    /// H must be in [0, log₂(N)] for any ensemble.
    func testShannonEntropyBounds() {
        let calc = PartitionFunctionCalculator()
        let n = 8
        let results = (0..<n).map { i in
            makeResult(deltaSBits: -Double(i + 1) * 0.7, dockingScore: -Double(i + 1) * 1.5)
        }

        let ensemble = calc.computeEnsemble(results: results)!

        XCTAssertGreaterThanOrEqual(ensemble.shannonEntropyBits, 0.0)
        XCTAssertLessThanOrEqual(ensemble.shannonEntropyBits, log2(Double(n)) + 1e-10)
    }

    /// N identical poses → H = log₂(N) (maximum entropy).
    func testMaximumEntropy() {
        let calc = PartitionFunctionCalculator()
        let n = 16
        let results = (0..<n).map { _ in
            makeResult(deltaSBits: -3.0)
        }

        let ensemble = calc.computeEnsemble(results: results)!

        // All identical → uniform → max entropy
        XCTAssertEqual(ensemble.shannonEntropyBits, log2(Double(n)), accuracy: 1e-6)
        XCTAssertEqual(ensemble.effectivePoseCount, Double(n), accuracy: 1e-4)
    }

    // MARK: - Effective Pose Count

    /// N_eff = 2^H. For uniform distribution, N_eff = N.
    func testEffectivePoseCountUniform() {
        let calc = PartitionFunctionCalculator()
        let results = (0..<4).map { _ in makeResult(deltaSBits: -2.0) }

        let ensemble = calc.computeEnsemble(results: results)!
        XCTAssertEqual(ensemble.effectivePoseCount, 4.0, accuracy: 1e-4)
    }

    /// When one pose dominates, N_eff → 1.
    func testEffectivePoseCountDominant() {
        let calc = PartitionFunctionCalculator()
        // One very favorable pose (best docking score), others much worse
        var results = [makeResult(deltaSBits: -10.0, dockingScore: -15.0)]  // dominant
        results += (0..<5).map { _ in makeResult(deltaSBits: -0.1, dockingScore: -5.0) }  // negligible

        let ensemble = calc.computeEnsemble(results: results)!
        XCTAssertLessThan(ensemble.effectivePoseCount, 2.0)
        XCTAssertTrue(ensemble.isSinglePoseDominant)
    }

    // MARK: - Entropic Binder Detection

    /// When many poses contribute equally, classify as entropic binder.
    func testEntropicBinderDetection() {
        let calc = PartitionFunctionCalculator()
        let results = (0..<10).map { _ in makeResult(deltaSBits: -3.0) }

        let ensemble = calc.computeEnsemble(results: results)!
        XCTAssertTrue(ensemble.isEntropicBinder)
        XCTAssertFalse(ensemble.isSinglePoseDominant)
    }

    // MARK: - Ranking and Attribution

    /// Poses must be ranked by Boltzmann weight descending.
    /// Best docking score (most negative) → highest Boltzmann weight → rank 1.
    func testPoseRanking() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(substanceId: "weak", deltaSBits: -1.0, dockingScore: -5.0),
            makeResult(substanceId: "strong", deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(substanceId: "medium", deltaSBits: -3.0, dockingScore: -7.5)
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        // Rank 1 should have the highest Boltzmann weight (best docking score)
        XCTAssertEqual(ensemble.attributions[0].rank, 1)
        XCTAssertEqual(ensemble.attributions[0].substanceId, "strong")
        XCTAssertEqual(ensemble.attributions[1].substanceId, "medium")
        XCTAssertEqual(ensemble.attributions[2].substanceId, "weak")
        XCTAssertGreaterThan(
            ensemble.attributions[0].boltzmannWeight,
            ensemble.attributions[1].boltzmannWeight
        )
        XCTAssertGreaterThan(
            ensemble.attributions[1].boltzmannWeight,
            ensemble.attributions[2].boltzmannWeight
        )

        // Cumulative weight must reach 1.0
        XCTAssertEqual(ensemble.attributions.last!.cumulativeWeight, 1.0, accuracy: 1e-10)
    }

    /// Shannon importance: dominant pose has lowest I (least surprising).
    func testShannonImportance() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -1.0, dockingScore: -5.0)
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        // The pose with higher p has lower Shannon importance (less surprising)
        let dominant = ensemble.attributions[0]
        let minor = ensemble.attributions[1]
        XCTAssertLessThan(dominant.shannonImportanceBits, minor.shannonImportanceBits)
    }

    // MARK: - Essential Pose Set

    /// Essential set must reach 95% cumulative weight.
    func testEssentialPoseSet() {
        let calc = PartitionFunctionCalculator()
        // One dominant (best docking score) + many minor poses
        var results = [makeResult(deltaSBits: -8.0, dockingScore: -15.0)]
        results += (0..<9).map { _ in makeResult(deltaSBits: -1.0, dockingScore: -5.0) }

        let ensemble = calc.computeEnsemble(results: results)!
        let essential = calc.essentialPoseSet(from: ensemble, threshold: 0.95)

        // Should need fewer poses than total
        XCTAssertLessThan(essential.count, ensemble.poseCount)

        // Cumulative of essential set ≥ 0.95
        let cumWeight = essential.reduce(0.0) { $0 + $1.boltzmannWeight }
        XCTAssertGreaterThanOrEqual(cumWeight, 0.95)
    }

    /// With uniform distribution, essential set needs most poses.
    func testEssentialPoseSetUniform() {
        let calc = PartitionFunctionCalculator()
        let n = 10
        let results = (0..<n).map { _ in makeResult(deltaSBits: -3.0) }

        let ensemble = calc.computeEnsemble(results: results)!
        let essential = calc.essentialPoseSet(from: ensemble, threshold: 0.95)

        // Uniform: need ≥ 95% of N poses
        XCTAssertGreaterThanOrEqual(essential.count, Int(ceil(0.95 * Double(n))))
    }

    // MARK: - Degeneracy Factors

    /// A pose with degeneracy g=2 should have double the weight of g=1 (same energy).
    func testDegeneracyFactors() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -3.0),
            makeResult(deltaSBits: -3.0)
        ]
        let degeneracies = [2.0, 1.0]

        let ensemble = calc.computeEnsemble(results: results, degeneracies: degeneracies)!

        // With equal energies and g=[2,1], populations should be [2/3, 1/3]
        let sorted = ensemble.attributions.sorted { $0.poseIndex < $1.poseIndex }
        XCTAssertEqual(sorted[0].boltzmannWeight, 2.0 / 3.0, accuracy: 1e-6)
        XCTAssertEqual(sorted[1].boltzmannWeight, 1.0 / 3.0, accuracy: 1e-6)
    }

    /// Mismatched degeneracy array returns nil.
    func testDegeneracyMismatchReturnsNil() {
        let calc = PartitionFunctionCalculator()
        let results = [makeResult(deltaSBits: -3.0)]
        let degeneracies = [1.0, 2.0]  // wrong length

        let ensemble = calc.computeEnsemble(results: results, degeneracies: degeneracies)
        XCTAssertNil(ensemble)
    }

    // MARK: - Edge Cases

    /// Empty input returns nil.
    func testEmptyInputReturnsNil() {
        let calc = PartitionFunctionCalculator()
        XCTAssertNil(calc.computeEnsemble(results: []))
    }

    /// Temperature scaling: higher T → more uniform distribution.
    func testTemperatureEffect() {
        let lowT = PartitionFunctionCalculator(temperatureK: 200.0)
        let highT = PartitionFunctionCalculator(temperatureK: 500.0)

        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -1.0, dockingScore: -5.0)
        ]

        let ensLow = lowT.computeEnsemble(results: results)!
        let ensHigh = highT.computeEnsemble(results: results)!

        // Higher T → more entropy (more uniform)
        XCTAssertGreaterThan(ensHigh.shannonEntropyBits, ensLow.shannonEntropyBits)
    }

    // MARK: - End-to-End with Raw Poses

    /// Full pipeline: free conformation → docking poses → partition function.
    func testEndToEndFromPoses() {
        let calc = PartitionFunctionCalculator()

        let freeConf = makeConformation(bondCount: 3, spread: 180.0)

        // Three docking poses with different constraint levels
        let poses = [
            makePose(conformation: makeConformation(bondCount: 3, spread: 10.0),
                     receptorId: "1ABC", dockingScore: -9.0),
            makePose(conformation: makeConformation(bondCount: 3, spread: 50.0),
                     receptorId: "1ABC", dockingScore: -7.0),
            makePose(conformation: makeConformation(bondCount: 3, spread: 120.0),
                     receptorId: "1ABC", dockingScore: -5.0)
        ]

        let ensemble = calc.computeEnsembleFromPoses(
            freeConformation: freeConf,
            dockingPoses: poses
        )
        XCTAssertNotNil(ensemble)
        guard let ens = ensemble else { return }

        // Basic sanity
        XCTAssertEqual(ens.poseCount, 3)
        let totalWeight = ens.attributions.reduce(0.0) { $0 + $1.boltzmannWeight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 1e-10)

        // Pose with best docking score (-9.0, spread=10) should have highest Boltzmann weight
        XCTAssertEqual(ens.attributions[0].rank, 1)
        XCTAssertEqual(ens.attributions[0].dockingScore, -9.0)
        XCTAssertTrue(ens.attributions[0].bindingDetected)
    }

    // MARK: - Parallel Computation Consistency

    /// Parallel and sequential computation must produce identical results,
    /// including per-pose poseIndex alignment (tests deterministic ordering).
    func testParallelConsistency() async {
        let calc = PartitionFunctionCalculator()

        let freeConf = makeConformation(bondCount: 3, spread: 180.0)

        let poses = (0..<20).map { i in
            makePose(
                conformation: makeConformation(bondCount: 3, spread: 10.0 + Double(i) * 8.0),
                receptorId: "1ABC",
                dockingScore: -5.0 - Double(i) * 0.3
            )
        }

        let sequential = calc.computeEnsembleFromPoses(
            freeConformation: freeConf,
            dockingPoses: poses
        )

        let parallel = await calc.computeEnsembleParallel(
            freeConformation: freeConf,
            dockingPoses: poses
        )

        XCTAssertNotNil(sequential)
        XCTAssertNotNil(parallel)
        guard let seq = sequential, let par = parallel else { return }

        // Same number of poses
        XCTAssertEqual(seq.poseCount, par.poseCount)

        // Ensemble free energy should match
        XCTAssertEqual(seq.ensembleFreeEnergy, par.ensembleFreeEnergy, accuracy: 1e-6)

        // Shannon entropy should match
        XCTAssertEqual(seq.shannonEntropyBits, par.shannonEntropyBits, accuracy: 1e-6)

        // Log partition function should match
        XCTAssertEqual(seq.logPartitionFunction, par.logPartitionFunction, accuracy: 1e-6)

        // All weights should sum to 1.0 in both
        let seqTotal = seq.attributions.reduce(0.0) { $0 + $1.boltzmannWeight }
        let parTotal = par.attributions.reduce(0.0) { $0 + $1.boltzmannWeight }
        XCTAssertEqual(seqTotal, 1.0, accuracy: 1e-10)
        XCTAssertEqual(parTotal, 1.0, accuracy: 1e-10)

        // Per-pose reproducibility: same poseIndex order and identical weights.
        // Attributions are sorted by Boltzmann weight, so if ordering is
        // deterministic the poseIndex sequences must match exactly.
        let seqIndices = seq.attributions.map(\.poseIndex)
        let parIndices = par.attributions.map(\.poseIndex)
        XCTAssertEqual(seqIndices, parIndices, "Parallel poseIndex order must match sequential")

        for (s, p) in zip(seq.attributions, par.attributions) {
            XCTAssertEqual(s.boltzmannWeight, p.boltzmannWeight, accuracy: 1e-10,
                           "Boltzmann weight mismatch at pose \(s.poseIndex)")
            XCTAssertEqual(s.freeEnergyKcal, p.freeEnergyKcal, accuracy: 1e-10,
                           "Free energy mismatch at pose \(s.poseIndex)")
        }
    }

    // MARK: - isEssential Boundary Correctness

    /// The pose that crosses the 95% threshold must be marked essential.
    func testIsEssentialBoundaryPose() {
        let calc = PartitionFunctionCalculator()
        // Construct an ensemble where the top pose has ~60% and #2 has ~30%,
        // so pose #2 is the one that crosses 95% cumulative.
        let results = [
            makeResult(deltaSBits: -6.0, dockingScore: -12.0),   // dominant
            makeResult(deltaSBits: -4.0, dockingScore: -9.0),    // strong
            makeResult(deltaSBits: -0.5, dockingScore: -4.0),    // weak
            makeResult(deltaSBits: -0.3, dockingScore: -3.0),    // very weak
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        // Top pose should always be essential
        XCTAssertTrue(ensemble.attributions[0].isEssential)

        // Find the pose whose cumulativeWeight first crosses 0.95
        let crossingIdx = ensemble.attributions.firstIndex { $0.cumulativeWeight >= 0.95 }
        XCTAssertNotNil(crossingIdx)
        if let idx = crossingIdx {
            XCTAssertTrue(ensemble.attributions[idx].isEssential,
                          "Pose crossing 95% threshold must be marked essential")
        }

        // Poses after the crossing should NOT be essential
        if let idx = crossingIdx, idx + 1 < ensemble.attributions.count {
            XCTAssertFalse(ensemble.attributions[idx + 1].isEssential,
                           "Pose after 95% crossing should be non-essential")
        }
    }

    /// A single dominant pose (p > 95%) should be the only essential pose.
    func testIsEssentialSingleDominant() {
        let calc = PartitionFunctionCalculator()
        var results = [makeResult(deltaSBits: -10.0, dockingScore: -20.0)]  // dominant
        results += (0..<4).map { _ in makeResult(deltaSBits: -0.1, dockingScore: -3.0) }

        let ensemble = calc.computeEnsemble(results: results)!

        XCTAssertTrue(ensemble.attributions[0].isEssential)
        XCTAssertTrue(ensemble.attributions[0].cumulativeWeight > 0.95)
        // All others should be non-essential
        for attr in ensemble.attributions.dropFirst() {
            XCTAssertFalse(attr.isEssential)
        }
    }

    // MARK: - Log-Space Partition Function

    /// Log-space Z must be consistent with ensemble free energy: ΔG = -kT · ln(Z).
    func testLogPartitionFunctionConsistency() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -3.0, dockingScore: -6.0),
            makeResult(deltaSBits: -5.0, dockingScore: -9.0),
            makeResult(deltaSBits: -7.0, dockingScore: -12.0)
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        // ΔG_ens = -kT · ln(Z_true)  →  ln(Z_true) = -ΔG_ens / (kT)
        let kT = 1.987e-3 * 298.0
        let expectedLogZ = -ensemble.ensembleFreeEnergy / kT
        XCTAssertEqual(ensemble.logPartitionFunction, expectedLogZ, accuracy: 1e-8)
    }

    /// Extreme energy values that would overflow exp() are safe in log-space.
    func testLogPartitionFunctionNoOverflow() {
        let calc = PartitionFunctionCalculator()
        // Wide spread of docking scores to test numerical stability.
        let results = (0..<5).map { i in
            makeResult(deltaSBits: -Double(i + 1) * 20.0, dockingScore: -Double(i + 1) * 20.0)
        }

        let ensemble = calc.computeEnsemble(results: results)
        XCTAssertNotNil(ensemble)
        guard let ens = ensemble else { return }

        // logPartitionFunction should be finite
        XCTAssertTrue(ens.logPartitionFunction.isFinite)
        XCTAssertTrue(ens.ensembleFreeEnergy.isFinite)

        // Weights still sum to 1.0
        let totalWeight = ens.attributions.reduce(0.0) { $0 + $1.boltzmannWeight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 1e-10)
    }

    // MARK: - Kahan Summation Accuracy

    /// Verify that many small weights still sum to exactly 1.0 with Kahan.
    func testKahanSummationManyPoses() {
        let calc = PartitionFunctionCalculator()
        // 100 identical poses: each p = 0.01, naive sum can drift at ~1e-14
        let results = (0..<100).map { _ in makeResult(deltaSBits: -3.0) }

        let ensemble = calc.computeEnsemble(results: results)!
        let totalWeight = ensemble.attributions.reduce(0.0) { $0 + $1.boltzmannWeight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 1e-14)

        // Each weight should be exactly 0.01
        for attr in ensemble.attributions {
            XCTAssertEqual(attr.boltzmannWeight, 0.01, accuracy: 1e-12)
        }
    }

    // MARK: - Summary Generation

    // MARK: - Input Validation Guards

    /// Zero temperature should return nil.
    func testZeroTemperatureReturnsNil() {
        let calc = PartitionFunctionCalculator(temperatureK: 0)
        let results = [makeResult(deltaSBits: -3.0)]
        XCTAssertNil(calc.computeEnsemble(results: results))
    }

    /// Negative degeneracy should return nil.
    func testNegativeDegeneracyReturnsNil() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -3.0),
            makeResult(deltaSBits: -3.0)
        ]
        let ensemble = calc.computeEnsemble(results: results, degeneracies: [-1.0, 1.0])
        XCTAssertNil(ensemble)
    }

    /// Zero degeneracy should return nil.
    func testZeroDegeneracyReturnsNil() {
        let calc = PartitionFunctionCalculator()
        let results = [makeResult(deltaSBits: -3.0)]
        let ensemble = calc.computeEnsemble(results: results, degeneracies: [0.0])
        XCTAssertNil(ensemble)
    }

    // MARK: - Sort Stability

    /// Poses with identical docking scores should be ordered by poseIndex.
    func testIdenticalWeightStability() {
        let calc = PartitionFunctionCalculator()
        let results = (0..<5).map { i in
            makeResult(substanceId: "pose_\(i)", deltaSBits: -3.0, dockingScore: -8.0)
        }
        let ensemble = calc.computeEnsemble(results: results)!
        // All weights equal → tiebreaker should order by poseIndex ascending
        let indices = ensemble.attributions.map(\.poseIndex)
        XCTAssertEqual(indices, [0, 1, 2, 3, 4])
    }

    // MARK: - Parallel with Degeneracies

    /// Parallel and sequential computation with degeneracies must match.
    func testParallelConsistencyWithDegeneracies() async {
        let calc = PartitionFunctionCalculator()
        let freeConf = makeConformation(bondCount: 3, spread: 180.0)
        let poses = (0..<10).map { i in
            makePose(
                conformation: makeConformation(bondCount: 3, spread: 10.0 + Double(i) * 15.0),
                receptorId: "1ABC",
                dockingScore: -5.0 - Double(i) * 0.5
            )
        }
        let degeneracies = (0..<10).map { Double($0 + 1) }

        let sequential = calc.computeEnsembleFromPoses(
            freeConformation: freeConf, dockingPoses: poses, degeneracies: degeneracies
        )
        let parallel = await calc.computeEnsembleParallel(
            freeConformation: freeConf, dockingPoses: poses, degeneracies: degeneracies
        )

        XCTAssertNotNil(sequential)
        XCTAssertNotNil(parallel)
        guard let seq = sequential, let par = parallel else { return }

        XCTAssertEqual(seq.poseCount, par.poseCount)
        for (s, p) in zip(
            seq.attributions.sorted(by: { $0.poseIndex < $1.poseIndex }),
            par.attributions.sorted(by: { $0.poseIndex < $1.poseIndex })
        ) {
            XCTAssertEqual(s.degeneracy, p.degeneracy, accuracy: 1e-10)
            XCTAssertEqual(s.boltzmannWeight, p.boltzmannWeight, accuracy: 1e-10)
        }
    }

    // MARK: - Energy Units Honesty

    /// Docking-score-only results → score-ensemble units (not kcal/mol).
    func testScoreEnsembleUnitsWhenDockingScoreOnly() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -3.0, dockingScore: -7.0),
            makeResult(deltaSBits: -1.0, dockingScore: -4.0)
        ]

        let ensemble = calc.computeEnsemble(results: results)
        XCTAssertNotNil(ensemble)
        guard let ens = ensemble else { return }

        XCTAssertEqual(ens.energyUnits, .scoreEnsemble)
        XCTAssertFalse(ens.energyUnits.isThermodynamic)
        XCTAssertEqual(ens.energyUnits.displayLabel, "score units")
        XCTAssertEqual(ens.energyUnits.rawValue, "score-ensemble")

        // Boltzmann energies must be docking scores
        if let e0 = ens.attributions.first(where: { $0.poseIndex == 0 })?.freeEnergyKcal {
            XCTAssertEqual(e0, -10.0, accuracy: 1e-12)
        } else {
            XCTFail("missing pose 0")
        }
        if let e1 = ens.attributions.first(where: { $0.poseIndex == 1 })?.freeEnergyKcal {
            XCTAssertEqual(e1, -7.0, accuracy: 1e-12)
        } else {
            XCTFail("missing pose 1")
        }

        // Summary must not claim absolute kcal/mol ΔG
        XCTAssertTrue(ens.summary.en.contains("score-ensemble") || ens.summary.en.contains("score units"))
        XCTAssertFalse(ens.summary.en.contains("kcal/mol"),
                       "Score-ensemble summary must not claim kcal/mol")
        XCTAssertTrue(ens.summary.fr.contains("score-ensemble") || ens.summary.fr.contains("score units"))
    }

    /// Full bindingFreeEnergy coverage → kcal/mol thermodynamic path.
    func testKcalPerMolUnitsWhenBindingFreeEnergyAvailable() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -100.0),  // scores intentionally diverge
            makeResult(deltaSBits: -3.0, dockingScore: -50.0),
            makeResult(deltaSBits: -1.0, dockingScore: -10.0)
        ]
        // True free energies in kcal/mol (different ranking than scores)
        let bindingFEs: [Double?] = [-8.5, -7.0, -5.5]

        let ensemble = calc.computeEnsemble(
            results: results,
            bindingFreeEnergies: bindingFEs
        )
        XCTAssertNotNil(ensemble)
        guard let ens = ensemble else { return }

        XCTAssertEqual(ens.energyUnits, .kcalPerMol)
        XCTAssertTrue(ens.energyUnits.isThermodynamic)
        XCTAssertEqual(ens.energyUnits.displayLabel, "kcal/mol")
        XCTAssertEqual(ens.energyUnits.rawValue, "kcal/mol")

        // Boltzmann energies must be binding free energies, not docking scores
        if let e0 = ens.attributions.first(where: { $0.poseIndex == 0 })?.freeEnergyKcal {
            XCTAssertEqual(e0, -8.5, accuracy: 1e-12)
        } else {
            XCTFail("missing pose 0")
        }
        if let e1 = ens.attributions.first(where: { $0.poseIndex == 1 })?.freeEnergyKcal {
            XCTAssertEqual(e1, -7.0, accuracy: 1e-12)
        } else {
            XCTFail("missing pose 1")
        }
        if let e2 = ens.attributions.first(where: { $0.poseIndex == 2 })?.freeEnergyKcal {
            XCTAssertEqual(e2, -5.5, accuracy: 1e-12)
        } else {
            XCTFail("missing pose 2")
        }

        // Dominant pose is lowest free energy (pose 0, -8.5 kcal/mol)
        XCTAssertEqual(ens.attributions[0].poseIndex, 0)
        XCTAssertEqual(ens.attributions[0].freeEnergyKcal, -8.5, accuracy: 1e-12)

        // Summary claims kcal/mol ΔG
        XCTAssertTrue(ens.summary.en.contains("kcal/mol"))
        XCTAssertTrue(ens.summary.en.contains("ΔG_ens"))
        XCTAssertFalse(ens.summary.en.contains("score-ensemble"))
        XCTAssertTrue(ens.summary.fr.contains("kcal/mol"))

        // Ensemble free energy must equal -kT ln(Z) with kcal energies
        let kT = 1.987e-3 * ens.temperatureK
        let expectedLogZ = -ens.ensembleFreeEnergy / kT
        XCTAssertEqual(ens.logPartitionFunction, expectedLogZ, accuracy: 1e-8)
    }

    /// Partial bindingFreeEnergy coverage must NOT mix units → score-ensemble fallback.
    func testPartialBindingFreeEnergyFallsBackToScoreEnsemble() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -3.0, dockingScore: -7.0)
        ]
        // One nil → cannot take kcal path
        let partial: [Double?] = [-8.5, nil]

        let ensemble = calc.computeEnsemble(
            results: results,
            bindingFreeEnergies: partial
        )!
        XCTAssertEqual(ensemble.energyUnits, .scoreEnsemble)
        // Energies are docking scores
        if let e0 = ensemble.attributions.first(where: { $0.poseIndex == 0 })?.freeEnergyKcal {
            XCTAssertEqual(e0, -10.0, accuracy: 1e-12)
        } else {
            XCTFail("missing pose 0")
        }
        if let e1 = ensemble.attributions.first(where: { $0.poseIndex == 1 })?.freeEnergyKcal {
            XCTAssertEqual(e1, -7.0, accuracy: 1e-12)
        } else {
            XCTFail("missing pose 1")
        }
    }

    /// From-poses path prefers DockingPose.bindingFreeEnergy when all present.
    func testFromPosesPrefersBindingFreeEnergy() {
        let calc = PartitionFunctionCalculator()
        let freeConf = makeConformation(bondCount: 3, spread: 180.0)

        let posesWithFE = [
            makePose(conformation: makeConformation(bondCount: 3, spread: 10.0),
                     dockingScore: -100.0, bindingFreeEnergy: -9.0),
            makePose(conformation: makeConformation(bondCount: 3, spread: 50.0),
                     dockingScore: -20.0, bindingFreeEnergy: -6.0),
            makePose(conformation: makeConformation(bondCount: 3, spread: 120.0),
                     dockingScore: -5.0, bindingFreeEnergy: -4.0)
        ]
        let kcalEns = calc.computeEnsembleFromPoses(
            freeConformation: freeConf,
            dockingPoses: posesWithFE
        )!
        XCTAssertEqual(kcalEns.energyUnits, .kcalPerMol)
        XCTAssertEqual(kcalEns.attributions[0].freeEnergyKcal, -9.0, accuracy: 1e-12)

        // Without bindingFreeEnergy → score-ensemble
        let posesScoreOnly = [
            makePose(conformation: makeConformation(bondCount: 3, spread: 10.0),
                     dockingScore: -9.0),
            makePose(conformation: makeConformation(bondCount: 3, spread: 50.0),
                     dockingScore: -6.0)
        ]
        let scoreEns = calc.computeEnsembleFromPoses(
            freeConformation: freeConf,
            dockingPoses: posesScoreOnly
        )!
        XCTAssertEqual(scoreEns.energyUnits, .scoreEnsemble)
        XCTAssertEqual(scoreEns.attributions[0].dockingScore, -9.0, accuracy: 1e-12)
        XCTAssertEqual(scoreEns.attributions[0].freeEnergyKcal, -9.0, accuracy: 1e-12)
    }

    /// Kcal vs score paths with different energy rankings yield different populations.
    func testKcalPathDiffersFromScoreWhenValuesDiverge() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(substanceId: "a", deltaSBits: -2.0, dockingScore: -12.0), // best score
            makeResult(substanceId: "b", deltaSBits: -2.0, dockingScore: -6.0)   // worse score
        ]
        // Free energies invert ranking: b is better binder thermodynamically
        let bindingFEs: [Double?] = [-5.0, -9.0]

        let scoreEns = calc.computeEnsemble(results: results)!
        let kcalEns = calc.computeEnsemble(
            results: results,
            bindingFreeEnergies: bindingFEs
        )!

        XCTAssertEqual(scoreEns.energyUnits, .scoreEnsemble)
        XCTAssertEqual(kcalEns.energyUnits, .kcalPerMol)

        XCTAssertEqual(scoreEns.attributions[0].substanceId, "a")
        XCTAssertEqual(kcalEns.attributions[0].substanceId, "b")
        XCTAssertNotEqual(
            scoreEns.ensembleFreeEnergy, kcalEns.ensembleFreeEnergy, accuracy: 1e-6
        )
    }

    // MARK: - Summary Generation

    /// Bilingual summary should contain key thermodynamic values (score-ensemble branch).
    func testSummaryContainsKeyValues() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -3.0, dockingScore: -7.0),
            makeResult(deltaSBits: -1.0, dockingScore: -4.0)
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        XCTAssertTrue(ensemble.summary.en.contains("Partition function ln(Z)"))
        XCTAssertTrue(ensemble.summary.en.contains("score-ensemble") || ensemble.summary.en.contains("score units"))
        XCTAssertTrue(ensemble.summary.en.contains("Shannon"))
        XCTAssertTrue(ensemble.summary.en.contains("3 poses"))

        XCTAssertTrue(ensemble.summary.fr.contains("Fonction de partition ln(Z)"))
        XCTAssertTrue(ensemble.summary.fr.contains("score-ensemble") || ensemble.summary.fr.contains("score units"))

        // Pose attribution summary
        let topPose = ensemble.attributions[0]
        XCTAssertTrue(topPose.summary.en.contains("Pose #1"))
        XCTAssertTrue(topPose.summary.fr.contains("Pose #1"))
    }

    /// Kcal-path summary claims absolute ΔG in kcal/mol.
    func testKcalSummaryContainsKcalUnits() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -3.0, dockingScore: -7.0)
        ]
        let ensemble = calc.computeEnsemble(
            results: results,
            bindingFreeEnergies: [-8.0, -6.0]
        )!

        XCTAssertEqual(ensemble.energyUnits, .kcalPerMol)
        XCTAssertTrue(ensemble.summary.en.contains("kcal/mol"))
        XCTAssertTrue(ensemble.summary.en.contains("ΔG_ens"))
        XCTAssertTrue(ensemble.summary.fr.contains("kcal/mol"))
    }

    // MARK: - Auto-Degeneracy (FOPTICS Analogy)

    /// Auto-degeneracy with identical energies should match manual degeneracy.
    func testAutoDegeneracyMatchesManual() {
        let calc = PartitionFunctionCalculator()
        // 6 poses: 3 at -10.0, 3 at -5.0 (identical within bins)
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -1.0, dockingScore: -5.0),
            makeResult(deltaSBits: -1.0, dockingScore: -5.0),
            makeResult(deltaSBits: -1.0, dockingScore: -5.0),
        ]

        // Auto with wide bin (captures all at same score)
        let auto = calc.computeEnsembleWithAutoDegeneracy(results: results, binWidth: 0.1)!

        // Manual: 2 representatives with degeneracies [3, 3]
        let manual = calc.computeEnsemble(results: [results[0], results[3]], degeneracies: [3.0, 3.0])!

        // Ensemble free energy should match closely
        XCTAssertEqual(auto.ensembleFreeEnergy, manual.ensembleFreeEnergy, accuracy: 1e-6)
        XCTAssertEqual(auto.shannonEntropyBits, manual.shannonEntropyBits, accuracy: 1e-6)
    }

    /// Auto-degeneracy bin width affects grouping.
    func testAutoDegeneracyBinWidth() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -5.0, dockingScore: -9.5),
            makeResult(deltaSBits: -1.0, dockingScore: -5.0),
        ]

        // Narrow bins: each pose is its own bin → 3 effective poses
        let narrow = calc.computeEnsembleWithAutoDegeneracy(results: results, binWidth: 0.1)!
        XCTAssertEqual(narrow.poseCount, 3)

        // Wide bins: first two merge → 2 effective bins
        let wide = calc.computeEnsembleWithAutoDegeneracy(results: results, binWidth: 1.0)!
        XCTAssertEqual(wide.poseCount, 2)
    }

    /// Empty results return nil.
    func testAutoDegeneracyEmpty() {
        let calc = PartitionFunctionCalculator()
        XCTAssertNil(calc.computeEnsembleWithAutoDegeneracy(results: []))
    }

    // MARK: - Incremental Absorb (GetCleft Merge Analogy)

    /// Absorbing results must match full recomputation.
    func testAbsorbMatchesFullRecompute() {
        let calc = PartitionFunctionCalculator()
        let first = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -3.0, dockingScore: -7.0),
        ]
        let second = [
            makeResult(deltaSBits: -1.0, dockingScore: -4.0),
            makeResult(deltaSBits: -4.0, dockingScore: -8.0),
        ]

        let full = calc.computeEnsemble(results: first + second)!
        let initial = calc.computeEnsemble(results: first)!
        let absorbed = calc.absorb(newResults: second, into: initial)!

        XCTAssertEqual(absorbed.ensembleFreeEnergy, full.ensembleFreeEnergy, accuracy: 1e-6)
        XCTAssertEqual(absorbed.shannonEntropyBits, full.shannonEntropyBits, accuracy: 1e-6)
        XCTAssertEqual(absorbed.poseCount, full.poseCount)
    }

    /// Absorbing with a new lower-energy pose correctly rescales.
    func testAbsorbWithNewMinimum() {
        let calc = PartitionFunctionCalculator()
        let initial = calc.computeEnsemble(results: [
            makeResult(deltaSBits: -3.0, dockingScore: -5.0),
        ])!

        // New pose has much lower energy → should become dominant
        let absorbed = calc.absorb(
            newResults: [makeResult(deltaSBits: -5.0, dockingScore: -15.0)],
            into: initial
        )!

        // The new pose (dockingScore=-15) should be rank 1
        XCTAssertEqual(absorbed.attributions[0].dockingScore, -15.0)
        XCTAssertGreaterThan(absorbed.attributions[0].boltzmannWeight, 0.99)
    }

    /// Absorbing empty results returns the existing ensemble unchanged.
    func testAbsorbEmptyReturnsExisting() {
        let calc = PartitionFunctionCalculator()
        let initial = calc.computeEnsemble(results: [
            makeResult(deltaSBits: -3.0, dockingScore: -8.0),
        ])!

        let result = calc.absorb(newResults: [], into: initial)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.ensembleFreeEnergy, initial.ensembleFreeEnergy, accuracy: 1e-10)
    }

    // MARK: - Binding Mode Clustering (GetCleft Connected-Component Analogy)

    /// Clustered energies produce a single binding mode.
    func testSingleBindingMode() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -4.5, dockingScore: -9.8),
            makeResult(deltaSBits: -4.0, dockingScore: -9.5),
        ]

        let ensemble = calc.computeEnsemble(results: results)!
        let modes = ensemble.bindingModes(energyRadius: 1.0)

        // All poses within 0.5 kcal/mol → single binding mode
        XCTAssertEqual(modes.count, 1)
        XCTAssertEqual(modes[0].count, 3)
    }

    /// Bimodal energy distribution produces two binding modes.
    func testMultipleBindingModes() {
        let calc = PartitionFunctionCalculator()
        // Energies close enough that all poses are thermodynamically relevant (essential),
        // but with a clear gap between two clusters when using energyRadius=0.5.
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -8.0),
            makeResult(deltaSBits: -4.5, dockingScore: -7.9),
            makeResult(deltaSBits: -1.0, dockingScore: -7.0),
            makeResult(deltaSBits: -0.5, dockingScore: -6.9),
        ]

        let ensemble = calc.computeEnsemble(results: results)!
        let modes = ensemble.bindingModes(energyRadius: 0.5)

        // Two clusters: {-8.0, -7.9} and {-7.0, -6.9}
        XCTAssertEqual(modes.count, 2)

        // Both modes should be essential
        guard modes.count == 2 else { return }
        XCTAssertEqual(modes[0].count + modes[1].count, ensemble.attributions.filter(\.isEssential).count)
    }

    // MARK: - Landscape Fingerprint (Cube Grid Analogy)

    /// All poses land in valid cells, total weight sums to 1.0.
    func testFingerprintWeightSum() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0),
            makeResult(deltaSBits: -3.0, dockingScore: -7.0),
            makeResult(deltaSBits: -1.0, dockingScore: -4.0),
        ]

        let ensemble = calc.computeEnsemble(results: results)!
        let fp = ensemble.landscapeFingerprint()

        // Total weight across all cells = 1.0
        let totalWeight = fp.cells.reduce(0.0) { $0 + $1.totalWeight }
        XCTAssertEqual(totalWeight, 1.0, accuracy: 1e-10)

        // Total pose count across cells = 3
        let totalPoses = fp.cells.reduce(0) { $0 + $1.poseCount }
        XCTAssertEqual(totalPoses, 3)
    }

    /// Fingerprint grid coverage: each cell has valid indices.
    func testFingerprintGridCoverage() {
        let calc = PartitionFunctionCalculator()
        let results = (0..<10).map { i in
            makeResult(
                deltaSBits: -Double(i + 1) * 0.5,
                dockingScore: -Double(i + 1) * 1.5
            )
        }

        let ensemble = calc.computeEnsemble(results: results)!
        let fp = ensemble.landscapeFingerprint(energyBinWidth: 2.0, entropyBinWidth: 1.0)

        // All bins should have non-negative indices
        for cell in fp.cells {
            XCTAssertGreaterThanOrEqual(cell.energyBin, 0)
            XCTAssertGreaterThanOrEqual(cell.entropyBin, 0)
            XCTAssertGreaterThan(cell.poseCount, 0)
            XCTAssertGreaterThan(cell.totalWeight, 0)
        }

        XCTAssertGreaterThan(fp.occupiedCellCount, 0)
    }

    // MARK: - Edge Case Tests (Bug Fix Verification)

    /// Single result auto-degeneracy produces 1 bin with degeneracy 1.
    func testAutoDegeneracySingleResult() {
        let calc = PartitionFunctionCalculator()
        let results = [makeResult(deltaSBits: -3.0, dockingScore: -8.0)]
        let auto = calc.computeEnsembleWithAutoDegeneracy(results: results, binWidth: 1.0)!
        XCTAssertEqual(auto.poseCount, 1)
        XCTAssertEqual(auto.attributions.count, 1)
        XCTAssertEqual(auto.attributions[0].boltzmannWeight, 1.0, accuracy: 1e-10)
    }

    /// Absorb with mismatched degeneracy count returns nil.
    func testAbsorbDegeneracyCountMismatch() {
        let calc = PartitionFunctionCalculator()
        let initial = calc.computeEnsemble(results: [
            makeResult(deltaSBits: -3.0, dockingScore: -8.0),
        ])!

        let result = calc.absorb(
            newResults: [makeResult(deltaSBits: -2.0, dockingScore: -6.0)],
            into: initial,
            newDegeneracies: [1.0, 2.0]  // 2 degeneracies for 1 result
        )
        XCTAssertNil(result)
    }

    /// Absorb preserves full FlexAIDdSResult metadata (bondResults, totalDeltaSConfig).
    func testAbsorbPreservesMetadata() {
        let calc = PartitionFunctionCalculator()
        let first = [
            makeResult(deltaSBits: -5.0, dockingScore: -10.0, bondCount: 4),
            makeResult(deltaSBits: -3.0, dockingScore: -7.0, bondCount: 3),
        ]
        let second = [
            makeResult(deltaSBits: -1.0, dockingScore: -4.0, bondCount: 2),
        ]

        let initial = calc.computeEnsemble(results: first)!
        let absorbed = calc.absorb(newResults: second, into: initial)!

        // Verify old poses retain their original deltaSConfigBits (not zeroed out)
        let sortedByIndex = absorbed.attributions.sorted { $0.poseIndex < $1.poseIndex }
        // First two poses came from 'first' array with deltaSBits -5.0 and -3.0
        XCTAssertEqual(sortedByIndex[0].deltaSConfigBits, -5.0, accuracy: 1e-10)
        XCTAssertEqual(sortedByIndex[1].deltaSConfigBits, -3.0, accuracy: 1e-10)
        // Third pose from 'second' array with deltaSBits -1.0
        XCTAssertEqual(sortedByIndex[2].deltaSConfigBits, -1.0, accuracy: 1e-10)
    }

    /// Single essential pose produces exactly 1 binding mode with 1 pose.
    func testBindingModesSinglePose() {
        let calc = PartitionFunctionCalculator()
        let results = [makeResult(deltaSBits: -3.0, dockingScore: -8.0)]
        let ensemble = calc.computeEnsemble(results: results)!
        let modes = ensemble.bindingModes()
        XCTAssertEqual(modes.count, 1)
        XCTAssertEqual(modes[0].count, 1)
    }

    /// Single pose fingerprint produces 1 cell with weight 1.0.
    func testFingerprintSinglePose() {
        let calc = PartitionFunctionCalculator()
        let results = [makeResult(deltaSBits: -3.0, dockingScore: -8.0)]
        let ensemble = calc.computeEnsemble(results: results)!
        let fp = ensemble.landscapeFingerprint()
        XCTAssertEqual(fp.cells.count, 1)
        XCTAssertEqual(fp.cells[0].totalWeight, 1.0, accuracy: 1e-10)
        XCTAssertEqual(fp.cells[0].poseCount, 1)
    }

    /// Zero or negative bin width returns empty fingerprint.
    func testFingerprintInvalidBinWidth() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -3.0, dockingScore: -8.0),
            makeResult(deltaSBits: -1.0, dockingScore: -5.0),
        ]
        let ensemble = calc.computeEnsemble(results: results)!

        let fpZero = ensemble.landscapeFingerprint(energyBinWidth: 0.0)
        XCTAssertTrue(fpZero.cells.isEmpty)

        let fpNeg = ensemble.landscapeFingerprint(entropyBinWidth: -1.0)
        XCTAssertTrue(fpNeg.cells.isEmpty)
    }

    /// Default auto-degeneracy bin width equals kT at 298K.
    func testDefaultAutoDegeneracyBinWidth() {
        let calc = PartitionFunctionCalculator(temperatureK: 298.15)
        // kT = 1.987e-3 * 298.15 ≈ 0.5924 kcal/mol
        let expectedKT = 1.987e-3 * 298.15

        // Two poses separated by less than kT should merge into one bin
        let close = [
            makeResult(deltaSBits: -3.0, dockingScore: -10.0),
            makeResult(deltaSBits: -3.0, dockingScore: -10.0 + expectedKT * 0.5),
        ]
        let closeResult = calc.computeEnsembleWithAutoDegeneracy(results: close)!
        XCTAssertEqual(closeResult.poseCount, 1)  // merged into 1 bin

        // Two poses separated by more than kT should stay separate
        let far = [
            makeResult(deltaSBits: -3.0, dockingScore: -10.0),
            makeResult(deltaSBits: -3.0, dockingScore: -10.0 + expectedKT * 1.5),
        ]
        let farResult = calc.computeEnsembleWithAutoDegeneracy(results: far)!
        XCTAssertEqual(farResult.poseCount, 2)  // separate bins
    }
}
