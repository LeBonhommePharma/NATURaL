import XCTest
@testable import BonhommeCore

final class PrescriptionPokeDrugBridgeTests: XCTestCase {

    func testExactSubstanceId() {
        let match = PrescriptionPokeDrugBridge.match(name: "propranolol")
        XCTAssertEqual(match?.substanceId, "propranolol")
        XCTAssertEqual(match?.matchKind, .substanceId)
        XCTAssertEqual(match?.confidence, 1.0)
        XCTAssertNotNil(match?.pharmacokineticProfile)
        XCTAssertNotNil(match?.bindingEntropyProfile)
    }

    func testExactCatalogName() {
        let match = PrescriptionPokeDrugBridge.match(name: "Caffeine")
        XCTAssertEqual(match?.substanceId, "caffeine")
        XCTAssertTrue(match?.matchKind == .substanceId || match?.matchKind == .exactName)
        XCTAssertNotNil(match?.bindingEntropyProfile)
    }

    func testContainsDoseAndSalt() {
        let match = PrescriptionPokeDrugBridge.match(name: "Propranolol HCl 40 mg")
        XCTAssertEqual(match?.substanceId, "propranolol")
        XCTAssertNotNil(match)
        XCTAssertTrue(match!.confidence >= 0.7)
    }

    func testMedicationIdPreferred() {
        let match = PrescriptionPokeDrugBridge.match(
            name: "Unknown Label",
            medicationId: "caffeine"
        )
        XCTAssertEqual(match?.substanceId, "caffeine")
        XCTAssertEqual(match?.matchKind, .substanceId)
    }

    func testLocalizedNameHelper() {
        let name = LocalizedString(en: "Diazepam", fr: "Diazépam")
        let match = PrescriptionPokeDrugBridge.match(
            medicationId: "manual-1",
            localizedName: name
        )
        XCTAssertEqual(match?.substanceId, "diazepam")
        XCTAssertNotNil(match?.species)
    }

    func testNoFalsePositiveOnNoise() {
        let match = PrescriptionPokeDrugBridge.match(name: "Vitamin D3 1000 IU")
        XCTAssertNil(match)
    }

    func testEmptyName() {
        XCTAssertNil(PrescriptionPokeDrugBridge.match(name: "   "))
    }

    func testNormalizeStripsDose() {
        let n = PrescriptionPokeDrugBridge.normalize("Sertraline 50mg tablets")
        XCTAssertFalse(n.contains("50"))
        XCTAssertTrue(n.contains("sertraline"))
    }

    func testSpeciesMatchHasMatchupScaffold() {
        let match = PrescriptionPokeDrugBridge.match(name: "caffeine")
        XCTAssertNotNil(match?.species)
        if let species = match?.species {
            let e = PokeDrugMatchup.effectiveness(
                scaffold: species.scaffold,
                against: species.primaryType
            )
            // Xanthine → adenosine should be at least weakly effective
            XCTAssertGreaterThanOrEqual(e, .weaklyEffective)
        }
    }

    func testHasCrossDomainHintWhenBindingPresent() {
        let match = PrescriptionPokeDrugBridge.match(name: "methylphenidate")
        XCTAssertEqual(match?.hasCrossDomainHint, true)
        XCTAssertNotNil(match?.bindingEntropyProfile?.expectedDeltaSBits)
    }
}
