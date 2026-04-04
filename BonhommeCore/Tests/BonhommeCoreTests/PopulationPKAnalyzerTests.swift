import XCTest
@testable import BonhommeCore

final class PopulationPKAnalyzerTests: XCTestCase {

    // MARK: - Helpers

    private func makeDoseEvent(medicationId: String) -> DoseEventSummary {
        DoseEventSummary(
            medicationId: medicationId,
            name: medicationId,
            doseValue: 10.0,
            doseUnit: "mg",
            timestamp: Date()
        )
    }

    private func makeMeasurement(minutesAfter: Double, entropy: Double) -> EntropyMeasurement {
        EntropyMeasurement(
            timestamp: Date().addingTimeInterval(minutesAfter * 60),
            entropy: entropy,
            rrIntervalCount: 100
        )
    }

    private func makeResult(medicationId: String, peakDeltaH: Double, peakTime: Double,
                            baseline: Double = 3.5, measurements: [EntropyMeasurement]? = nil) -> DrugResponseResult {
        let dose = makeDoseEvent(medicationId: medicationId)
        let defaultMeasurements = measurements ?? [
            makeMeasurement(minutesAfter: 0, entropy: baseline),
            makeMeasurement(minutesAfter: peakTime, entropy: baseline + peakDeltaH),
            makeMeasurement(minutesAfter: peakTime * 2, entropy: baseline + peakDeltaH * 0.5),
            makeMeasurement(minutesAfter: peakTime * 3, entropy: baseline)
        ]
        return DrugResponseResult(
            doseEvent: dose,
            baselineEntropy: baseline,
            baselineRRCount: 100,
            measurements: defaultMeasurements,
            peakDeltaH: peakDeltaH,
            peakTimeMinutes: peakTime,
            profileMatch: nil
        )
    }

    // MARK: - Minimum Sample Size

    func testMinimumSampleSize() {
        let single = [makeResult(medicationId: "caffeine", peakDeltaH: 0.5, peakTime: 30)]
        XCTAssertNil(PopulationPKAnalyzer.analyze(results: single),
            "Should return nil for fewer than 2 results")
    }

    func testEmptyReturnsNil() {
        XCTAssertNil(PopulationPKAnalyzer.analyze(results: []))
    }

    // MARK: - CV Computation

    func testCVComputation() {
        let results = [
            makeResult(medicationId: "caffeine", peakDeltaH: 0.4, peakTime: 30),
            makeResult(medicationId: "caffeine", peakDeltaH: 0.5, peakTime: 35),
            makeResult(medicationId: "caffeine", peakDeltaH: 0.6, peakTime: 25),
            makeResult(medicationId: "caffeine", peakDeltaH: 0.5, peakTime: 30),
        ]

        let analysis = PopulationPKAnalyzer.analyze(results: results)
        XCTAssertNotNil(analysis)
        XCTAssertEqual(analysis!.n, 4)
        XCTAssertGreaterThan(analysis!.cvPeakDeltaH, 0, "CV should be positive for varying data")
        XCTAssertEqual(analysis!.meanPeakDeltaH, 0.5, accuracy: 0.01)
    }

    // MARK: - Outlier Detection

    func testOutlierDetectionZScore() {
        // Create a population with one extreme outlier
        var results: [DrugResponseResult] = []
        for _ in 0..<10 {
            results.append(makeResult(medicationId: "caffeine", peakDeltaH: 0.5, peakTime: 30))
        }
        // Add an outlier (much higher peak)
        results.append(makeResult(medicationId: "caffeine", peakDeltaH: 2.0, peakTime: 30))

        let analysis = PopulationPKAnalyzer.analyze(results: results)
        XCTAssertNotNil(analysis)
        let peakOutliers = analysis!.outliers.filter { $0.metric == .peakDeltaH }
        XCTAssertGreaterThanOrEqual(peakOutliers.count, 1,
            "Should flag the extreme peak value as outlier")

        for outlier in peakOutliers {
            XCTAssertGreaterThan(abs(outlier.zScore), 2.0)
        }
    }

    // MARK: - CYP2D6 Annotation

    func testCYP2D6AnnotationForCodeine() {
        // Codeine is a prodrug (CYP2D6 → morphine)
        var results: [DrugResponseResult] = []
        for _ in 0..<10 {
            results.append(makeResult(medicationId: "codeine", peakDeltaH: 0.5, peakTime: 45))
        }
        // Poor metabolizer: very low response
        results.append(makeResult(medicationId: "codeine", peakDeltaH: 0.05, peakTime: 45))

        let analysis = PopulationPKAnalyzer.analyze(results: results)
        XCTAssertNotNil(analysis)

        let codeineOutliers = analysis!.outliers.filter { $0.metric == .peakDeltaH }
        let hasExplanation = codeineOutliers.contains { $0.possibleExplanation != nil }
        XCTAssertTrue(hasExplanation,
            "Codeine (prodrug) outliers should have CYP2D6 explanation")
    }

    func testNonProdrugNoMetabolizerAnnotation() {
        var results: [DrugResponseResult] = []
        for _ in 0..<10 {
            results.append(makeResult(medicationId: "caffeine", peakDeltaH: 0.5, peakTime: 30))
        }
        results.append(makeResult(medicationId: "caffeine", peakDeltaH: 2.0, peakTime: 30))

        let analysis = PopulationPKAnalyzer.analyze(results: results)
        XCTAssertNotNil(analysis)

        let caffeineOutliers = analysis!.outliers.filter { $0.metric == .peakDeltaH }
        let hasExplanation = caffeineOutliers.contains { $0.possibleExplanation != nil }
        XCTAssertFalse(hasExplanation,
            "Non-prodrug outliers should not have metabolizer explanation")
    }

    // MARK: - Metabolizer Phenotype Detection

    func testMetabolizerPhenotypeDetection() {
        let poorResult = makeResult(medicationId: "codeine", peakDeltaH: 0.05, peakTime: 45)
        let phenotype = PopulationPKAnalyzer.detectMetabolizerPhenotype(
            result: poorResult, populationMean: 0.5, populationSD: 0.1)
        XCTAssertEqual(phenotype, .poorMetabolizer)

        let ultraResult = makeResult(medicationId: "codeine", peakDeltaH: 1.2, peakTime: 45)
        let ultraPhenotype = PopulationPKAnalyzer.detectMetabolizerPhenotype(
            result: ultraResult, populationMean: 0.5, populationSD: 0.1)
        XCTAssertEqual(ultraPhenotype, .ultraRapidMetabolizer)

        let normalResult = makeResult(medicationId: "codeine", peakDeltaH: 0.5, peakTime: 45)
        let normalPhenotype = PopulationPKAnalyzer.detectMetabolizerPhenotype(
            result: normalResult, populationMean: 0.5, populationSD: 0.1)
        XCTAssertEqual(normalPhenotype, .normalMetabolizer)
    }

    func testNonProdrugMetabolizerReturnsNil() {
        let result = makeResult(medicationId: "caffeine", peakDeltaH: 0.05, peakTime: 30)
        let phenotype = PopulationPKAnalyzer.detectMetabolizerPhenotype(
            result: result, populationMean: 0.5, populationSD: 0.1)
        XCTAssertNil(phenotype, "Non-prodrug should not get metabolizer phenotype")
    }

    // MARK: - High Variability Flag

    func testHighVariabilityFlag() {
        // Create high-variability population (CV > 40%)
        let results = [
            makeResult(medicationId: "caffeine", peakDeltaH: 0.1, peakTime: 30),
            makeResult(medicationId: "caffeine", peakDeltaH: 1.0, peakTime: 30),
            makeResult(medicationId: "caffeine", peakDeltaH: 0.2, peakTime: 30),
            makeResult(medicationId: "caffeine", peakDeltaH: 0.9, peakTime: 30),
        ]
        let analysis = PopulationPKAnalyzer.analyze(results: results)
        XCTAssertNotNil(analysis)
        XCTAssertTrue(analysis!.isHighVariability, "Wide spread data should flag high variability")
    }

    // MARK: - All Results Must Share Substance

    func testAllResultsMustShareSubstance() {
        let results = [
            makeResult(medicationId: "caffeine", peakDeltaH: 0.5, peakTime: 30),
            makeResult(medicationId: "morphine", peakDeltaH: 0.5, peakTime: 30),
        ]
        XCTAssertNil(PopulationPKAnalyzer.analyze(results: results),
            "Mismatched medication IDs should return nil")
    }

    // MARK: - Population Comparison

    func testPopulationComparison() {
        let groupA = [
            makeResult(medicationId: "codeine", peakDeltaH: 0.5, peakTime: 45),
            makeResult(medicationId: "codeine", peakDeltaH: 0.6, peakTime: 40),
            makeResult(medicationId: "codeine", peakDeltaH: 0.4, peakTime: 50),
        ]
        let groupB = [
            makeResult(medicationId: "codeine", peakDeltaH: 0.1, peakTime: 60),
            makeResult(medicationId: "codeine", peakDeltaH: 0.15, peakTime: 55),
            makeResult(medicationId: "codeine", peakDeltaH: 0.05, peakTime: 65),
        ]

        let comparison = PopulationPKAnalyzer.comparePopulations(groupA: groupA, groupB: groupB)
        XCTAssertNotNil(comparison)
        XCTAssertGreaterThan(comparison!.meanDeltaHDifference, 0,
            "Group A (normal) should have higher mean peak ΔH than Group B (poor)")
        XCTAssertGreaterThan(abs(comparison!.cohensD), 0,
            "Cohen's d should be non-zero for different populations")
    }

    // MARK: - Summary

    func testSummaryBilingual() {
        let results = [
            makeResult(medicationId: "caffeine", peakDeltaH: 0.5, peakTime: 30),
            makeResult(medicationId: "caffeine", peakDeltaH: 0.6, peakTime: 35),
        ]
        let analysis = PopulationPKAnalyzer.analyze(results: results)
        XCTAssertNotNil(analysis)
        XCTAssertFalse(analysis!.summary.en.isEmpty)
        XCTAssertFalse(analysis!.summary.fr.isEmpty)
        XCTAssertTrue(analysis!.summary.en.contains("CV"))
    }
}
