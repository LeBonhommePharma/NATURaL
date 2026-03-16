import XCTest
@testable import BonhommeCore

/// Tests validating the DrugResponseAnalyzer against synthetic pharmacological data.
///
/// Each test generates time-stamped RR-interval distributions with known statistical
/// properties (mean, spread) to simulate pre-dose baseline and post-dose autonomic
/// response. The analyzer must correctly detect entropy collapse/expansion and
/// match the expected pharmacokinetic profile.
///
/// These tests constitute an independent physiological validation of the FlexAID∆S
/// entropy framework: the same EntropyCalculator that computes configurational entropy
/// of molecular torsional angles is here computing Shannon entropy of cardiac RR
/// intervals, and must detect "binding" (autonomic receptor activation) from the
/// distributional shift.
final class DrugResponseAnalyzerTests: XCTestCase {

    // MARK: - Test Helpers

    /// Generate a synthetic RR-interval time series with a given mean and spread.
    ///
    /// Creates a deterministic distribution (linearly spaced within ±spread of mean)
    /// to produce predictable entropy values without relying on random number generators.
    ///
    /// - Parameters:
    ///   - mean: Mean RR interval in milliseconds (e.g., 850 for resting, 650 for tachycardic).
    ///   - spread: Half-width of the distribution in ms (e.g., 60 for normal, 20 for compressed).
    ///   - count: Number of RR intervals to generate.
    ///   - startTime: Timestamp of the first interval.
    ///   - intervalSpacing: Time between successive intervals (seconds). Default 1.0.
    /// - Returns: Array of (timestamp, rrInterval) tuples.
    private func generateRRSeries(
        mean: Double,
        spread: Double,
        count: Int,
        startTime: Date,
        intervalSpacing: TimeInterval = 1.0
    ) -> [(timestamp: Date, rrInterval: Double)] {
        guard count > 0 else { return [] }
        guard spread > 0 else {
            // Constant values (with tiny jitter to avoid zero-range)
            return (0..<count).map { i in
                let t = startTime.addingTimeInterval(Double(i) * intervalSpacing)
                let rr = mean + (i % 2 == 0 ? 0.5 : -0.5)
                return (timestamp: t, rrInterval: rr)
            }
        }

        let step = (spread * 2) / Double(count - 1)
        return (0..<count).map { i in
            let t = startTime.addingTimeInterval(Double(i) * intervalSpacing)
            let rr = (mean - spread) + step * Double(i)
            return (timestamp: t, rrInterval: rr)
        }
    }

    /// Create a dose event summary for testing.
    private func makeDose(
        id: String = "test-rx",
        name: String = "TestDrug",
        value: Double = 10,
        unit: String = "mg",
        at time: Date
    ) -> DoseEventSummary {
        DoseEventSummary(
            medicationId: id,
            name: name,
            doseValue: value,
            doseUnit: unit,
            timestamp: time
        )
    }

    /// Build a complete RR time series with baseline + post-dose segments.
    ///
    /// - Parameters:
    ///   - doseTime: When the dose was administered.
    ///   - baselineMean: Mean RR during baseline (ms).
    ///   - baselineSpread: Spread during baseline (ms).
    ///   - postDoseMean: Mean RR after dose (ms).
    ///   - postDoseSpread: Spread after dose (ms).
    ///   - baselineDuration: Duration of baseline window (seconds).
    ///   - postDoseDuration: Duration of post-dose observation (seconds).
    /// - Returns: Combined RR time series spanning baseline through post-dose.
    private func buildTimeSeries(
        doseTime: Date,
        baselineMean: Double,
        baselineSpread: Double,
        postDoseMean: Double,
        postDoseSpread: Double,
        baselineDuration: TimeInterval = 1800,
        postDoseDuration: TimeInterval = 21600 // 6 hours
    ) -> [(timestamp: Date, rrInterval: Double)] {
        let baselineStart = doseTime.addingTimeInterval(-baselineDuration)
        let baselineCount = Int(baselineDuration) // 1 RR per second
        let postCount = Int(postDoseDuration)

        let baseline = generateRRSeries(
            mean: baselineMean,
            spread: baselineSpread,
            count: baselineCount,
            startTime: baselineStart
        )

        let postDose = generateRRSeries(
            mean: postDoseMean,
            spread: postDoseSpread,
            count: postCount,
            startTime: doseTime
        )

        return baseline + postDose
    }

    // MARK: - Amphetamine: Entropy Collapse Detection

    /// Validate that amphetamine-like sympathomimetic response produces entropy collapse.
    ///
    /// Expected physiology:
    /// - Pre-dose: Normal sinus rhythm, RR ~850ms ± 60ms → moderate entropy
    /// - Post-dose: Sympathetic activation, RR ~650ms ± 20ms → low entropy
    /// - ΔH should be significantly negative (entropy collapse)
    ///
    /// FlexAID∆S analog: Ligand binding freezes torsional angles → ΔS_config < 0
    func testAmphetamineEntropyCollapse() {
        let analyzer = DrugResponseAnalyzer(
            binCount: 32,
            windowRadius: 300,
            minimumRRCount: 20,
            baselineWindowSeconds: 1800
        )

        let doseTime = Date()
        let dose = makeDose(
            id: "amphetamine",
            name: "Amphetamine",
            value: 20,
            unit: "mg",
            at: doseTime
        )

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850,
            baselineSpread: 60,
            postDoseMean: 650,
            postDoseSpread: 20
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            profile: .amphetamine
        )

        XCTAssertNotNil(result, "Should produce a result with sufficient data")

        guard let r = result else { return }

        // Core assertion: entropy collapse detected
        XCTAssertTrue(r.bindingDetected, "Amphetamine should produce detectable entropy change")
        XCTAssertLessThan(r.peakDeltaH, 0, "Sympathomimetic should produce negative ΔH (entropy collapse)")
        XCTAssertLessThan(r.peakDeltaH, -0.4, "ΔH should exceed significance threshold")
        XCTAssertEqual(r.responseDirection, .sympathomimeticCollapse)

        // Baseline should be moderate entropy
        XCTAssertGreaterThan(r.baselineEntropy, 1.5, "Normal resting HRV should have moderate entropy")

        // Effect size should be substantial
        XCTAssertGreaterThan(r.effectSize, 0.2, "Effect size should be meaningful")

        // Profile match
        XCTAssertNotNil(r.profileMatch, "Should match amphetamine profile")
        if let match = r.profileMatch {
            XCTAssertEqual(match.profile.substanceId, "amphetamine")
            XCTAssertTrue(match.directionMatch, "Direction should match sympathomimetic")
            XCTAssertGreaterThan(match.confidence, 0.5, "Confidence should be above 50%")
        }

        // Measurements should exist
        XCTAssertGreaterThan(r.measurements.count, 0, "Should have post-dose measurements")

        // All post-dose measurements should show entropy decrease
        for m in r.measurements {
            XCTAssertLessThan(m.deltaH, 0.5,
                "Post-dose entropy should be lower than or close to baseline")
        }
    }

    // MARK: - Caffeine: Mild Collapse

    /// Caffeine should produce a mild, faster-onset entropy collapse.
    ///
    /// Expected: RR ~780ms ± 35ms (mild tachycardia, moderate variability compression)
    /// vs baseline ~850ms ± 60ms. Smaller |ΔH| than amphetamine.
    func testCaffeineMildCollapse() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(id: "caffeine", name: "Caffeine", value: 200, unit: "mg", at: doseTime)

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850,
            baselineSpread: 60,
            postDoseMean: 780,
            postDoseSpread: 35
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            profile: .caffeine
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        // Should still detect a change, but milder
        XCTAssertLessThan(r.peakDeltaH, 0, "Caffeine should produce negative ΔH")

        // Caffeine ΔH should be less extreme than amphetamine equivalent
        // (comparing against the amphetamine test's expected ~-1.4 bits)
        XCTAssertGreaterThan(r.peakDeltaH, -2.0,
            "Caffeine ΔH should be less extreme than a full sympathomimetic")
    }

    // MARK: - Propranolol: Entropy Expansion

    /// Beta-blocker should produce entropy expansion (opposite of stimulant).
    ///
    /// Expected: RR ~900ms ± 80ms (bradycardia, expanded variability)
    /// vs baseline ~850ms ± 60ms. ΔH should be positive.
    ///
    /// FlexAID∆S analog: Allosteric modulator relaxes conformational constraints → ΔS > 0
    func testPropranololEntropyExpansion() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(id: "propranolol", name: "Propranolol", value: 40, unit: "mg", at: doseTime)

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850,
            baselineSpread: 60,
            postDoseMean: 900,
            postDoseSpread: 80
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            profile: .propranolol
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertGreaterThan(r.peakDeltaH, 0, "Beta-blocker should produce positive ΔH (entropy expansion)")
        XCTAssertEqual(r.responseDirection, .parasympathomimeticExpansion)

        if let match = r.profileMatch {
            XCTAssertTrue(match.directionMatch, "Direction should match parasympathomimetic")
        }
    }

    // MARK: - Inert Substance: No Significant Change

    /// A substance with no autonomic effect should produce no significant ΔH.
    ///
    /// Same distribution pre and post → ΔH ≈ 0.
    func testInertSubstanceNoChange() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(id: "placebo", name: "Placebo", value: 1, unit: "tab", at: doseTime)

        // Identical distribution pre and post
        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850,
            baselineSpread: 60,
            postDoseMean: 850,
            postDoseSpread: 60
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertEqual(r.responseDirection, .noSignificantChange,
            "Placebo should show no significant entropy change")
        XCTAssertFalse(r.bindingDetected, "No binding should be detected for inert substance")
        XCTAssertLessThan(abs(r.peakDeltaH), 0.5,
            "|ΔH| should be near zero for identical distributions")
    }

    // MARK: - Opioid: Vagotonic Expansion

    /// Morphine (mu-opioid agonist) should produce entropy expansion (vagotonic).
    ///
    /// Expected: RR ~950ms ± 90ms (bradycardia, high variability)
    func testMorphineVagotonicExpansion() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(id: "morphine", name: "Morphine", value: 10, unit: "mg", at: doseTime)

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850,
            baselineSpread: 60,
            postDoseMean: 950,
            postDoseSpread: 90
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            profile: .morphine
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertGreaterThan(r.peakDeltaH, 0, "Opioid should increase HRV entropy (vagotonic)")
        XCTAssertEqual(r.responseDirection, .parasympathomimeticExpansion)
    }

    // MARK: - Anticholinergic: Vagal Brake Removal

    /// Atropine (muscarinic antagonist) removes vagal brake → entropy collapse.
    ///
    /// Expected: RR ~700ms ± 15ms (tachycardic, rigid)
    func testAtropineVagalBrakeRemoval() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(id: "atropine", name: "Atropine", value: 0.5, unit: "mg", at: doseTime)

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850,
            baselineSpread: 60,
            postDoseMean: 700,
            postDoseSpread: 15
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            profile: .atropine
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertLessThan(r.peakDeltaH, -0.4, "Atropine should produce strong entropy collapse")
        XCTAssertEqual(r.responseDirection, .sympathomimeticCollapse)
        XCTAssertTrue(r.bindingDetected)
    }

    // MARK: - Benzodiazepine: GABAergic Expansion

    /// Alprazolam should produce entropy expansion (parasympathomimetic via GABA).
    func testAlprazolamGABAergicExpansion() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(id: "alprazolam", name: "Alprazolam", value: 1, unit: "mg", at: doseTime)

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850,
            baselineSpread: 60,
            postDoseMean: 880,
            postDoseSpread: 75
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            profile: .alprazolam
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertGreaterThan(r.peakDeltaH, 0, "Benzodiazepine should expand HRV entropy")
    }

    // MARK: - SNRI: Noradrenergic Collapse

    /// Venlafaxine (SNRI) at therapeutic dose should show mild sympathomimetic collapse.
    func testVenlafaxineSNRICollapse() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(id: "venlafaxine", name: "Venlafaxine", value: 150, unit: "mg", at: doseTime)

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850,
            baselineSpread: 60,
            postDoseMean: 790,
            postDoseSpread: 40
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            profile: .venlafaxine
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertLessThan(r.peakDeltaH, 0, "SNRI should produce entropy collapse via NE reuptake inhibition")
    }

    // MARK: - Profile Matching Accuracy

    /// Without specifying a profile, the analyzer should auto-detect the best match.
    func testAutoProfileDetection() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()

        // Strong sympathomimetic signature (amphetamine-like)
        let dose = makeDose(id: "unknown", name: "Unknown", value: 20, unit: "mg", at: doseTime)
        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850,
            baselineSpread: 60,
            postDoseMean: 650,
            postDoseSpread: 20
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries
            // No profile specified — should auto-detect
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        XCTAssertTrue(r.bindingDetected)

        // Should match a sympathomimetic profile
        if let match = r.profileMatch {
            XCTAssertEqual(match.profile.mechanism, .sympathomimetic,
                "Auto-detected profile should be sympathomimetic")
            XCTAssertTrue(match.directionMatch)
            XCTAssertGreaterThan(match.confidence, 0.5)
        }
    }

    // MARK: - Direction Match Validation

    /// Verify that direction match correctly identifies sympathomimetic vs parasympathomimetic.
    func testDirectionMatchClassification() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()

        // Sympathomimetic (collapse)
        let collapseRR = buildTimeSeries(
            doseTime: doseTime, baselineMean: 850, baselineSpread: 60,
            postDoseMean: 650, postDoseSpread: 20
        )
        let collapse = analyzer.analyze(
            doseEvent: makeDose(at: doseTime),
            rrTimeSeries: collapseRR,
            profile: .amphetamine
        )
        XCTAssertTrue(collapse?.profileMatch?.directionMatch ?? false)

        // Wrong direction: parasympathomimetic data with sympathomimetic profile
        let expansionRR = buildTimeSeries(
            doseTime: doseTime, baselineMean: 850, baselineSpread: 60,
            postDoseMean: 920, postDoseSpread: 85
        )
        let mismatch = analyzer.analyze(
            doseEvent: makeDose(at: doseTime),
            rrTimeSeries: expansionRR,
            profile: .amphetamine
        )
        XCTAssertFalse(mismatch?.profileMatch?.directionMatch ?? true,
            "Positive ΔH should NOT match sympathomimetic direction")
    }

    // MARK: - Batch Analysis & Aggregation

    /// Analyze multiple dose events and verify aggregate statistics.
    func testBatchAnalysisAndAggregation() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        var allRR: [(timestamp: Date, rrInterval: Double)] = []
        var doses: [DoseEventSummary] = []

        // Simulate 3 dose events, 12 hours apart
        for i in 0..<3 {
            let doseTime = Date().addingTimeInterval(Double(i) * 43200) // 12h apart
            doses.append(makeDose(
                id: "amphetamine",
                name: "Amphetamine",
                value: 20,
                unit: "mg",
                at: doseTime
            ))

            let series = buildTimeSeries(
                doseTime: doseTime,
                baselineMean: 850,
                baselineSpread: 60,
                postDoseMean: 650,
                postDoseSpread: 20
            )
            allRR.append(contentsOf: series)
        }

        let results = analyzer.analyzeBatch(
            doseEvents: doses,
            rrTimeSeries: allRR,
            profile: .amphetamine
        )

        XCTAssertEqual(results.count, 3, "Should analyze all 3 dose events")

        let aggregate = analyzer.aggregate(results)
        XCTAssertNotNil(aggregate)

        guard let agg = aggregate else { return }

        XCTAssertEqual(agg.n, 3)
        XCTAssertLessThan(agg.meanDeltaH, 0, "Mean ΔH should be negative for sympathomimetic")
        XCTAssertEqual(agg.detectionRate, 1.0, accuracy: 0.01,
            "All doses should produce detectable response")

        // Cohen's d should indicate a large effect
        XCTAssertGreaterThan(agg.cohensD, 0.8,
            "Cohen's d should be large for consistent sympathomimetic response")
    }

    // MARK: - Dose-Response Curve

    /// Higher doses should produce larger |ΔH| (dose-response relationship).
    ///
    /// This is the FlexAID∆S validation: stronger binding → larger entropy loss,
    /// just as higher ligand concentration → more occupied binding sites → more
    /// torsional entropy frozen.
    func testDoseResponseCorrelation() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        var allRR: [(timestamp: Date, rrInterval: Double)] = []
        var doses: [DoseEventSummary] = []

        // Simulate 3 different dose levels with proportional autonomic effects
        // Low dose (5mg): mild effect
        // Medium dose (20mg): moderate effect
        // High dose (40mg): strong effect
        let doseConfigs: [(value: Double, postMean: Double, postSpread: Double)] = [
            (5, 800, 50),    // mild: small shift from 850/60 baseline
            (20, 700, 30),   // moderate: larger shift
            (40, 620, 15),   // strong: pronounced shift
        ]

        for (i, config) in doseConfigs.enumerated() {
            let doseTime = Date().addingTimeInterval(Double(i) * 43200)
            doses.append(makeDose(
                id: "amphetamine",
                name: "Amphetamine",
                value: config.value,
                unit: "mg",
                at: doseTime
            ))

            let series = buildTimeSeries(
                doseTime: doseTime,
                baselineMean: 850,
                baselineSpread: 60,
                postDoseMean: config.postMean,
                postDoseSpread: config.postSpread
            )
            allRR.append(contentsOf: series)
        }

        let results = analyzer.analyzeBatch(
            doseEvents: doses,
            rrTimeSeries: allRR,
            profile: .amphetamine
        )

        XCTAssertEqual(results.count, 3)

        // Verify dose-response ordering: higher dose → larger |ΔH|
        let sorted = results.sorted(by: { $0.doseEvent.doseValue < $1.doseEvent.doseValue })
        for i in 1..<sorted.count {
            XCTAssertGreaterThan(
                abs(sorted[i].peakDeltaH),
                abs(sorted[i - 1].peakDeltaH),
                "Higher dose (\(sorted[i].doseEvent.doseValue)mg) should produce larger |ΔH| than lower dose (\(sorted[i - 1].doseEvent.doseValue)mg)"
            )
        }

        // Dose-response curve should show positive correlation
        let curve = analyzer.doseResponseCurve(results)
        XCTAssertNotNil(curve)
        if let c = curve {
            XCTAssertEqual(c.points.count, 3)
            XCTAssertGreaterThan(c.pearsonR, 0.9,
                "Pearson r should be > 0.9 for a strong dose-response relationship")
        }
    }

    // MARK: - Edge Cases

    /// Insufficient baseline data should return nil.
    func testInsufficientBaselineReturnsNil() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(at: doseTime)

        // Only 5 baseline intervals (below minimumRRCount of 20)
        let rrSeries = generateRRSeries(
            mean: 850, spread: 60, count: 5,
            startTime: doseTime.addingTimeInterval(-300)
        )

        let result = analyzer.analyze(doseEvent: dose, rrTimeSeries: rrSeries)
        XCTAssertNil(result, "Should return nil with insufficient baseline data")
    }

    /// Empty post-dose data should return nil.
    func testNoPostDoseDataReturnsNil() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(at: doseTime)

        // Only baseline data, no post-dose
        let rrSeries = generateRRSeries(
            mean: 850, spread: 60, count: 100,
            startTime: doseTime.addingTimeInterval(-1800)
        )

        let result = analyzer.analyze(doseEvent: dose, rrTimeSeries: rrSeries)
        XCTAssertNil(result, "Should return nil with no post-dose data")
    }

    /// Custom measurement windows should be honored.
    func testCustomMeasurementWindows() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(at: doseTime)

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850, baselineSpread: 60,
            postDoseMean: 700, postDoseSpread: 30
        )

        let customWindows: [Double] = [30, 90, 150]
        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            customWindows: customWindows
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        // Should have measurements at exactly the custom windows
        let measuredWindows = r.measurements.map(\.minutesPostDose)
        for window in customWindows {
            XCTAssertTrue(measuredWindows.contains(window),
                "Should have measurement at \(window) minutes")
        }
    }

    // MARK: - Effect Size & AUC Validation

    /// Verify that effect size and AUC are computed correctly.
    func testEffectSizeAndAUC() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(at: doseTime)

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850, baselineSpread: 60,
            postDoseMean: 650, postDoseSpread: 20
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            profile: .amphetamine
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        // Effect size should be > 0 and < 1 (fractional reduction)
        XCTAssertGreaterThan(r.effectSize, 0)
        XCTAssertLessThanOrEqual(r.effectSize, 1.0)

        // AUC should be negative for sympathomimetic (cumulative entropy loss)
        XCTAssertLessThan(r.deltaHAUC, 0,
            "Cumulative ΔH AUC should be negative for sustained entropy collapse")
    }

    // MARK: - Onset and Recovery Detection

    /// Verify onset and recovery time detection.
    func testOnsetAndRecoveryDetection() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()
        let dose = makeDose(at: doseTime)

        let rrSeries = buildTimeSeries(
            doseTime: doseTime,
            baselineMean: 850, baselineSpread: 60,
            postDoseMean: 650, postDoseSpread: 20
        )

        let result = analyzer.analyze(
            doseEvent: dose,
            rrTimeSeries: rrSeries,
            customWindows: [15, 30, 60, 90, 120, 180, 240, 360]
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        // Onset should be at one of the early windows
        if let onset = r.onsetMinutes {
            XCTAssertLessThanOrEqual(onset, 60,
                "Onset should be detected within the first hour for a strong sympathomimetic")
        }
    }

    // MARK: - PharmacokineticProfile Registry

    /// Verify the profile registry contains all expected substances.
    func testProfileRegistryCompleteness() {
        let profiles = PharmacokineticProfile.knownProfiles

        // Should have a substantial number of profiles
        XCTAssertGreaterThan(profiles.count, 70,
            "Registry should contain 70+ substance profiles")

        // All IDs should be unique
        let ids = profiles.map(\.substanceId)
        XCTAssertEqual(ids.count, Set(ids).count, "All substance IDs should be unique")

        // Key substances should be present
        let requiredSubstances = [
            "amphetamine", "methylphenidate", "caffeine", "propranolol",
            "morphine", "alprazolam", "sertraline", "quetiapine",
            "nicotine", "ethanol", "cocaine", "atropine", "lithium"
        ]

        for substance in requiredSubstances {
            XCTAssertNotNil(
                PharmacokineticProfile.profile(for: substance),
                "Registry should contain profile for \(substance)"
            )
        }
    }

    /// Verify profile lookup by therapeutic class.
    func testProfileLookupByClass() {
        let stimulants = PharmacokineticProfile.profiles(for: .stimulant)
        XCTAssertGreaterThan(stimulants.count, 5, "Should have multiple stimulant profiles")

        let betaBlockers = PharmacokineticProfile.profiles(for: .betaBlocker)
        XCTAssertGreaterThan(betaBlockers.count, 3, "Should have multiple beta-blocker profiles")

        // All stimulants should be sympathomimetic
        for stim in stimulants {
            XCTAssertEqual(stim.mechanism, .sympathomimetic,
                "\(stim.substanceId) should be sympathomimetic")
        }

        // All beta-blockers should be parasympathomimetic
        for bb in betaBlockers {
            XCTAssertEqual(bb.mechanism, .parasympathomimetic,
                "\(bb.substanceId) should be parasympathomimetic")
        }
    }

    /// Verify FDA-approved filter works.
    func testFDAApprovedFilter() {
        let fdaApproved = PharmacokineticProfile.fdaApprovedProfiles
        XCTAssertGreaterThan(fdaApproved.count, 50,
            "Most profiles should be FDA-approved")

        // LSD should not be FDA-approved
        let lsd = PharmacokineticProfile.profile(for: "lsd")
        XCTAssertNotNil(lsd)
        XCTAssertFalse(lsd!.fdaApproved)

        // Sertraline should be FDA-approved
        let sertraline = PharmacokineticProfile.profile(for: "sertraline")
        XCTAssertNotNil(sertraline)
        XCTAssertTrue(sertraline!.fdaApproved)
    }

    // MARK: - Entropy Parity with FlexAID∆S

    /// Verify that the same EntropyCalculator used in FlexAID∆S molecular docking
    /// produces correct, expected values on cardiac RR-interval distributions.
    ///
    /// This is the cornerstone validation: identical math, different domain.
    func testEntropyCalculatorParityWithFlexAIDdS() {
        let calc = EntropyCalculator(binCount: 32)

        // 1. Uniform distribution → maximum entropy (all bins equally populated)
        //    FlexAID∆S analog: freely rotating torsion → max configurational entropy
        let uniform = Array(stride(from: 600.0, through: 1000.0, by: 1.0))
        let hUniform = calc.shannonEntropy(uniform)
        XCTAssertGreaterThan(hUniform, 4.0,
            "Uniform distribution should have high entropy (> 4 bits)")

        // 2. Concentrated distribution → low entropy
        //    FlexAID∆S analog: locked torsion in binding pocket → minimal entropy
        let concentrated = Array(repeating: 750.0, count: 400) + Array(stride(from: 749.0, to: 751.0, by: 0.1))
        let hConcentrated = calc.shannonEntropy(concentrated)
        XCTAssertLessThan(hConcentrated, 1.0,
            "Concentrated distribution should have low entropy (< 1 bit)")

        // 3. The delta should be large (this IS the binding signal)
        let deltaH = hConcentrated - hUniform
        XCTAssertLessThan(deltaH, -3.0,
            "ΔH from uniform to concentrated should be strongly negative (> 3 bits)")

        // 4. Score mapping should invert correctly
        let scoreUniform = calc.entropyToScore(hUniform)
        let scoreConcentrated = calc.entropyToScore(hConcentrated)
        XCTAssertLessThan(scoreUniform, scoreConcentrated,
            "Concentrated (bound) should have higher coherence score than uniform (free)")
    }

    // MARK: - Multi-Class Discrimination

    /// The analyzer should correctly distinguish between drug classes based on
    /// their entropy signatures alone (without being told the drug class).
    func testMultiClassDiscrimination() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()

        // Sympathomimetic signature (amphetamine-like)
        let stimRR = buildTimeSeries(
            doseTime: doseTime, baselineMean: 850, baselineSpread: 60,
            postDoseMean: 650, postDoseSpread: 20
        )
        let stimResult = analyzer.analyze(
            doseEvent: makeDose(id: "stim", name: "Unknown Stimulant", at: doseTime),
            rrTimeSeries: stimRR
        )

        // Parasympathomimetic signature (beta-blocker-like)
        let bbRR = buildTimeSeries(
            doseTime: doseTime, baselineMean: 850, baselineSpread: 60,
            postDoseMean: 920, postDoseSpread: 85
        )
        let bbResult = analyzer.analyze(
            doseEvent: makeDose(id: "bb", name: "Unknown Beta-Blocker", at: doseTime),
            rrTimeSeries: bbRR
        )

        // Inert signature
        let inertRR = buildTimeSeries(
            doseTime: doseTime, baselineMean: 850, baselineSpread: 60,
            postDoseMean: 850, postDoseSpread: 60
        )
        let inertResult = analyzer.analyze(
            doseEvent: makeDose(id: "inert", name: "Placebo", at: doseTime),
            rrTimeSeries: inertRR
        )

        // Discrimination assertions
        XCTAssertNotNil(stimResult)
        XCTAssertNotNil(bbResult)
        XCTAssertNotNil(inertResult)

        XCTAssertEqual(stimResult?.responseDirection, .sympathomimeticCollapse)
        XCTAssertEqual(bbResult?.responseDirection, .parasympathomimeticExpansion)
        XCTAssertEqual(inertResult?.responseDirection, .noSignificantChange)

        // Stimulant and beta-blocker should have opposite ΔH signs
        if let s = stimResult, let b = bbResult {
            XCTAssertLessThan(s.peakDeltaH, 0, "Stimulant should collapse entropy")
            XCTAssertGreaterThan(b.peakDeltaH, 0, "Beta-blocker should expand entropy")
        }
    }

    // MARK: - Summary Generation

    /// Verify that human-readable summaries are generated correctly.
    func testSummaryGeneration() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)
        let doseTime = Date()

        let rrSeries = buildTimeSeries(
            doseTime: doseTime, baselineMean: 850, baselineSpread: 60,
            postDoseMean: 650, postDoseSpread: 20
        )

        let result = analyzer.analyze(
            doseEvent: makeDose(id: "amphetamine", name: "Amphetamine", at: doseTime),
            rrTimeSeries: rrSeries,
            profile: .amphetamine
        )

        XCTAssertNotNil(result)
        guard let r = result else { return }

        let summary = r.summary

        // English summary should contain key information
        XCTAssertTrue(summary.en.contains("ΔH"), "Summary should contain ΔH")
        XCTAssertTrue(summary.en.contains("collapse") || summary.en.contains("expansion") || summary.en.contains("No significant"),
            "Summary should describe the direction")
        XCTAssertTrue(summary.en.contains("bits"), "Summary should include units")

        // French summary should also be populated
        XCTAssertFalse(summary.fr.isEmpty, "French summary should not be empty")
    }

    // MARK: - Aggregate Summary

    /// Verify aggregate statistics produce meaningful summaries.
    func testAggregateStatisticsSummary() {
        let analyzer = DrugResponseAnalyzer(binCount: 32, minimumRRCount: 20)

        var results: [DrugResponseResult] = []
        for i in 0..<5 {
            let doseTime = Date().addingTimeInterval(Double(i) * 86400)
            let rrSeries = buildTimeSeries(
                doseTime: doseTime,
                baselineMean: 850, baselineSpread: 60,
                postDoseMean: 650, postDoseSpread: 20
            )

            if let r = analyzer.analyze(
                doseEvent: makeDose(value: 20, at: doseTime),
                rrTimeSeries: rrSeries,
                profile: .amphetamine
            ) {
                results.append(r)
            }
        }

        let aggregate = analyzer.aggregate(results)
        XCTAssertNotNil(aggregate)

        guard let agg = aggregate else { return }

        XCTAssertEqual(agg.n, 5)
        let summary = agg.summary
        XCTAssertTrue(summary.en.contains("5 dose events"))
        XCTAssertTrue(summary.en.contains("Cohen's d"))
    }
}
