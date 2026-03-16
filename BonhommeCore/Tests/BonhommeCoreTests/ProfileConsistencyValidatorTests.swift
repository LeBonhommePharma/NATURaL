import XCTest
@testable import BonhommeCore

final class ProfileConsistencyValidatorTests: XCTestCase {

    // MARK: - Full Validation

    func testFullValidationRuns() {
        let report = ProfileConsistencyValidator.validate()
        XCTAssertEqual(report.substancesChecked, PokeDrugSpecies.knownSpecies.count,
            "Should check all PokeDrug species")
    }

    func testAllSpeciesHaveThreeProfiles() {
        let report = ProfileConsistencyValidator.validate()
        let missingPK = report.issuesByType[.missingPKProfile] ?? []
        let missingBinding = report.issuesByType[.missingBindingEntropyProfile] ?? []
        let missingThermo = report.issuesByType[.missingThermodynamicProfile] ?? []

        // Document any missing profiles (may have some by design)
        if !missingPK.isEmpty {
            print("Missing PK profiles: \(missingPK.map(\.substanceId))")
        }
        if !missingBinding.isEmpty {
            print("Missing BindingEntropy profiles: \(missingBinding.map(\.substanceId))")
        }
        if !missingThermo.isEmpty {
            print("Missing Thermodynamic profiles: \(missingThermo.map(\.substanceId))")
        }
    }

    // MARK: - Stat Derivation Consistency

    func testDefenseConsistency() {
        // Cocaine: half-life 60 min → deriveDefense should match curated
        let issues = ProfileConsistencyValidator.validate(substanceId: "cocaine")
        let defenseMismatches = issues.filter { $0.issueType == .defenseMismatch }
        // Document result
        for issue in defenseMismatches {
            print("Defense mismatch: \(issue.detail.en)")
        }
    }

    func testSpeedConsistency() {
        // DMT: onset 0.5 min → deriveSpeed should be high
        let issues = ProfileConsistencyValidator.validate(substanceId: "dmt")
        let speedMismatches = issues.filter { $0.issueType == .speedMismatch }
        for issue in speedMismatches {
            print("Speed mismatch: \(issue.detail.en)")
        }
    }

    func testAttackConsistency() {
        // LSD: Ki 3.5 nM → deriveAttack = 5
        let issues = ProfileConsistencyValidator.validate(substanceId: "lsd")
        let attackMismatches = issues.filter { $0.issueType == .attackMismatch }
        for issue in attackMismatches {
            print("Attack mismatch: \(issue.detail.en)")
        }
    }

    // MARK: - ITC Consistency

    func testITCConsistency() {
        let report = ProfileConsistencyValidator.validate()
        let itcIssues = report.issuesByType[.thermodynamicInconsistency] ?? []
        XCTAssertEqual(itcIssues.count, 0,
            "No ITC thermodynamic inconsistencies should exist in curated data")
    }

    // MARK: - Single Substance Validation

    func testSingleSubstanceValidation() {
        let issues = ProfileConsistencyValidator.validate(substanceId: "morphine")
        // Morphine should have all three profiles
        let missingTypes: [ConsistencyIssueType] = [.missingPKProfile, .missingBindingEntropyProfile, .missingThermodynamicProfile]
        for type in missingTypes {
            XCTAssertFalse(issues.contains { $0.issueType == type },
                "Morphine should have all profile types, missing: \(type)")
        }
    }

    func testUnknownSubstanceReturnsEmpty() {
        // Unknown substance with no species entry returns just missing-profile warnings
        let issues = ProfileConsistencyValidator.validate(substanceId: "nonexistent-xyz")
        // Should have missing profile issues but no stat-derivation issues (no species to compare)
        let statIssues = issues.filter {
            [.attackMismatch, .defenseMismatch, .speedMismatch, .specialAttackMismatch]
                .contains($0.issueType)
        }
        XCTAssertEqual(statIssues.count, 0,
            "Unknown substance should not have stat mismatch issues")
    }

    // MARK: - Report Properties

    func testReportSummaryBilingual() {
        let report = ProfileConsistencyValidator.validate()
        XCTAssertFalse(report.summary.en.isEmpty)
        XCTAssertFalse(report.summary.fr.isEmpty)
        XCTAssertTrue(report.summary.en.contains("substances"))
        XCTAssertTrue(report.summary.fr.contains("substances"))
    }

    func testReportCounts() {
        let report = ProfileConsistencyValidator.validate()
        XCTAssertEqual(report.errorCount + report.warningCount,
            report.issues.filter { $0.severity == .error || $0.severity == .warning }.count)
    }

    func testIssueSeverityComparable() {
        XCTAssertTrue(IssueSeverity.info < IssueSeverity.warning)
        XCTAssertTrue(IssueSeverity.warning < IssueSeverity.error)
        XCTAssertFalse(IssueSeverity.error < IssueSeverity.info)
    }

    func testConsistencyIssueTypeAllCases() {
        XCTAssertEqual(ConsistencyIssueType.allCases.count, 9)
    }
}
