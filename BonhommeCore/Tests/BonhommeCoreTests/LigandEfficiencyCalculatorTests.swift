import XCTest
@testable import BonhommeCore

final class LigandEfficiencyCalculatorTests: XCTestCase {

    // MARK: - Catalog Integrity

    func testAllPokeDrugSubstancesHaveDescriptors() {
        for species in PokeDrugSpecies.knownSpecies {
            XCTAssertNotNil(
                MolecularDescriptor.descriptor(for: species.substanceId),
                "\(species.substanceId) should have a MolecularDescriptor"
            )
        }
    }

    func testDescriptorCount() {
        XCTAssertGreaterThanOrEqual(
            MolecularDescriptor.knownDescriptors.count, 80,
            "Should have descriptors for all ~85 PK substances"
        )
    }

    // MARK: - Cross-Check with BindingEntropyProfile

    func testRotatableBondConsistencyWithBindingEntropy() {
        for descriptor in MolecularDescriptor.knownDescriptors {
            guard let beProfile = BindingEntropyProfile.profile(for: descriptor.substanceId) else { continue }
            XCTAssertEqual(
                descriptor.rotatableBondCount, beProfile.rotatableBondCount,
                "\(descriptor.substanceId) rotatableBondCount mismatch: MolecularDescriptor=\(descriptor.rotatableBondCount), BindingEntropyProfile=\(beProfile.rotatableBondCount)"
            )
        }
    }

    // MARK: - Ligand Efficiency Calculations

    func testLigandEfficiencyPositive() {
        let ranked = LigandEfficiencyCalculator.rankByLE()
        XCTAssertFalse(ranked.isEmpty, "Should have LE results for substances with both descriptors and profiles")

        for result in ranked {
            if let le = result.le {
                XCTAssertGreaterThan(le, 0, "\(result.substanceId) LE should be positive (binding is favorable)")
            }
        }
    }

    func testBEIRanking() {
        let ranked = LigandEfficiencyCalculator.rankByLE()
        // LSD and fentanyl should have high pKi (tight binding)
        let lsd = ranked.first { $0.substanceId == "lsd" }
        let caffeine = ranked.first { $0.substanceId == "caffeine" }

        if let lsdPKi = lsd?.pKi, let caffeinePKi = caffeine?.pKi {
            XCTAssertGreaterThan(lsdPKi, caffeinePKi,
                "LSD (Ki ~3.5 nM, pKi ~8.5) should have higher pKi than caffeine (Ki ~2400 nM, pKi ~5.6)")
        }
    }

    func testLipEComputation() {
        // LSD: pKi = 9 - log10(3.5) = 8.46, cLogP = 2.95 → LipE ≈ 5.5
        let result = LigandEfficiencyCalculator.calculate(substanceId: "lsd", targetId: "5-HT2A")
        XCTAssertNotNil(result)
        if let lipE = result?.lipE {
            XCTAssertEqual(lipE, 5.5, accuracy: 0.5,
                "LSD LipE should be ~5.5 (pKi ~8.46 - cLogP 2.95)")
        }
        if let pKi = result?.pKi {
            XCTAssertEqual(pKi, 8.46, accuracy: 0.1)
        }
    }

    // MARK: - Drug-Likeness

    func testLipinskiCompliance() {
        // THC violates cLogP (6.97 > 5)
        let thc = MolecularDescriptor.descriptor(for: "thc")!
        XCTAssertFalse(thc.isLipinskiCompliant, "THC should violate Lipinski (cLogP > 5)")
        XCTAssertTrue(thc.drugLikenessViolations.contains(.cLogPExceeds5))

        // Dronabinol = same molecule as THC
        let dronabinol = MolecularDescriptor.descriptor(for: "dronabinol")!
        XCTAssertFalse(dronabinol.isLipinskiCompliant)

        // Caffeine should be compliant
        let caffeine = MolecularDescriptor.descriptor(for: "caffeine")!
        XCTAssertTrue(caffeine.isLipinskiCompliant, "Caffeine should pass Lipinski")
    }

    func testVeberCompliance() {
        // Digoxin: PSA 203.1 > 140 → violates Veber
        let digoxin = MolecularDescriptor.descriptor(for: "digoxin")!
        XCTAssertFalse(digoxin.isVeberCompliant, "Digoxin should violate Veber (PSA > 140)")
        XCTAssertTrue(digoxin.drugLikenessViolations.contains(.psaExceeds140))

        // Morphine: PSA 52.9, rotBonds 1 → passes Veber
        let morphine = MolecularDescriptor.descriptor(for: "morphine")!
        XCTAssertTrue(morphine.isVeberCompliant, "Morphine should pass Veber")
    }

    func testDrugLikenessViolations() {
        // Insulin: massive protein, should have multiple violations
        let insulin = MolecularDescriptor.descriptor(for: "insulin-rapid")!
        XCTAssertFalse(insulin.isLipinskiCompliant)
        XCTAssertFalse(insulin.isVeberCompliant)
        XCTAssertTrue(insulin.drugLikenessViolations.contains(.molecularWeightExceeds500))
        XCTAssertTrue(insulin.drugLikenessViolations.contains(.hBondDonorsExceed5))
        XCTAssertTrue(insulin.drugLikenessViolations.contains(.hBondAcceptorsExceed10))
    }

    // MARK: - Multi-Target

    func testCalculateAllForSubstance() {
        let results = LigandEfficiencyCalculator.calculateAll(for: "morphine")
        // Morphine has 3 targets in thermodynamic profiles
        XCTAssertGreaterThanOrEqual(results.count, 1)
    }

    // MARK: - Unknown Substance

    func testUnknownSubstanceReturnsNil() {
        let result = LigandEfficiencyCalculator.calculate(substanceId: "nonexistent", targetId: "any")
        XCTAssertNil(result)
    }

    // MARK: - Summary

    func testSummaryBilingual() {
        let result = LigandEfficiencyCalculator.calculate(substanceId: "lsd", targetId: "5-HT2A")
        XCTAssertNotNil(result)
        XCTAssertFalse(result!.summary.en.isEmpty)
        XCTAssertFalse(result!.summary.fr.isEmpty)
        XCTAssertTrue(result!.summary.en.contains("LE="))
    }
}
