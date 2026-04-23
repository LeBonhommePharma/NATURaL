import XCTest
@testable import BonhommeCore

final class SelectivityEntropyAnalyzerTests: XCTestCase {

    // MARK: - Single Target

    func testSingleTargetEntropyIsZero() {
        // Salvinorin A has only 1 target (KOR) → H = 0
        let result = SelectivityEntropyAnalyzer.analyze(substanceId: "salvinorin-a")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.targetCount, 1)
        XCTAssertEqual(result?.selectivityEntropy ?? -1, 0.0, accuracy: 1e-10,
            "Single-target substance should have zero entropy")
    }

    func testSalvinorinAMaxSelectivity() {
        let result = SelectivityEntropyAnalyzer.analyze(substanceId: "salvinorin-a")!
        XCTAssertEqual(result.normalizedSelectivity, 1.0, accuracy: 1e-10,
            "Single target → normalized selectivity = 1.0")
        XCTAssertEqual(result.derivedSpecialAttack, 5,
            "Normalized selectivity 1.0 → 5 stars")
        XCTAssertEqual(result.dominantTargetId, "KOR")
    }

    // MARK: - Multi-Target

    func testIbogaineMinSelectivity() {
        // Ibogaine has 6 targets → high entropy → low selectivity
        let result = SelectivityEntropyAnalyzer.analyze(substanceId: "ibogaine")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.targetCount, 6)
        XCTAssertEqual(result?.derivedSpecialAttack, 1,
            "Ibogaine (6 targets, relatively even) should have derived Sp.Atk = 1")
    }

    func testLSDSelectivity() {
        // LSD has 3 targets with 5-HT2A as primary
        let result = SelectivityEntropyAnalyzer.analyze(substanceId: "lsd")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.targetCount, 3)
        XCTAssertEqual(result?.dominantTargetId, "5-HT2A")
        XCTAssertGreaterThan(result!.selectivityEntropy, 0,
            "Multi-target substance should have positive entropy")
    }

    // MARK: - Range Validation

    func testNormalizedSelectivityRange() {
        let results = SelectivityEntropyAnalyzer.analyzeAll()
        XCTAssertFalse(results.isEmpty, "Should have results for substances with thermodynamic profiles")

        for result in results {
            XCTAssertGreaterThanOrEqual(result.normalizedSelectivity, 0.0,
                "\(result.substanceId) normalized selectivity should be >= 0")
            XCTAssertLessThanOrEqual(result.normalizedSelectivity, 1.0,
                "\(result.substanceId) normalized selectivity should be <= 1")
            XCTAssertGreaterThanOrEqual(result.derivedSpecialAttack, 1)
            XCTAssertLessThanOrEqual(result.derivedSpecialAttack, 5)
        }
    }

    func testEntropyNonNegative() {
        for result in SelectivityEntropyAnalyzer.analyzeAll() {
            XCTAssertGreaterThanOrEqual(result.selectivityEntropy, 0,
                "\(result.substanceId) entropy should be non-negative")
        }
    }

    // MARK: - Comparison with PokeDrug Stats

    func testComparisonWithExistingStats() {
        let comparisons = SelectivityEntropyAnalyzer.compareWithPokeDrugStats()
        XCTAssertFalse(comparisons.isEmpty,
            "Should have comparisons for PokeDrug species with thermodynamic profiles")

        for comp in comparisons {
            XCTAssertGreaterThanOrEqual(comp.informationTheoretic, 1)
            XCTAssertLessThanOrEqual(comp.informationTheoretic, 5)
            XCTAssertGreaterThanOrEqual(comp.existing, 1)
            XCTAssertLessThanOrEqual(comp.existing, 5)
        }
    }

    // MARK: - Two Equal Targets

    func testTwoEqualTargetsMaxEntropy() {
        // If a substance has exactly 2 targets with equal pKi, H = log2(2) = 1 bit
        // We can check morphine (3 targets) has entropy < log2(3) = 1.585 bits
        let result = SelectivityEntropyAnalyzer.analyze(substanceId: "morphine")
        XCTAssertNotNil(result)
        if let r = result {
            XCTAssertLessThanOrEqual(r.selectivityEntropy, r.maxPossibleEntropy,
                "Entropy should not exceed max possible")
        }
    }

    // MARK: - Unknown Substance

    func testUnknownSubstanceReturnsNil() {
        let result = SelectivityEntropyAnalyzer.analyze(substanceId: "nonexistent-substance")
        XCTAssertNil(result)
    }
}
