import XCTest
@testable import BonhommeCore

final class PokeDrugTypeTests: XCTestCase {

    // MARK: - Enum Completeness

    func testPokeDrugTypeCount() {
        XCTAssertEqual(PokeDrugType.allCases.count, 12, "PokeDrug system has exactly 12 types")
    }

    func testMolecularScaffoldCount() {
        XCTAssertEqual(MolecularScaffold.allCases.count, 13, "PokeDrug system has exactly 13 scaffolds")
    }

    func testPokeDrugHabitatCount() {
        XCTAssertEqual(PokeDrugHabitat.allCases.count, 7, "PokeDrug system has exactly 7 habitats")
    }

    // MARK: - Type Metadata

    func testAllTypesHaveNonEmptyMetadata() {
        for type in PokeDrugType.allCases {
            XCTAssertFalse(type.pharmacologicalTarget.en.isEmpty, "\(type) missing EN pharmacological target")
            XCTAssertFalse(type.pharmacologicalTarget.fr.isEmpty, "\(type) missing FR pharmacological target")
            XCTAssertFalse(type.endogenousLigand.en.isEmpty, "\(type) missing EN endogenous ligand")
            XCTAssertFalse(type.endogenousLigand.fr.isEmpty, "\(type) missing FR endogenous ligand")
            XCTAssertFalse(type.prototypeDrug.en.isEmpty, "\(type) missing EN prototype drug")
            XCTAssertFalse(type.prototypeDrug.fr.isEmpty, "\(type) missing FR prototype drug")
            XCTAssertFalse(type.color.isEmpty, "\(type) missing color")
            XCTAssertTrue(type.color.hasPrefix("#"), "\(type) color should be hex format")
        }
    }

    // MARK: - Scaffold Metadata

    func testAllScaffoldsHaveNonEmptyMetadata() {
        for scaffold in MolecularScaffold.allCases {
            XCTAssertFalse(scaffold.primaryTypes.isEmpty, "\(scaffold) missing primary types")
            XCTAssertFalse(scaffold.displayName.en.isEmpty, "\(scaffold) missing EN name")
            XCTAssertFalse(scaffold.displayName.fr.isEmpty, "\(scaffold) missing FR name")
            XCTAssertFalse(scaffold.coreStructure.en.isEmpty, "\(scaffold) missing EN core structure")
            XCTAssertFalse(scaffold.coreStructure.fr.isEmpty, "\(scaffold) missing FR core structure")
        }
    }

    func testScaffoldPrimaryTypesAreValidPokeDrugTypes() {
        for scaffold in MolecularScaffold.allCases {
            for type in scaffold.primaryTypes {
                XCTAssertTrue(PokeDrugType.allCases.contains(type),
                    "\(scaffold) has invalid primary type: \(type)")
            }
        }
    }

    // MARK: - Habitat Metadata

    func testAllHabitatsHaveNonEmptyMetadata() {
        for habitat in PokeDrugHabitat.allCases {
            XCTAssertFalse(habitat.displayName.en.isEmpty, "\(habitat) missing EN name")
            XCTAssertFalse(habitat.displayName.fr.isEmpty, "\(habitat) missing FR name")
            XCTAssertFalse(habitat.description.en.isEmpty, "\(habitat) missing EN description")
            XCTAssertFalse(habitat.description.fr.isEmpty, "\(habitat) missing FR description")
            XCTAssertFalse(habitat.scaffoldsFound.isEmpty, "\(habitat) has no scaffolds")
        }
    }

    func testHabitatScaffoldsAreValid() {
        for habitat in PokeDrugHabitat.allCases {
            for scaffold in habitat.scaffoldsFound {
                XCTAssertTrue(MolecularScaffold.allCases.contains(scaffold),
                    "\(habitat) references invalid scaffold: \(scaffold)")
            }
        }
    }

    // MARK: - Type Effectiveness

    func testTypeEffectivenessOrdering() {
        XCTAssertTrue(TypeEffectiveness.immune < TypeEffectiveness.notEffective)
        XCTAssertTrue(TypeEffectiveness.notEffective < TypeEffectiveness.weaklyEffective)
        XCTAssertTrue(TypeEffectiveness.weaklyEffective < TypeEffectiveness.effective)
        XCTAssertTrue(TypeEffectiveness.effective < TypeEffectiveness.superEffective)
    }

    func testStarRatingDisplay() {
        XCTAssertEqual(TypeEffectiveness.immune.starRating, "✗ Immune")
        XCTAssertEqual(TypeEffectiveness.notEffective.starRating, "✗ Not effective")
        XCTAssertEqual(TypeEffectiveness.weaklyEffective.starRating, "★★")
        XCTAssertEqual(TypeEffectiveness.effective.starRating, "★★★")
        XCTAssertEqual(TypeEffectiveness.superEffective.starRating, "★★★★")
    }

    // MARK: - Matchup Chart

    func testKnownSuperEffectivePairs() {
        // Tryptamine → 5-HT2A: endogenous ligand IS a tryptamine
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .tryptamine, against: .serotonin),
            .superEffective
        )
        // Ergoline → 5-HT2A: locked tryptamine + lid mechanism
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .ergoline, against: .serotonin),
            .superEffective
        )
        // Morphinan → MOR: mimics enkephalin Tyr1
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .morphinan, against: .opioid),
            .superEffective
        )
        // Phenethylamine → DAT: endogenous ligands ARE phenethylamines
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .phenethylamine, against: .dopamine),
            .superEffective
        )
        // Xanthine → Adenosine: purine analog
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .xanthine, against: .adenosine),
            .superEffective
        )
        // Salvinorin A scaffold → KOR: Ki 1.9 nM
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .terpenoid, against: .kappa),
            .superEffective
        )
        // Benzodioxole → Empathogen: SERT/DAT ~10:1
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .benzodioxole, against: .empathogen),
            .superEffective
        )
    }

    func testKnownImmunePairs() {
        // Terpenoid (salvinorin A) → 5-HT2A: confirmed zero binding
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .terpenoid, against: .serotonin),
            .immune
        )
        // Xanthine → Opioid: no basic nitrogen, wrong shape
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .xanthine, against: .opioid),
            .immune
        )
        // Phenethylamine → CB1: too small/polar
        XCTAssertEqual(
            PokeDrugMatchup.effectiveness(scaffold: .phenethylamine, against: .cannabinoid),
            .immune
        )
    }

    func testAllScaffoldTypeCombinationsReturnValid() {
        for scaffold in MolecularScaffold.allCases {
            for type in PokeDrugType.allCases {
                let result = PokeDrugMatchup.effectiveness(scaffold: scaffold, against: type)
                XCTAssertTrue(
                    (TypeEffectiveness.immune...TypeEffectiveness.superEffective).contains(result),
                    "Invalid effectiveness for \(scaffold) vs \(type): \(result)"
                )
            }
        }
    }

    // MARK: - Stats Derivation

    func testDeriveDefenseFromHalfLife() {
        XCTAssertEqual(PokeDrugStats.deriveDefense(halfLifeMinutes: 30), 1)   // < 60
        XCTAssertEqual(PokeDrugStats.deriveDefense(halfLifeMinutes: 120), 2)  // 60-180
        XCTAssertEqual(PokeDrugStats.deriveDefense(halfLifeMinutes: 300), 3)  // 180-480
        XCTAssertEqual(PokeDrugStats.deriveDefense(halfLifeMinutes: 600), 4)  // 480-1200
        XCTAssertEqual(PokeDrugStats.deriveDefense(halfLifeMinutes: 1800), 5) // > 1200
    }

    func testDeriveSpeedFromOnset() {
        XCTAssertEqual(PokeDrugStats.deriveSpeed(onsetMinutes: 1), 5)   // < 5
        XCTAssertEqual(PokeDrugStats.deriveSpeed(onsetMinutes: 10), 4)  // 5-15
        XCTAssertEqual(PokeDrugStats.deriveSpeed(onsetMinutes: 20), 3)  // 15-30
        XCTAssertEqual(PokeDrugStats.deriveSpeed(onsetMinutes: 45), 2)  // 30-60
        XCTAssertEqual(PokeDrugStats.deriveSpeed(onsetMinutes: 90), 1)  // > 60
    }

    func testStarString() {
        XCTAssertEqual(PokeDrugStats.starString(for: 1), "★")
        XCTAssertEqual(PokeDrugStats.starString(for: 3), "★★★")
        XCTAssertEqual(PokeDrugStats.starString(for: 5), "★★★★★")
    }
}
