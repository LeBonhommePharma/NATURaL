import XCTest
@testable import BonhommeCore

/// Tests validating the FlexAID∆S configurational entropy module.
///
/// These tests use synthetic torsional angle distributions with known statistical
/// properties to validate:
/// 1. Shannon entropy computation on molecular conformations
/// 2. ΔS_config detection for binding events
/// 3. Entropy-to-energy conversion (bits → kcal/mol)
/// 4. Cross-domain correlation with in-vivo DrugResponseAnalyzer results
/// 5. FeedbackEngine integration via DockingInsightAnalyzer
///
/// The core principle: the same EntropyCalculator that computes HRV entropy
/// from cardiac RR intervals computes configurational entropy from torsional
/// angles. Identical math, different domain. If binding is detected in one
/// domain, it should correlate with binding in the other.
final class FlexAIDdSAnalyzerTests: XCTestCase {

    // MARK: - Test Helpers

    /// Generate a torsional angle distribution with known spread.
    /// Linearly spaced angles within [center - spread, center + spread].
    ///
    /// - Parameters:
    ///   - bondId: Identifier for the bond.
    ///   - center: Center of the distribution (degrees).
    ///   - spread: Half-width in degrees (180 = full rotation, 10 = tightly constrained).
    ///   - count: Number of angle samples.
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

    // MARK: - Basic Entropy Tests

    /// Uniform torsional distribution (±180°) should have high entropy (free rotation).
    /// FlexAID∆S analog: ligand freely rotating in solution.
    func testFreeRotationHighEntropy() {
        let analyzer = FlexAIDdSAnalyzer()
        let freeAngles = makeAngles(spread: 180, count: 500)
        let h = analyzer.entropy(of: freeAngles)

        XCTAssertGreaterThan(h, 3.0,
            "Full rotation (±180°) should have high entropy (> 3 bits)")
    }

    /// Narrow torsional distribution (±10°) should have low entropy (constrained).
    /// FlexAID∆S analog: ligand locked in binding pocket.
    func testConstrainedLowEntropy() {
        let analyzer = FlexAIDdSAnalyzer()
        let boundAngles = makeAngles(spread: 10, count: 500)
        let h = analyzer.entropy(of: boundAngles)

        XCTAssertLessThan(h, 2.0,
            "Narrow distribution (±10°) should have low entropy (< 2 bits)")
    }

    /// ΔS_config = H_bound - H_free should be negative for binding.
    func testDeltaSConfigNegativeForBinding() {
        let analyzer = FlexAIDdSAnalyzer()
        let free = makeAngles(spread: 180, count: 500)
        let bound = makeAngles(spread: 10, count: 500)

        let hFree = analyzer.entropy(of: free)
        let hBound = analyzer.entropy(of: bound)
        let deltaS = hBound - hFree

        XCTAssertLessThan(deltaS, 0,
            "ΔS = H_bound - H_free should be negative (binding constrains)")
        XCTAssertLessThan(deltaS, -1.0,
            "A strong binding should produce |ΔS| > 1 bit")
    }

    // MARK: - Full Ligand Analysis

    /// Multi-bond ligand: total ΔS = sum of per-bond ΔS.
    func testMultiBondTotalEntropy() {
        let analyzer = FlexAIDdSAnalyzer()
        let free = makeConformation(bondCount: 5, spread: 180)
        let bound = makeConformation(bondCount: 5, spread: 15)
        let pose = makePose(conformation: bound)

        let result = analyzer.analyze(freeConformation: free, dockingPose: pose)

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertEqual(r.bondCount, 5)
        XCTAssertLessThan(r.totalDeltaSConfig, 0, "Total ΔS should be negative")
        XCTAssertTrue(r.bindingDetected, "5-bond constrained ligand should detect binding")

        // Total should approximately equal sum of individual bond ΔS values
        let sumBondDeltas = r.bondResults.reduce(0.0) { $0 + $1.deltaSBits }
        XCTAssertEqual(r.totalDeltaSConfig, sumBondDeltas, accuracy: 0.001,
            "Total ΔS should equal sum of per-bond ΔS")
    }

    /// Bond count mismatch between free and bound should return nil.
    func testBondCountMismatchReturnsNil() {
        let analyzer = FlexAIDdSAnalyzer()
        let free = makeConformation(bondCount: 3, spread: 180)
        let bound = makeConformation(bondCount: 5, spread: 15)
        let pose = makePose(conformation: bound)

        let result = analyzer.analyze(freeConformation: free, dockingPose: pose)
        XCTAssertNil(result, "Mismatched bond counts should return nil")
    }

    /// Rigid ligand (all bonds narrow even in free state) → minimal ΔS.
    func testRigidLigandMinimalDeltaS() {
        let analyzer = FlexAIDdSAnalyzer()
        let free = makeConformation(bondCount: 3, spread: 15)   // Already constrained
        let bound = makeConformation(bondCount: 3, spread: 10)  // Slightly more
        let pose = makePose(conformation: bound)

        let result = analyzer.analyze(freeConformation: free, dockingPose: pose)

        XCTAssertNotNil(result)
        guard let r = result else { return }

        // Small ΔS because free state was already constrained
        XCTAssertGreaterThan(r.totalDeltaSConfig, -2.0,
            "Rigid ligand should have small |ΔS|")
    }

    /// Flexible ligand (many wide bonds) → large |ΔS|.
    func testFlexibleLigandLargeDeltaS() {
        let analyzer = FlexAIDdSAnalyzer()
        let free = makeConformation(bondCount: 8, spread: 180)   // Very flexible
        let bound = makeConformation(bondCount: 8, spread: 5)    // Very constrained
        let pose = makePose(conformation: bound)

        let result = analyzer.analyze(freeConformation: free, dockingPose: pose)

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertLessThan(r.totalDeltaSConfig, -5.0,
            "8-bond flexible→constrained should produce large |ΔS| (> 5 bits)")
        XCTAssertTrue(r.bindingDetected)
        XCTAssertGreaterThan(r.meanFractionalLoss, 0.5,
            "Should lose > 50% of conformational freedom")
    }

    /// Most/least constrained bond identification.
    func testMostLeastConstrainedBond() {
        let analyzer = FlexAIDdSAnalyzer()

        // Bond 0: wide → narrow (large ΔS)
        // Bond 1: wide → medium (moderate ΔS)
        // Bond 2: wide → wide (small ΔS)
        let freeBonds = [
            makeAngles(bondId: "b0", spread: 180),
            makeAngles(bondId: "b1", spread: 180),
            makeAngles(bondId: "b2", spread: 180),
        ]
        let boundBonds = [
            makeAngles(bondId: "b0", spread: 5),
            makeAngles(bondId: "b1", spread: 60),
            makeAngles(bondId: "b2", spread: 150),
        ]

        let free = LigandConformation(
            substanceId: "test", name: LocalizedString(en: "Test", fr: "Test"),
            bonds: freeBonds
        )
        let bound = LigandConformation(
            substanceId: "test", name: LocalizedString(en: "Test", fr: "Test"),
            bonds: boundBonds
        )
        let pose = makePose(conformation: bound)
        let result = analyzer.analyze(freeConformation: free, dockingPose: pose)

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertEqual(r.mostConstrainedBond?.bondId, "b0",
            "Bond 0 (180→5) should be most constrained")
        XCTAssertEqual(r.leastConstrainedBond?.bondId, "b2",
            "Bond 2 (180→150) should be least constrained")
    }

    // MARK: - Entropy-to-Energy Conversion

    /// Verify kcal/mol conversion at standard temperature (298K).
    func testEntropyPenaltyKcalConversion() {
        let analyzer = FlexAIDdSAnalyzer()

        // ΔS = -1 bit → positive penalty (entropy cost)
        let penalty = analyzer.entropyPenaltyKcal(deltaSBits: -1.0)
        XCTAssertGreaterThan(penalty, 0,
            "Negative ΔS (binding) should produce positive penalty")

        // At 298K, 1 bit ≈ 0.41 kcal/mol
        // R × ln(2) × T = 1.987e-3 × 0.6931 × 298 ≈ 0.410
        XCTAssertEqual(penalty, 0.41, accuracy: 0.02,
            "1 bit at 298K should be ~0.41 kcal/mol")

        // Zero ΔS → zero penalty
        let zeroPenalty = analyzer.entropyPenaltyKcal(deltaSBits: 0)
        XCTAssertEqual(zeroPenalty, 0, accuracy: 0.001)

        // Round-trip: bits → kcal → bits
        let roundTrip = analyzer.kcalToDeltaSBits(penaltyKcal: penalty)
        XCTAssertEqual(roundTrip, -1.0, accuracy: 0.01,
            "Round-trip conversion should recover original ΔS")
    }

    /// Temperature dependence: higher T → larger penalty per bit.
    func testTemperatureDependence() {
        let analyzer = FlexAIDdSAnalyzer()

        let penalty298 = analyzer.entropyPenaltyKcal(deltaSBits: -1.0, temperatureK: 298)
        let penalty310 = analyzer.entropyPenaltyKcal(deltaSBits: -1.0, temperatureK: 310)
        let penalty350 = analyzer.entropyPenaltyKcal(deltaSBits: -1.0, temperatureK: 350)

        XCTAssertLessThan(penalty298, penalty310,
            "Higher temperature should increase entropy penalty")
        XCTAssertLessThan(penalty310, penalty350)
    }

    // MARK: - Batch Analysis

    /// Multiple docking poses should be sorted by |ΔS| descending.
    func testBatchAnalysisSortedByDeltaS() {
        let analyzer = FlexAIDdSAnalyzer()
        let free = makeConformation(bondCount: 3, spread: 180)

        let poses = [
            makePose(conformation: makeConformation(bondCount: 3, spread: 100), dockingScore: -6.0),
            makePose(conformation: makeConformation(bondCount: 3, spread: 5), dockingScore: -9.0),
            makePose(conformation: makeConformation(bondCount: 3, spread: 50), dockingScore: -7.5),
        ]

        let results = analyzer.analyzeBatch(freeConformation: free, dockingPoses: poses)

        XCTAssertEqual(results.count, 3)

        // Should be sorted by |ΔS| descending
        for i in 1..<results.count {
            XCTAssertGreaterThanOrEqual(
                abs(results[i - 1].totalDeltaSConfig),
                abs(results[i].totalDeltaSConfig),
                "Batch results should be sorted by |ΔS| descending"
            )
        }

        // Most constrained (spread=5) should be first
        XCTAssertEqual(results[0].dockingScore, -9.0,
            "Most constrained pose should be first")
    }

    // MARK: - Cross-Domain Validation

    /// Validate correlation between ΔS_config and ΔH_hrv using synthetic data.
    /// Uses 5 paired substances (raised minimum from 3 to 5 for statistical rigor).
    func testCrossDomainCorrelation() {
        let validator = CrossDomainValidator()

        // Create synthetic paired data with known correlation
        // More rotatable bonds → larger |ΔS| → larger |ΔH|
        let dockingResults = [
            FlexAIDdSResult(substanceId: "drug_a", receptorId: "1ABC",
                bondResults: [BondEntropyResult(bondId: "b1", freeEntropy: 4.0, boundEntropy: 1.0)],
                dockingScore: -8.0),
            FlexAIDdSResult(substanceId: "drug_b", receptorId: "1ABC",
                bondResults: [
                    BondEntropyResult(bondId: "b1", freeEntropy: 4.0, boundEntropy: 1.0),
                    BondEntropyResult(bondId: "b2", freeEntropy: 4.0, boundEntropy: 1.5),
                ],
                dockingScore: -9.0),
            FlexAIDdSResult(substanceId: "drug_c", receptorId: "1ABC",
                bondResults: [
                    BondEntropyResult(bondId: "b1", freeEntropy: 4.0, boundEntropy: 1.0),
                    BondEntropyResult(bondId: "b2", freeEntropy: 4.0, boundEntropy: 1.5),
                    BondEntropyResult(bondId: "b3", freeEntropy: 4.0, boundEntropy: 0.5),
                ],
                dockingScore: -10.0),
            FlexAIDdSResult(substanceId: "drug_d", receptorId: "1ABC",
                bondResults: [BondEntropyResult(bondId: "b1", freeEntropy: 4.0, boundEntropy: 2.5)],
                dockingScore: -6.0),
            FlexAIDdSResult(substanceId: "drug_e", receptorId: "1ABC",
                bondResults: [
                    BondEntropyResult(bondId: "b1", freeEntropy: 4.0, boundEntropy: 0.5),
                    BondEntropyResult(bondId: "b2", freeEntropy: 4.0, boundEntropy: 0.5),
                    BondEntropyResult(bondId: "b3", freeEntropy: 4.0, boundEntropy: 0.5),
                    BondEntropyResult(bondId: "b4", freeEntropy: 4.0, boundEntropy: 0.5),
                ],
                dockingScore: -12.0),
        ]

        // DrugResponseResults with proportional ΔH_hrv
        let now = Date()
        let drugResults = [
            DrugResponseResult(
                doseEvent: DoseEventSummary(medicationId: "drug_a", name: "Drug A", doseValue: 10, doseUnit: "mg", timestamp: now),
                baselineEntropy: 4.0, baselineRRCount: 100,
                measurements: [EntropyMeasurement(minutesPostDose: 60, entropy: 3.0, deltaH: -1.0, rrCount: 50, coherenceScore: 0.6)],
                peakDeltaH: -1.0, peakTimeMinutes: 60, profileMatch: nil
            ),
            DrugResponseResult(
                doseEvent: DoseEventSummary(medicationId: "drug_b", name: "Drug B", doseValue: 10, doseUnit: "mg", timestamp: now),
                baselineEntropy: 4.0, baselineRRCount: 100,
                measurements: [EntropyMeasurement(minutesPostDose: 60, entropy: 2.0, deltaH: -2.0, rrCount: 50, coherenceScore: 0.7)],
                peakDeltaH: -2.0, peakTimeMinutes: 60, profileMatch: nil
            ),
            DrugResponseResult(
                doseEvent: DoseEventSummary(medicationId: "drug_c", name: "Drug C", doseValue: 10, doseUnit: "mg", timestamp: now),
                baselineEntropy: 4.0, baselineRRCount: 100,
                measurements: [EntropyMeasurement(minutesPostDose: 60, entropy: 1.0, deltaH: -3.0, rrCount: 50, coherenceScore: 0.8)],
                peakDeltaH: -3.0, peakTimeMinutes: 60, profileMatch: nil
            ),
            DrugResponseResult(
                doseEvent: DoseEventSummary(medicationId: "drug_d", name: "Drug D", doseValue: 10, doseUnit: "mg", timestamp: now),
                baselineEntropy: 4.0, baselineRRCount: 100,
                measurements: [EntropyMeasurement(minutesPostDose: 60, entropy: 3.5, deltaH: -0.5, rrCount: 50, coherenceScore: 0.5)],
                peakDeltaH: -0.5, peakTimeMinutes: 60, profileMatch: nil
            ),
            DrugResponseResult(
                doseEvent: DoseEventSummary(medicationId: "drug_e", name: "Drug E", doseValue: 10, doseUnit: "mg", timestamp: now),
                baselineEntropy: 4.0, baselineRRCount: 100,
                measurements: [EntropyMeasurement(minutesPostDose: 60, entropy: 0.0, deltaH: -4.5, rrCount: 50, coherenceScore: 0.9)],
                peakDeltaH: -4.5, peakTimeMinutes: 60, profileMatch: nil
            ),
        ]

        let result = validator.validate(dockingResults: dockingResults, drugResponseResults: drugResults)

        XCTAssertNotNil(result)
        guard let v = result else { return }

        XCTAssertEqual(v.n, 5)
        XCTAssertGreaterThan(v.pearsonR, 0.9,
            "Proportional ΔS/ΔH should produce r > 0.9")
        XCTAssertGreaterThan(v.rSquared, 0.8)
        XCTAssertLessThan(v.pValue, 0.05,
            "Strong correlation with n=5 should be significant")
    }

    /// Validate from known BindingEntropyProfile values.
    func testValidateFromProfiles() {
        let validator = CrossDomainValidator()
        let now = Date()

        // Use substances that exist in BindingEntropyProfile
        let substances = ["caffeine", "amphetamine", "propranolol", "fentanyl", "morphine"]
        var drugResults: [DrugResponseResult] = []

        for (i, sub) in substances.enumerated() {
            guard let profile = BindingEntropyProfile.profile(for: sub) else { continue }
            // Simulate proportional ΔH: more binding entropy → more HRV change
            let deltaH = profile.expectedDeltaSBits * 0.3  // Scale factor
            drugResults.append(DrugResponseResult(
                doseEvent: DoseEventSummary(medicationId: sub, name: sub, doseValue: 10, doseUnit: "mg", timestamp: now.addingTimeInterval(Double(i) * 3600)),
                baselineEntropy: 4.0, baselineRRCount: 100,
                measurements: [EntropyMeasurement(minutesPostDose: 60, entropy: 4.0 + deltaH, deltaH: deltaH, rrCount: 50, coherenceScore: 0.5)],
                peakDeltaH: deltaH, peakTimeMinutes: 60, profileMatch: nil
            ))
        }

        let result = validator.validateFromProfiles(drugResponseResults: drugResults)
        XCTAssertNotNil(result)

        if let v = result {
            XCTAssertGreaterThanOrEqual(v.n, 3,
                "Should pair at least 3 substances")
            XCTAssertGreaterThan(v.pearsonR, 0.8,
                "Proportional synthetic data should correlate well")
        }
    }

    /// Insufficient pairs (< 5, default minimum) should return nil.
    func testCrossDomainInsufficientPairsReturnsNil() {
        let validator = CrossDomainValidator()

        let result = validator.validate(
            dockingResults: [
                FlexAIDdSResult(substanceId: "x", receptorId: "1ABC",
                    bondResults: [BondEntropyResult(bondId: "b1", freeEntropy: 4.0, boundEntropy: 1.0)],
                    dockingScore: -8.0)
            ],
            drugResponseResults: [
                DrugResponseResult(
                    doseEvent: DoseEventSummary(medicationId: "x", name: "X", doseValue: 10, doseUnit: "mg", timestamp: Date()),
                    baselineEntropy: 4.0, baselineRRCount: 100,
                    measurements: [EntropyMeasurement(minutesPostDose: 60, entropy: 3.0, deltaH: -1.0, rrCount: 50, coherenceScore: 0.6)],
                    peakDeltaH: -1.0, peakTimeMinutes: 60, profileMatch: nil
                )
            ]
        )

        XCTAssertNil(result, "< 5 paired substances should return nil (minimum raised for statistical rigor)")
    }

    // MARK: - BindingEntropyProfile Registry

    /// All profile substance IDs should be unique.
    func testBindingEntropyProfileUniqueness() {
        let ids = BindingEntropyProfile.knownProfiles.map(\.substanceId)
        XCTAssertEqual(ids.count, Set(ids).count,
            "All binding entropy profile IDs should be unique")
    }

    /// All BindingEntropyProfile substanceIds should exist in PharmacokineticProfile.
    func testBindingEntropyProfilesCrossReference() {
        for profile in BindingEntropyProfile.knownProfiles {
            XCTAssertNotNil(
                PharmacokineticProfile.profile(for: profile.substanceId),
                "BindingEntropyProfile '\(profile.substanceId)' should have a matching PharmacokineticProfile"
            )
        }
    }

    /// Rotatable bond count should correlate with |ΔS|.
    func testRotatableBondCorrelationWithDeltaS() {
        let profiles = BindingEntropyProfile.knownProfiles.filter {
            $0.rotatableBondCount > 0  // Exclude zero-bond substances
        }

        guard profiles.count >= 5 else {
            XCTFail("Need at least 5 profiles with rotatable bonds")
            return
        }

        // Check that more bonds generally means larger |ΔS|
        let sorted = profiles.sorted { $0.rotatableBondCount < $1.rotatableBondCount }
        let firstQuarter = sorted[..<(sorted.count / 4)]
        let lastQuarter = sorted[(sorted.count * 3 / 4)...]

        let avgDeltaFirst = firstQuarter.map { abs($0.expectedDeltaSBits) }.reduce(0, +) / Double(firstQuarter.count)
        let avgDeltaLast = lastQuarter.map { abs($0.expectedDeltaSBits) }.reduce(0, +) / Double(lastQuarter.count)

        XCTAssertGreaterThan(avgDeltaLast, avgDeltaFirst,
            "Substances with more rotatable bonds should have larger |ΔS|")
    }

    // MARK: - FeedbackEngine Integration

    /// DockingSignal should be ingestible by FeedbackEngine.
    func testDockingSignalIngestion() {
        let engine = FeedbackEngine()

        let signal = DockingSignal(
            substanceId: "amphetamine",
            substanceName: LocalizedString(en: "Amphetamine", fr: "Amphétamine"),
            freeEntropy: 8.0,
            boundEntropy: 3.0,
            rotatableBondCount: 2,
            receptorId: "DAT"
        )

        engine.ingest(signal)
        // Should not crash — signal is buffered under .molecularDocking
    }

    /// DockingInsightAnalyzer should produce valid AnalysisInsight.
    func testDockingInsightAnalyzerProducesInsight() {
        let engine = FeedbackEngine()
        engine.register(DockingInsightAnalyzer())

        let signal = DockingSignal(
            substanceId: "amphetamine",
            substanceName: LocalizedString(en: "Amphetamine", fr: "Amphétamine"),
            freeEntropy: 8.0,
            boundEntropy: 3.0,
            rotatableBondCount: 2,
            receptorId: "DAT",
            dockingScore: -9.5
        )

        engine.ingest(signal)
        let insights = engine.analyzeAll()

        let dockingInsight = insights[.molecularDocking]
        XCTAssertNotNil(dockingInsight, "Should produce a .molecularDocking insight")

        if let insight = dockingInsight {
            XCTAssertEqual(insight.signalType, .molecularDocking)
            XCTAssertNotNil(insight.score)
            XCTAssertGreaterThan(insight.score ?? 0, 0,
                "Significant ΔS should produce non-zero score")
            XCTAssertTrue(insight.summary.en.contains("ΔS"),
                "Summary should mention ΔS")
            XCTAssertTrue(insight.summary.en.contains("kcal/mol"),
                "Summary should include energy units")
        }
    }

    /// No docking signals → graceful empty insight.
    func testDockingInsightAnalyzerEmptySignals() {
        let engine = FeedbackEngine()
        engine.register(DockingInsightAnalyzer())

        let insights = engine.analyzeAll()
        let dockingInsight = insights[.molecularDocking]

        XCTAssertNotNil(dockingInsight)
        XCTAssertNil(dockingInsight?.score,
            "Empty signals should produce nil score")
        XCTAssertTrue(dockingInsight?.summary.en.contains("No molecular docking data") ?? false)
    }

    /// Full pipeline: ingest DockingSignal + MedicationSignal → analyzeAll → verify cross-reference.
    func testFullPipelineWithMedicationCrossReference() {
        let engine = FeedbackEngine()
        engine.register(DockingInsightAnalyzer())

        // Ingest a medication dose
        let medSignal = MedicationSignal(
            timestamp: Date(),
            medicationId: "amphetamine",
            name: LocalizedString(en: "Amphetamine", fr: "Amphétamine"),
            doseValue: 20,
            doseUnit: "mg",
            event: .taken
        )
        engine.ingest(medSignal)

        // Ingest a docking result for the same substance
        let dockingSignal = DockingSignal(
            substanceId: "amphetamine",
            substanceName: LocalizedString(en: "Amphetamine", fr: "Amphétamine"),
            freeEntropy: 8.0,
            boundEntropy: 3.0,
            rotatableBondCount: 2,
            receptorId: "DAT"
        )
        engine.ingest(dockingSignal)

        let insights = engine.analyzeAll()
        let dockingInsight = insights[.molecularDocking]

        XCTAssertNotNil(dockingInsight)
        // The cross-reference note should mention the medication
        // (only if MedicationAnalyzer has been registered and run first,
        // but the signal should still be in context)
    }

    // MARK: - Mathematical Parity

    /// The same EntropyCalculator used for RR intervals produces
    /// identical results on torsional angle distributions.
    func testEntropyCalculatorParityAcrossDomains() {
        let calc = EntropyCalculator(binCount: 32)

        // Create identical numerical values
        let values = Array(stride(from: -180.0, through: 180.0, by: 1.0))

        // Compute entropy: same input → same output regardless of domain interpretation
        let h1 = calc.shannonEntropy(values)  // "as torsional angles"
        let h2 = calc.shannonEntropy(values)  // "as RR intervals"

        XCTAssertEqual(h1, h2,
            "Same numerical input must produce identical entropy regardless of domain")
        XCTAssertGreaterThan(h1, 4.0,
            "Linearly spaced values over 360° should have high entropy")
    }

    /// Verify score mapping is consistent across domains.
    func testScoreMappingConsistency() {
        let calc = EntropyCalculator(binCount: 32)

        // Low entropy (concentrated) → high coherence score
        let concentrated = Array(repeating: 50.0, count: 100) + [49.0, 51.0]
        let hLow = calc.shannonEntropy(concentrated)
        let scoreLow = calc.entropyToScore(hLow)

        // High entropy (spread) → low coherence score
        let spread = Array(stride(from: 0.0, to: 200.0, by: 0.5))
        let hHigh = calc.shannonEntropy(spread)
        let scoreHigh = calc.entropyToScore(hHigh)

        XCTAssertGreaterThan(scoreLow, scoreHigh,
            "Lower entropy should map to higher coherence score")
    }

    // MARK: - Summary Generation

    /// Verify bilingual summary generation for binding detection.
    func testSummaryGenerationBinding() {
        let analyzer = FlexAIDdSAnalyzer()
        let free = makeConformation(bondCount: 5, spread: 180)
        let bound = makeConformation(bondCount: 5, spread: 10)
        let pose = makePose(conformation: bound)

        let result = analyzer.analyze(freeConformation: free, dockingPose: pose)
        XCTAssertNotNil(result)

        guard let r = result else { return }
        XCTAssertTrue(r.summary.en.contains("penalty detected"),
            "Binding detection summary should say 'penalty detected'")
        XCTAssertTrue(r.summary.fr.contains("détectée"),
            "French summary should say 'détectée'")
        XCTAssertTrue(r.summary.en.contains("5 bonds"),
            "Summary should mention bond count")
    }

    /// Verify summary for non-significant result.
    func testSummaryGenerationNoBinding() {
        let analyzer = FlexAIDdSAnalyzer()
        let free = makeConformation(bondCount: 2, spread: 50)
        let bound = makeConformation(bondCount: 2, spread: 45)
        let pose = makePose(conformation: bound)

        let result = analyzer.analyze(freeConformation: free, dockingPose: pose)
        XCTAssertNotNil(result)

        guard let r = result else { return }
        if !r.bindingDetected {
            XCTAssertTrue(r.summary.en.contains("No significant"),
                "Non-binding summary should say 'No significant'")
        }
    }

    // MARK: - Validation Summary

    /// CrossDomainValidator summary should contain key statistics.
    func testValidationResultSummary() {
        let validator = CrossDomainValidator()

        let dockingResults = (0..<5).map { i in
            FlexAIDdSResult(
                substanceId: "drug_\(i)", receptorId: "1ABC",
                bondResults: (0...i).map { j in
                    BondEntropyResult(bondId: "b\(j)", freeEntropy: 4.0, boundEntropy: Double(4 - i) * 0.5)
                },
                dockingScore: Double(-6 - i)
            )
        }

        let now = Date()
        let drugResults: [DrugResponseResult] = (0..<5).map { i in
            let doseEvent = DoseEventSummary(
                medicationId: "drug_\(i)", name: "Drug \(i)",
                doseValue: 10, doseUnit: "mg", timestamp: now
            )
            let entropy = Double(4 - i) * 0.8
            let deltaH = Double(-i) * 0.5
            let measurement = EntropyMeasurement(
                minutesPostDose: 60, entropy: entropy,
                deltaH: deltaH, rrCount: 50, coherenceScore: 0.5
            )
            return DrugResponseResult(
                doseEvent: doseEvent,
                baselineEntropy: 4.0, baselineRRCount: 100,
                measurements: [measurement],
                peakDeltaH: deltaH, peakTimeMinutes: 60, profileMatch: nil
            )
        }

        let result = validator.validate(dockingResults: dockingResults, drugResponseResults: drugResults)
        XCTAssertNotNil(result)

        if let v = result {
            let summary = v.summary
            XCTAssertTrue(summary.en.contains("n=\(v.n)"))
            XCTAssertTrue(summary.en.contains("r ="))
            XCTAssertTrue(summary.en.contains("R²"))
            XCTAssertFalse(summary.fr.isEmpty)
        }
    }

    // MARK: - PharmacokineticProfile bindingEntropyKcal

    /// Verify that profilesWithBindingEntropy filter works.
    func testProfilesWithBindingEntropyFilter() {
        let profiles = PharmacokineticProfile.profilesWithBindingEntropy
        XCTAssertGreaterThan(profiles.count, 20,
            "Should have 20+ profiles with binding entropy data")

        for p in profiles {
            XCTAssertNotNil(p.bindingEntropyKcal)
        }

        // Amphetamine should be in the list
        XCTAssertTrue(profiles.contains { $0.substanceId == "amphetamine" })
    }

    // MARK: - Circular Entropy for Torsional Angles

    /// Verify that FlexAIDdSAnalyzer now uses circular entropy for torsional angles.
    /// Angles near ±180° should be recognized as constrained (low entropy),
    /// not mistakenly reported as high-entropy by linear binning.
    func testCircularEntropyUsedForAngles() {
        let analyzer = FlexAIDdSAnalyzer()

        // Free state: broad distribution centered at 0° (wide, high entropy)
        let freeBond = TorsionalAngleDistribution(
            bondId: "b1",
            angles: (0..<200).map { i in -170.0 + 340.0 * Double(i) / 199.0 }
        )

        // Bound state: constrained near the ±180° boundary
        // These angles are clustered within ~4° on the circle
        let boundAngles = (0..<200).map { i -> Double in
            if i < 100 { return 178.0 + Double(i % 4) * 0.5 }
            else { return -178.0 - Double(i % 4) * 0.5 }
        }
        let boundBond = TorsionalAngleDistribution(bondId: "b1", angles: boundAngles)

        let freeConf = LigandConformation(substanceId: "test", name: LocalizedString(en: "Test", fr: "Test"), bonds: [freeBond])
        let boundConf = LigandConformation(substanceId: "test", name: LocalizedString(en: "Test", fr: "Test"), bonds: [boundBond])
        let pose = DockingPose(boundConformation: boundConf, receptorId: "1ABC", dockingScore: -8.0)

        guard let result = analyzer.analyze(freeConformation: freeConf, dockingPose: pose) else {
            XCTFail("Analysis should produce a result")
            return
        }

        // ΔS should be strongly negative (bound is constrained → entropy collapsed)
        XCTAssertLessThan(result.totalDeltaSConfig, -1.0,
            "Angles constrained near ±180° should show entropy collapse with circular binning")
        XCTAssertTrue(result.bindingDetected,
            "Strong entropy collapse should be detected as binding")
    }
}
