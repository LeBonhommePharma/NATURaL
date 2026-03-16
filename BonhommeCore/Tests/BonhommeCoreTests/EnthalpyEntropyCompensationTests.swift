import XCTest
@testable import BonhommeCore

final class EnthalpyEntropyCompensationTests: XCTestCase {

    // MARK: - Minimum Data Count

    func testMinimumDataCount() {
        // Analyzing with insufficient ITC data should return nil
        let result = EnthalpyEntropyCompensation.analyze(substanceIds: ["caffeine"])
        XCTAssertNil(result, "Should return nil for fewer than 4 ITC-profiled substances")
    }

    // MARK: - Full Analysis

    func testFullAnalysisReturnsResult() {
        let result = EnthalpyEntropyCompensation.analyze()
        // We have 10 ITC-profiled substances, so this should succeed
        XCTAssertNotNil(result, "Should return result with ≥4 ITC-profiled substances")
        if let r = result {
            XCTAssertGreaterThanOrEqual(r.n, 4)
        }
    }

    func testCompensationSlopeNegative() {
        // Enthalpy-entropy compensation typically has negative slope
        // (more favorable ΔH → less favorable -TΔS)
        guard let result = EnthalpyEntropyCompensation.analyze() else {
            XCTFail("Analysis should return a result"); return
        }
        XCTAssertLessThan(result.slope, 0,
            "Compensation slope should be negative (enthalpy-entropy trade-off)")
    }

    // MARK: - R² Range

    func testRSquaredRange() {
        guard let result = EnthalpyEntropyCompensation.analyze() else {
            XCTFail("Analysis should return a result"); return
        }
        XCTAssertGreaterThanOrEqual(result.rSquared, 0.0, "R² should be non-negative")
        XCTAssertLessThanOrEqual(result.rSquared, 1.0, "R² should be ≤ 1.0")
    }

    func testPearsonRRange() {
        guard let result = EnthalpyEntropyCompensation.analyze() else {
            XCTFail("Analysis should return a result"); return
        }
        XCTAssertGreaterThanOrEqual(result.pearsonR, -1.0)
        XCTAssertLessThanOrEqual(result.pearsonR, 1.0)
        // R² should equal pearsonR²
        XCTAssertEqual(result.rSquared, result.pearsonR * result.pearsonR, accuracy: 1e-10)
    }

    // MARK: - Self-Consistency

    func testSelfConsistencyWithDeltaG() {
        // For each data point: ΔG ≈ ΔH + (-TΔS)
        guard let result = EnthalpyEntropyCompensation.analyze() else {
            XCTFail("Analysis should return a result"); return
        }
        for dp in result.dataPoints {
            let sum = dp.deltaHKcal + dp.minusTDeltaSKcal
            XCTAssertEqual(dp.deltaGKcal, sum, accuracy: 0.5,
                "\(dp.substanceId):\(dp.targetId) ΔG should ≈ ΔH + (-TΔS)")
        }
    }

    // MARK: - Outlier Detection

    func testOutlierDetection() {
        guard let result = EnthalpyEntropyCompensation.analyze() else {
            XCTFail("Analysis should return a result"); return
        }
        // Outliers should be a subset of data points
        XCTAssertLessThanOrEqual(result.outliers.count, result.n)

        // Each outlier should be in the data points
        let dpIds = Set(result.dataPoints.map { "\($0.substanceId):\($0.targetId)" })
        for outlier in result.outliers {
            XCTAssertTrue(dpIds.contains("\(outlier.substanceId):\(outlier.targetId)"),
                "Outlier \(outlier.substanceId) should be in data points")
        }
    }

    // MARK: - Subset Analysis

    func testSubsetAnalysis() {
        // Use a known subset of ITC substances
        let subset = ["lsd", "morphine", "fentanyl", "cocaine", "thc", "caffeine"]
        let result = EnthalpyEntropyCompensation.analyze(substanceIds: subset)
        XCTAssertNotNil(result, "Should analyze subset of ITC substances")
        if let r = result {
            XCTAssertLessThanOrEqual(r.n, subset.count)
        }
    }

    // MARK: - Compensation Type

    func testCompensationTypeValues() {
        guard let result = EnthalpyEntropyCompensation.analyze() else {
            XCTFail("Analysis should return a result"); return
        }
        // Just verify it returns a valid type
        let validTypes: [CompensationType] = [.full, .partial, .none]
        XCTAssertTrue(validTypes.contains(result.compensationType))
    }

    // MARK: - Flag Outliers

    func testFlagInterestingOutliers() {
        let outliers = EnthalpyEntropyCompensation.flagInterestingOutliers()
        // Should not crash; outliers may be empty
        XCTAssertGreaterThanOrEqual(outliers.count, 0)
    }

    // MARK: - Summary

    func testSummaryBilingual() {
        guard let result = EnthalpyEntropyCompensation.analyze() else {
            XCTFail("Analysis should return a result"); return
        }
        XCTAssertFalse(result.summary.en.isEmpty)
        XCTAssertFalse(result.summary.fr.isEmpty)
        XCTAssertTrue(result.summary.en.contains("R²"))
    }
}
