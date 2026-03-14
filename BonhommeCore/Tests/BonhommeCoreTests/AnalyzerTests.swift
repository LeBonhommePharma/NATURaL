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

        // Uniform distribution: maximum entropy
        let uniform = Array(stride(from: 700.0, through: 900.0, by: 1.0))
        let highEntropy = analyzer.shannonEntropy(uniform)
        XCTAssertGreaterThan(highEntropy, 2.0, "Uniform RR intervals should have high entropy")

        // Nearly constant: minimum entropy
        let constant = Array(repeating: 800.0, count: 100) + [801.0]
        let lowEntropy = analyzer.shannonEntropy(constant)
        XCTAssertLessThan(lowEntropy, 1.0, "Constant RR intervals should have near-zero entropy")
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

        // Zero entropy → score 1.0 (maximally coherent)
        XCTAssertEqual(calc.entropyToScore(0), 1.0)

        // Max entropy (8 bits) → score 0.0
        XCTAssertEqual(calc.entropyToScore(8.0), 0.0)

        // Mid-range
        XCTAssertEqual(calc.entropyToScore(4.0), 0.5, accuracy: 0.001)

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
        // Verify that HRVAnalyzer's delegated entropy matches EntropyCalculator
        let binCount = 8
        let calc = EntropyCalculator(binCount: binCount)
        let analyzer = HRVAnalyzer(binCount: binCount)

        let values = Array(stride(from: 700.0, through: 900.0, by: 1.0))
        let calcEntropy = calc.shannonEntropy(values)
        let analyzerEntropy = analyzer.shannonEntropy(values)

        XCTAssertEqual(calcEntropy, analyzerEntropy, accuracy: 0.0001,
                       "EntropyCalculator and HRVAnalyzer should produce identical results")
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
