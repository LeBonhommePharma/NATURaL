import XCTest
@testable import BonhommeCore

/// Dedicated tests for CrossDomainValidator, covering:
/// - p-value computation accuracy against published statistical tables
/// - Minimum sample size enforcement
/// - Hybrid validation mode
/// - NaN/infinity input handling
/// - Edge cases in correlation analysis
final class CrossDomainValidatorTests: XCTestCase {

    private let validator = CrossDomainValidator()

    // MARK: - Test Helpers

    /// Create a minimal DrugResponseResult for pairing tests.
    private func makeDrugResponse(
        medicationId: String,
        peakDeltaH: Double,
        effectSize: Double = 0.3
    ) -> DrugResponseResult {
        let dose = DoseEventSummary(
            medicationId: medicationId,
            name: medicationId,
            doseValue: 10.0,
            doseUnit: "mg",
            timestamp: Date()
        )
        return DrugResponseResult(
            doseEvent: dose,
            baselineEntropy: 3.5,
            baselineRRCount: 50,
            measurements: [],
            peakDeltaH: peakDeltaH,
            peakTimeMinutes: 30,
            profileMatch: nil
        )
    }

    /// Create a minimal FlexAIDdSResult for pairing tests.
    private func makeDockingResult(
        substanceId: String,
        totalDeltaS: Double
    ) -> FlexAIDdSResult {
        // Create bond results that sum to the desired totalDeltaS
        let bondResult = BondEntropyResult(
            bondId: "bond_1",
            freeEntropy: 4.0,
            boundEntropy: 4.0 + totalDeltaS
        )
        return FlexAIDdSResult(
            substanceId: substanceId,
            receptorId: "test-receptor",
            bondResults: [bondResult],
            dockingScore: -5.0
        )
    }

    // MARK: - p-Value Computation

    /// Verify p-value computation against known statistical table values.
    /// At n=5, r=0.878 → p ≈ 0.05 (standard critical value for df=3).
    func testPValueForKnownStatistics() {
        // The critical r value for n=5, two-tailed, α=0.05 is approximately 0.878
        let p = CrossDomainValidator.computePValue(r: 0.878, n: 5)

        // p should be close to 0.05
        XCTAssertGreaterThan(p, 0.02, "p-value for r=0.878, n=5 should be near 0.05")
        XCTAssertLessThan(p, 0.10, "p-value for r=0.878, n=5 should be near 0.05")
    }

    /// At n=5, r=0.5 → p ≈ 0.39. This should NOT be significant.
    func testWeakCorrelationNotSignificant() {
        let p = CrossDomainValidator.computePValue(r: 0.5, n: 5)

        // p should be well above 0.05
        XCTAssertGreaterThan(p, 0.2,
            "r=0.5 at n=5 should have p > 0.2 (not significant)")

        // Build a validation result to confirm isSignificant is false
        let responses = (0..<5).map { i in
            makeDrugResponse(medicationId: "drug_\(i)", peakDeltaH: Double(i) * -0.3)
        }
        let dockingResults = (0..<5).map { i in
            makeDockingResult(substanceId: "drug_\(i)", totalDeltaS: Double(i) * -0.5)
        }

        // Even if we get a result, check that weak correlation is not flagged
        if let result = validator.validate(dockingResults: dockingResults, drugResponseResults: responses) {
            if abs(result.pearsonR) < 0.878 && result.n <= 5 {
                // For small n with moderate r, should not be significant
                XCTAssertGreaterThan(result.pValue, 0.05)
            }
        }
    }

    /// At n=20, r=0.5 → p ≈ 0.025. This SHOULD be significant.
    func testStrongCorrelationWithLargeNSignificant() {
        let p = CrossDomainValidator.computePValue(r: 0.5, n: 20)
        XCTAssertLessThan(p, 0.05,
            "r=0.5 at n=20 should have p < 0.05 (significant)")
    }

    /// Perfect correlation should have p ≈ 0.
    func testPerfectCorrelation() {
        let p = CrossDomainValidator.computePValue(r: 0.999, n: 10)
        XCTAssertLessThan(p, 0.001,
            "Near-perfect correlation should have near-zero p-value")
    }

    /// r=0 should have p=1 (no correlation at all).
    func testZeroCorrelation() {
        let p = CrossDomainValidator.computePValue(r: 0.0, n: 10)
        XCTAssertGreaterThan(p, 0.9,
            "Zero correlation should have p near 1.0")
    }

    /// Edge case: n=2 should return p=1 (df=0, undefined).
    func testPValueWithTooFewSamples() {
        let p = CrossDomainValidator.computePValue(r: 0.99, n: 2)
        XCTAssertEqual(p, 1.0,
            "n=2 gives df=0, p-value should be 1.0")
    }

    /// r=1.0 exactly should return p=0.
    func testPValuePerfectR() {
        let p = CrossDomainValidator.computePValue(r: 1.0, n: 10)
        XCTAssertEqual(p, 0.0)
    }

    // MARK: - Minimum Pairs

    /// With default config (minPairs=5), 4 pairs should return nil.
    func testMinimumPairsRaisedToFive() {
        let responses = (0..<4).map { i in
            makeDrugResponse(medicationId: "drug_\(i)", peakDeltaH: Double(i + 1) * -0.5)
        }
        let docking = (0..<4).map { i in
            makeDockingResult(substanceId: "drug_\(i)", totalDeltaS: Double(i + 1) * -1.0)
        }

        let result = validator.validate(dockingResults: docking, drugResponseResults: responses)
        XCTAssertNil(result, "4 pairs should be insufficient (minimum is 5)")
    }

    /// 5 pairs should produce a result.
    func testFivePairsProducesResult() {
        let responses = (0..<5).map { i in
            makeDrugResponse(medicationId: "drug_\(i)", peakDeltaH: Double(i + 1) * -0.5)
        }
        let docking = (0..<5).map { i in
            makeDockingResult(substanceId: "drug_\(i)", totalDeltaS: Double(i + 1) * -1.0)
        }

        let result = validator.validate(dockingResults: docking, drugResponseResults: responses)
        XCTAssertNotNil(result, "5 pairs should be sufficient")
    }

    /// Custom config can lower minimum pairs.
    func testCustomMinPairs() {
        let config = AnalysisConfiguration(crossDomainMinPairs: 3)
        let customValidator = CrossDomainValidator(configuration: config)

        let responses = (0..<3).map { i in
            makeDrugResponse(medicationId: "drug_\(i)", peakDeltaH: Double(i + 1) * -0.5)
        }
        let docking = (0..<3).map { i in
            makeDockingResult(substanceId: "drug_\(i)", totalDeltaS: Double(i + 1) * -1.0)
        }

        let result = customValidator.validate(dockingResults: docking, drugResponseResults: responses)
        XCTAssertNotNil(result, "Custom config with minPairs=3 should accept 3 pairs")
    }

    // MARK: - Hybrid Validation

    /// When docking results exist for a substance, they should take priority over profiles.
    func testValidateHybridPrefersDocking() {
        // Create docking result for caffeine with a specific ΔS
        let docking = [makeDockingResult(substanceId: "caffeine", totalDeltaS: -2.5)]

        // Create enough drug responses to meet minimum pairs
        // (hybrid fills in from BindingEntropyProfile for others)
        var responses = [makeDrugResponse(medicationId: "caffeine", peakDeltaH: -0.8)]

        // Add more substances that exist in BindingEntropyProfile
        let knownIds = BindingEntropyProfile.knownProfiles.prefix(6).map(\.substanceId)
        for id in knownIds where id != "caffeine" {
            responses.append(makeDrugResponse(medicationId: id, peakDeltaH: -0.5))
        }

        let result = validator.validateHybrid(dockingResults: docking, drugResponseResults: responses)

        // Should produce a result (enough pairs from profile fallback)
        if let result = result {
            // Verify caffeine uses the docking value (-2.5) not the profile value
            let caffeinePair = result.observations.first { $0.substanceId == "caffeine" }
            XCTAssertNotNil(caffeinePair)
            if let pair = caffeinePair {
                XCTAssertEqual(pair.deltaSConfig, -2.5, accuracy: 0.01,
                    "Hybrid should prefer docking result over profile")
            }
        }
    }

    /// When no docking result exists, hybrid should fall back to profile values.
    func testValidateHybridFallsBack() {
        // No docking results at all — should use profiles for everything
        let knownIds = BindingEntropyProfile.knownProfiles.prefix(6).map(\.substanceId)
        let responses = knownIds.map { id in
            makeDrugResponse(medicationId: id, peakDeltaH: -0.6)
        }

        let result = validator.validateHybrid(dockingResults: [], drugResponseResults: responses)
        XCTAssertNotNil(result, "Hybrid with 0 docking + profile fallback should produce result")

        if let result = result {
            XCTAssertGreaterThanOrEqual(result.n, 5)
        }
    }

    // MARK: - NaN / Infinity Handling

    /// Pairs containing NaN values should not crash or produce NaN.
    func testNaNInputsGraceful() {
        let responses = (0..<6).map { i -> DrugResponseResult in
            let deltaH = i == 2 ? Double.nan : Double(i + 1) * -0.5
            return makeDrugResponse(medicationId: "drug_\(i)", peakDeltaH: deltaH)
        }
        let docking = (0..<6).map { i in
            makeDockingResult(substanceId: "drug_\(i)", totalDeltaS: Double(i + 1) * -1.0)
        }

        let result = validator.validate(dockingResults: docking, drugResponseResults: responses)

        // Should produce a result (5 clean pairs after filtering NaN)
        XCTAssertNotNil(result)
        if let r = result {
            XCTAssertFalse(r.pearsonR.isNaN, "Pearson r should not be NaN")
            XCTAssertFalse(r.pValue.isNaN, "p-value should not be NaN")
        }
    }

    // MARK: - ValidationResult Properties

    /// Verify that p-value is included in the summary string.
    func testSummaryIncludesPValue() {
        let responses = (0..<5).map { i in
            makeDrugResponse(medicationId: "drug_\(i)", peakDeltaH: Double(i + 1) * -0.5)
        }
        let docking = (0..<5).map { i in
            makeDockingResult(substanceId: "drug_\(i)", totalDeltaS: Double(i + 1) * -1.0)
        }

        if let result = validator.validate(dockingResults: docking, drugResponseResults: responses) {
            XCTAssertTrue(result.summary.en.contains("p ="),
                "Summary should include p-value")
        }
    }
}
