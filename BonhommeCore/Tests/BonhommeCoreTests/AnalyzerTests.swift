import XCTest
@testable import BonhommeCore

final class AnalyzerTests: XCTestCase {

    // MARK: - HRVAnalyzer

    func testHRVAnalyzerNoData() {
        let analyzer = HRVAnalyzer()
        let result = analyzer.analyze(signals: [], context: AnalysisContext())

        XCTAssertNil(result.score)
        XCTAssertEqual(result.trend, .stable)
        XCTAssertEqual(result.status, .normal)
        XCTAssertEqual(result.signalType, .heartRateVariability)
    }

    func testHRVAnalyzerShannonEntropy() {
        let analyzer = HRVAnalyzer(binCount: 8)

        // Uniform over the full fixed domain [300, 1500]: near-max entropy (log₂8 = 3)
        let uniform = Array(stride(from: 300.0, through: 1500.0, by: 5.0))
        let highEntropy = analyzer.shannonEntropy(uniform)
        XCTAssertGreaterThan(highEntropy, 2.0, "Uniform RR intervals over full domain should have high entropy")

        // Nearly constant: minimum entropy (fixed domain concentrates into few bins)
        let constant = Array(repeating: 800.0, count: 100) + [801.0]
        let lowEntropy = analyzer.shannonEntropy(constant)
        XCTAssertLessThan(lowEntropy, 1.0, "Constant RR intervals should have near-zero entropy")
    }

    func testHRVAnalyzerFixedRRDomainConstants() {
        XCTAssertEqual(HRVAnalyzer.rrDomainMinMs, 300, accuracy: 0)
        XCTAssertEqual(HRVAnalyzer.rrDomainMaxMs, 1500, accuracy: 0)
        XCTAssertLessThan(HRVAnalyzer.rrDomainMinMs, HRVAnalyzer.rrDomainMaxMs)
    }

    func testHRVAnalyzerUsesFixedDomainNotAdaptive() {
        let binCount = 32
        let analyzer = HRVAnalyzer(binCount: binCount)
        let calc = EntropyCalculator(binCount: binCount)

        // Tight cluster well inside [300, 1500]: adaptive bins hug the data,
        // so the same spread fills many adaptive bins but only ~1 fixed-domain bin.
        // Deterministic ±5 ms around 800 ms (bin width fixed ≈ 37.5 ms for 32 bins).
        let tight = (0..<200).map { i in 800.0 + Double((i % 11) - 5) }
        let fixedH = analyzer.shannonEntropy(tight)
        let adaptiveH = calc.shannonEntropy(tight)

        XCTAssertLessThan(
            fixedH, adaptiveH,
            "Fixed [300,1500] domain should report lower entropy for a tight RR cluster than adaptive binning"
        )

        // Match EntropyCalculator fixed-domain API exactly
        let expected = calc.shannonEntropy(
            tight,
            domainMin: HRVAnalyzer.rrDomainMinMs,
            domainMax: HRVAnalyzer.rrDomainMaxMs
        )
        XCTAssertEqual(fixedH, expected, accuracy: 1e-12,
                       "HRVAnalyzer must call shannonEntropy(_:domainMin:domainMax:) with [300,1500]")
    }

    func testHRVAnalyzerFixedDomainClampsOutliers() {
        let binCount = 16
        let analyzer = HRVAnalyzer(binCount: binCount)
        let calc = EntropyCalculator(binCount: binCount)

        // Values outside the physiological domain must clamp like the fixed-domain API
        let withOutliers = [200.0, 800.0, 800.0, 800.0, 2000.0, 810.0, 790.0, 805.0]
        let hrvH = analyzer.shannonEntropy(withOutliers)
        let fixedH = calc.shannonEntropy(
            withOutliers,
            domainMin: HRVAnalyzer.rrDomainMinMs,
            domainMax: HRVAnalyzer.rrDomainMaxMs
        )
        XCTAssertEqual(hrvH, fixedH, accuracy: 1e-12)

        // Adaptive expands to the raw min/max including outliers; fixed domain clamps.
        // A second series with the same interior points but no outliers should match fixed H.
        let interiorOnly = [800.0, 800.0, 800.0, 810.0, 790.0, 805.0]
        let interiorFixed = analyzer.shannonEntropy(interiorOnly)
        // Clamped outliers land at domain edges, so H may differ from pure interior —
        // but must still equal EntropyCalculator fixed-domain (already asserted).
        // Adaptive on outliers must differ from adaptive on interior (range expanded).
        let adaptiveOut = calc.shannonEntropy(withOutliers)
        let adaptiveIn = calc.shannonEntropy(interiorOnly)
        XCTAssertNotEqual(adaptiveOut, adaptiveIn, accuracy: 1e-9,
                          "Adaptive binning expands with outliers; fixed domain does not")
        _ = interiorFixed
    }

    func testHRVAnalyzerWithSignals() {
        let analyzer = HRVAnalyzer()
        let signals: [any HealthSignal] = (0..<10).map { i in
            HRVSignal(
                timestamp: Date().addingTimeInterval(Double(-10 + i)),
                sdnn: 40 + Double(i),
                rmssd: 35 + Double(i),
                rrIntervals: [800, 810, 790, 820, 805]
            )
        }

        let result = analyzer.analyze(signals: signals, context: AnalysisContext())
        XCTAssertNotNil(result.score)
        if let score = result.score {
            XCTAssertGreaterThanOrEqual(score, 0.0)
            XCTAssertLessThanOrEqual(score, 1.0)
        }
    }

    // MARK: - MedicationAnalyzer

    func testMedicationAnalyzerNoData() {
        let analyzer = MedicationAnalyzer()
        let result = analyzer.analyze(signals: [], context: AnalysisContext())

        XCTAssertNil(result.score)
        XCTAssertEqual(result.signalType, .medication)
    }

    func testMedicationAnalyzerPerfectAdherence() {
        let analyzer = MedicationAnalyzer(windowDays: 7)
        let signals: [any HealthSignal] = (0..<7).map { i in
            MedicationSignal(
                timestamp: Date().addingTimeInterval(Double(-86400 * i)),
                medicationId: "rx-1",
                name: LocalizedString(en: "TestMed", fr: "TestMed"),
                doseValue: 100,
                doseUnit: "mg",
                event: .taken
            )
        }

        let result = analyzer.analyze(signals: signals, context: AnalysisContext())
        XCTAssertEqual(result.score, 1.0, "All doses taken should yield 100% adherence")
        XCTAssertEqual(result.status, .normal)
    }

    func testMedicationAnalyzerMixedAdherence() {
        let analyzer = MedicationAnalyzer(windowDays: 7)
        let signals: [any HealthSignal] = [
            MedicationSignal(
                timestamp: Date(),
                medicationId: "rx-1",
                name: LocalizedString(en: "Med", fr: "Med"),
                doseValue: 100, doseUnit: "mg", event: .taken
            ),
            MedicationSignal(
                timestamp: Date().addingTimeInterval(-86400),
                medicationId: "rx-1",
                name: LocalizedString(en: "Med", fr: "Med"),
                doseValue: 100, doseUnit: "mg", event: .missed
            ),
        ]

        let result = analyzer.analyze(signals: signals, context: AnalysisContext())
        XCTAssertNotNil(result.score)
        XCTAssertEqual(result.score!, 0.5, accuracy: 0.01, "1 taken + 1 missed = 50%")
    }

    // MARK: - FeedbackEngine

    func testFeedbackEngineMultiSignal() {
        let engine = FeedbackEngine()
        engine.register(HRVAnalyzer())
        engine.register(MedicationAnalyzer())

        // Ingest HRV
        engine.ingest(HRVSignal(
            timestamp: Date(),
            sdnn: 42,
            rmssd: 38,
            rrIntervals: [800, 810, 790, 820]
        ))

        // Ingest medication
        engine.ingest(MedicationSignal(
            timestamp: Date(),
            medicationId: "rx-1",
            name: LocalizedString(en: "Aspirin", fr: "Aspirine"),
            doseValue: 81,
            doseUnit: "mg",
            event: .taken
        ))

        let results = engine.analyzeAll()

        XCTAssertNotNil(results[.heartRateVariability])
        XCTAssertNotNil(results[.medication])
        XCTAssertEqual(results.count, 2)
    }

    func testFeedbackEngineLatestInsight() {
        let engine = FeedbackEngine()
        engine.register(HRVAnalyzer())

        XCTAssertNil(engine.latestInsight(for: .heartRateVariability))

        _ = engine.analyze(for: .heartRateVariability)

        XCTAssertNotNil(engine.latestInsight(for: .heartRateVariability))
    }

    // MARK: - AnalysisInsight Codable

    func testAnalysisInsightCodable() throws {
        let insight = AnalysisInsight(
            signalType: .medication,
            score: 0.85,
            trend: .improving,
            status: .normal,
            summary: LocalizedString(en: "Good adherence", fr: "Bonne adhérence")
        )

        let data = try JSONEncoder().encode(insight)
        let decoded = try JSONDecoder().decode(AnalysisInsight.self, from: data)

        XCTAssertEqual(decoded.signalType, .medication)
        XCTAssertEqual(decoded.score, 0.85)
        XCTAssertEqual(decoded.trend, .improving)
        XCTAssertEqual(decoded.status, .normal)
    }

    // MARK: - EntropyCalculator

    func testEntropyCalculatorUniform() {
        let calc = EntropyCalculator(binCount: 8)

        // Uniform distribution: should have high entropy (near log2(8) = 3.0)
        let uniform = Array(stride(from: 700.0, through: 900.0, by: 1.0))
        let entropy = calc.shannonEntropy(uniform)
        XCTAssertGreaterThan(entropy, 2.0, "Uniform distribution should have high entropy")
    }

    func testEntropyCalculatorConstant() {
        let calc = EntropyCalculator(binCount: 8)

        // Nearly constant: should have near-zero entropy
        let constant = Array(repeating: 800.0, count: 100) + [801.0]
        let entropy = calc.shannonEntropy(constant)
        XCTAssertLessThan(entropy, 1.0, "Constant values should have near-zero entropy")
    }

    func testEntropyCalculatorEdgeCases() {
        let calc = EntropyCalculator(binCount: 32)

        // Empty array
        XCTAssertEqual(calc.shannonEntropy([]), 0)

        // Single value
        XCTAssertEqual(calc.shannonEntropy([800.0]), 0)

        // Two identical values (zero range)
        XCTAssertEqual(calc.shannonEntropy([800.0, 800.0]), 0)

        // Two different values
        let twoValues = calc.shannonEntropy([700.0, 900.0])
        XCTAssertGreaterThan(twoValues, 0)
    }

    func testEntropyToScore() {
        let calc = EntropyCalculator(binCount: 32)
        let maxH = log2(32.0) // 5.0 — theoretical max for 32 bins

        // Zero entropy → score 1.0 (maximally coherent)
        XCTAssertEqual(calc.entropyToScore(0), 1.0)

        // Theoretical max → score 0.0
        XCTAssertEqual(calc.entropyToScore(maxH), 0.0, accuracy: 1e-12)

        // Mid-range: H = 2.5 → score 0.5 under log₂(32)
        XCTAssertEqual(calc.entropyToScore(2.5), 0.5, accuracy: 0.001)

        // Beyond max → clamped to 0.0
        XCTAssertEqual(calc.entropyToScore(10.0), 0.0)

        // Negative → clamped to 1.0
        XCTAssertEqual(calc.entropyToScore(-1.0), 1.0)

        // Custom max entropy
        XCTAssertEqual(calc.entropyToScore(5.0, maxEntropy: 10.0), 0.5, accuracy: 0.001)
    }

    func testEntropyCalculatorAnalyze() {
        let calc = EntropyCalculator(binCount: 8)

        // Nil for insufficient data
        XCTAssertNil(calc.analyze([]))
        XCTAssertNil(calc.analyze([800.0]))

        // Valid result for sufficient data
        let result = calc.analyze([700, 750, 800, 850, 900])
        XCTAssertNotNil(result)
        if let r = result {
            XCTAssertGreaterThan(r.entropy, 0)
            XCTAssertGreaterThanOrEqual(r.score, 0)
            XCTAssertLessThanOrEqual(r.score, 1)
        }
    }

    func testEntropyCalculatorMatchesHRVAnalyzer() {
        // HRVAnalyzer uses fixed RR domain [300, 1500] ms — match that overload
        let binCount = 8
        let calc = EntropyCalculator(binCount: binCount)
        let analyzer = HRVAnalyzer(binCount: binCount)

        let values = Array(stride(from: 700.0, through: 900.0, by: 1.0))
        let calcEntropy = calc.shannonEntropy(
            values,
            domainMin: HRVAnalyzer.rrDomainMinMs,
            domainMax: HRVAnalyzer.rrDomainMaxMs
        )
        let analyzerEntropy = analyzer.shannonEntropy(values)

        XCTAssertEqual(calcEntropy, analyzerEntropy, accuracy: 0.0001,
                       "EntropyCalculator fixed-domain and HRVAnalyzer should produce identical results")
    }

    // MARK: - BiofeedbackSnapshot with Insights

    func testBiofeedbackSnapshotFromFeedbackEngine() throws {
        let insight = AnalysisInsight(
            signalType: .heartRateVariability,
            score: 0.72,
            trend: .improving,
            status: .normal,
            summary: LocalizedString(en: "Focused", fr: "Concentré")
        )

        let snapshot = BiofeedbackSnapshot(
            heartRate: 68,
            activeCalories: 12.5,
            feedbackInsights: [.heartRateVariability: insight]
        )

        XCTAssertEqual(snapshot.sciScore, 0.72)
        XCTAssertEqual(snapshot.sciTrend, .improving)
        XCTAssertEqual(snapshot.insights.count, 1)

        // Verify Codable roundtrip
        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(BiofeedbackSnapshot.self, from: data)
        XCTAssertEqual(decoded.sciScore, 0.72)
        XCTAssertEqual(decoded.insights[.heartRateVariability]?.score, 0.72)
    }
}
