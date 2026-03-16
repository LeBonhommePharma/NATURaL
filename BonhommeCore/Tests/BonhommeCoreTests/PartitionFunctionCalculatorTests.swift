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
        dockingScore: Double = -8.5
    ) -> DockingPose {
        DockingPose(
            boundConformation: conformation,
            receptorId: receptorId,
            dockingScore: dockingScore
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
            makeResult(deltaSBits: -Double(i + 1) * 0.5)
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
            makeResult(deltaSBits: -1.0),
            makeResult(deltaSBits: -3.0),
            makeResult(deltaSBits: -5.0)
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        // Convert each ΔS to ΔG for comparison
        let analyzer = FlexAIDdSAnalyzer()
        let minDeltaG = results.map {
            analyzer.entropyPenaltyKcal(deltaSBits: $0.totalDeltaSConfig)
        }.min()!

        // Ensemble ΔG must be ≤ best single-state ΔG
        XCTAssertLessThanOrEqual(ensemble.ensembleFreeEnergy, minDeltaG + 1e-10)
    }

    // MARK: - Shannon Entropy Bounds

    /// H must be in [0, log₂(N)] for any ensemble.
    func testShannonEntropyBounds() {
        let calc = PartitionFunctionCalculator()
        let n = 8
        let results = (0..<n).map { i in
            makeResult(deltaSBits: -Double(i + 1) * 0.7)
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
        // One very favorable pose, others much worse
        var results = [makeResult(deltaSBits: -10.0)]  // dominant
        results += (0..<5).map { _ in makeResult(deltaSBits: -0.1) }  // negligible

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
    func testPoseRanking() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(substanceId: "weak", deltaSBits: -1.0),
            makeResult(substanceId: "strong", deltaSBits: -5.0),
            makeResult(substanceId: "medium", deltaSBits: -3.0)
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        // Rank 1 should have the highest Boltzmann weight
        XCTAssertEqual(ensemble.attributions[0].rank, 1)
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
            makeResult(deltaSBits: -5.0),
            makeResult(deltaSBits: -1.0)
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
        // One dominant + many minor poses
        var results = [makeResult(deltaSBits: -8.0)]
        results += (0..<9).map { _ in makeResult(deltaSBits: -1.0) }

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
            makeResult(deltaSBits: -5.0),
            makeResult(deltaSBits: -1.0)
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

        // Most constrained pose (spread=10) should have largest |ΔS| → largest ΔG
        // → highest Boltzmann weight
        XCTAssertEqual(ens.attributions[0].rank, 1)
        XCTAssertTrue(ens.attributions[0].bindingDetected)
    }

    // MARK: - Parallel Computation Consistency

    /// Parallel and sequential computation should produce the same result.
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

        // All weights should sum to 1.0 in both
        let seqTotal = seq.attributions.reduce(0.0) { $0 + $1.boltzmannWeight }
        let parTotal = par.attributions.reduce(0.0) { $0 + $1.boltzmannWeight }
        XCTAssertEqual(seqTotal, 1.0, accuracy: 1e-10)
        XCTAssertEqual(parTotal, 1.0, accuracy: 1e-10)
    }

    // MARK: - Summary Generation

    /// Bilingual summary should contain key thermodynamic values.
    func testSummaryContainsKeyValues() {
        let calc = PartitionFunctionCalculator()
        let results = [
            makeResult(deltaSBits: -5.0),
            makeResult(deltaSBits: -3.0),
            makeResult(deltaSBits: -1.0)
        ]

        let ensemble = calc.computeEnsemble(results: results)!

        XCTAssertTrue(ensemble.summary.en.contains("Partition function"))
        XCTAssertTrue(ensemble.summary.en.contains("kcal/mol"))
        XCTAssertTrue(ensemble.summary.en.contains("Shannon"))
        XCTAssertTrue(ensemble.summary.en.contains("3 poses"))

        XCTAssertTrue(ensemble.summary.fr.contains("Fonction de partition"))
        XCTAssertTrue(ensemble.summary.fr.contains("kcal/mol"))

        // Pose attribution summary
        let topPose = ensemble.attributions[0]
        XCTAssertTrue(topPose.summary.en.contains("Pose #1"))
        XCTAssertTrue(topPose.summary.fr.contains("Pose #1"))
    }
}
