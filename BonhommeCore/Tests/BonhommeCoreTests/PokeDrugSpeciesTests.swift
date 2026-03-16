import XCTest
@testable import BonhommeCore

final class PokeDrugSpeciesTests: XCTestCase {

    // MARK: - Catalog Integrity

    func testSpeciesCount() {
        XCTAssertEqual(PokeDrugSpecies.knownSpecies.count, 21, "PokeDrug Pokedex has 21 species")
    }

    func testUniqueSubstanceIds() {
        let ids = PokeDrugSpecies.knownSpecies.map(\.substanceId)
        XCTAssertEqual(ids.count, Set(ids).count, "All substanceIds must be unique")
    }

    func testUniqueDexNumbers() {
        let numbers = PokeDrugSpecies.knownSpecies.map(\.dexNumber)
        XCTAssertEqual(numbers.count, Set(numbers).count, "All dexNumbers must be unique")
    }

    func testDexNumbersArePositive() {
        for species in PokeDrugSpecies.knownSpecies {
            XCTAssertGreaterThan(species.dexNumber, 0, "\(species.substanceId) has non-positive dex number")
        }
    }

    // MARK: - Cross-Reference Validation

    func testAllSpeciesHavePKProfile() {
        for species in PokeDrugSpecies.knownSpecies {
            XCTAssertNotNil(
                species.pharmacokineticProfile,
                "\(species.substanceId) has no matching PharmacokineticProfile"
            )
        }
    }

    func testAllSpeciesHaveBindingEntropyProfile() {
        for species in PokeDrugSpecies.knownSpecies {
            XCTAssertNotNil(
                species.bindingEntropyProfile,
                "\(species.substanceId) has no matching BindingEntropyProfile"
            )
        }
    }

    // MARK: - Stat Validation

    func testAllStatsInRange() {
        for species in PokeDrugSpecies.knownSpecies {
            let s = species.stats
            XCTAssertTrue((1...5).contains(s.hp), "\(species.substanceId) HP \(s.hp) out of range")
            XCTAssertTrue((1...5).contains(s.attack), "\(species.substanceId) Attack \(s.attack) out of range")
            XCTAssertTrue((1...5).contains(s.defense), "\(species.substanceId) Defense \(s.defense) out of range")
            XCTAssertTrue((1...5).contains(s.specialAttack), "\(species.substanceId) Sp.Atk \(s.specialAttack) out of range")
            XCTAssertTrue((1...5).contains(s.specialDefense), "\(species.substanceId) Sp.Def \(s.specialDefense) out of range")
            XCTAssertTrue((1...5).contains(s.speed), "\(species.substanceId) Speed \(s.speed) out of range")
        }
    }

    func testStatTotalsInRange() {
        for species in PokeDrugSpecies.knownSpecies {
            let total = species.stats.total
            XCTAssertTrue((6...30).contains(total), "\(species.substanceId) total \(total) out of 6-30 range")
        }
    }

    // MARK: - Localization

    func testAllFlavorTextBilingual() {
        for species in PokeDrugSpecies.knownSpecies {
            XCTAssertFalse(species.flavorText.en.isEmpty, "\(species.substanceId) missing EN flavor text")
            XCTAssertFalse(species.flavorText.fr.isEmpty, "\(species.substanceId) missing FR flavor text")
            XCTAssertFalse(species.name.en.isEmpty, "\(species.substanceId) missing EN name")
            XCTAssertFalse(species.name.fr.isEmpty, "\(species.substanceId) missing FR name")
        }
    }

    // MARK: - Lookup Methods

    func testLookupBySubstanceId() {
        let lsd = PokeDrugSpecies.species(for: "lsd")
        XCTAssertNotNil(lsd)
        XCTAssertEqual(lsd?.scaffold, .ergoline)
        XCTAssertEqual(lsd?.primaryType, .serotonin)
        XCTAssertEqual(lsd?.secondaryType, .dopamine)
        XCTAssertEqual(lsd?.dexNumber, 1)
    }

    func testLookupByType() {
        let opioids = PokeDrugSpecies.species(ofType: .opioid)
        XCTAssertTrue(opioids.contains { $0.substanceId == "morphine" })
        XCTAssertTrue(opioids.contains { $0.substanceId == "fentanyl" })
        XCTAssertTrue(opioids.contains { $0.substanceId == "ibogaine" }) // secondary type
    }

    func testLookupByScaffold() {
        let tryptamines = PokeDrugSpecies.species(withScaffold: .tryptamine)
        XCTAssertTrue(tryptamines.contains { $0.substanceId == "psilocybin" })
        XCTAssertTrue(tryptamines.contains { $0.substanceId == "dmt" })
    }

    func testLookupByHabitat() {
        let fungal = PokeDrugSpecies.species(inHabitat: .fungalForest)
        XCTAssertTrue(fungal.contains { $0.substanceId == "lsd" })
        XCTAssertTrue(fungal.contains { $0.substanceId == "psilocybin" })
    }

    // MARK: - Specific Species Validation

    func testSalvinorinAIsGlassCannon() {
        let sal = PokeDrugSpecies.species(for: "salvinorin-a")
        XCTAssertNotNil(sal)
        XCTAssertEqual(sal?.stats.specialAttack, 5, "Salvinorin A should have max Sp.Atk (>5000x selectivity)")
        XCTAssertEqual(sal?.stats.speed, 5, "Salvinorin A should have max Speed (<30 sec)")
        XCTAssertEqual(sal?.stats.defense, 1, "Salvinorin A should have min Defense (8 min)")
    }

    func testIbogaineIsTripleType() {
        let ibo = PokeDrugSpecies.species(for: "ibogaine")
        XCTAssertNotNil(ibo)
        XCTAssertEqual(ibo?.scaffold, .iboga)
        XCTAssertEqual(ibo?.stats.specialAttack, 1, "Ibogaine should have lowest selectivity (6+ targets)")
        XCTAssertEqual(ibo?.stats.specialDefense, 5, "Ibogaine should have max Sp.Def (single dose)")
    }

    func testLSDAndPsilocybinMaxHP() {
        let lsd = PokeDrugSpecies.species(for: "lsd")
        let psi = PokeDrugSpecies.species(for: "psilocybin")
        XCTAssertEqual(lsd?.stats.hp, 5, "LSD should have max HP (TI ~1000)")
        XCTAssertEqual(psi?.stats.hp, 5, "Psilocybin should have max HP (TI ~1000)")
    }

    func testFentanylMinHP() {
        let fen = PokeDrugSpecies.species(for: "fentanyl")
        XCTAssertEqual(fen?.stats.hp, 1, "Fentanyl should have min HP (TI ~2-3)")
    }

    func testDMTNoTolerance() {
        let dmt = PokeDrugSpecies.species(for: "dmt")
        XCTAssertEqual(dmt?.stats.specialDefense, 5, "DMT should have max Sp.Def (no tolerance)")
    }

    // MARK: - Evolution Chains

    func testEvolutionChainCount() {
        XCTAssertGreaterThanOrEqual(EvolutionChain.knownChains.count, 7, "At least 7 evolution chains")
    }

    func testEvolutionChainsHaveNonEmptySteps() {
        for chain in EvolutionChain.knownChains {
            XCTAssertFalse(chain.steps.isEmpty, "Chain \(chain.name.en) has no steps")
            XCTAssertFalse(chain.name.en.isEmpty, "Chain missing EN name")
            XCTAssertFalse(chain.name.fr.isEmpty, "Chain missing FR name")
        }
    }

    func testEvolutionStepSubstanceIdsNonEmpty() {
        for chain in EvolutionChain.knownChains {
            for step in chain.steps {
                XCTAssertFalse(step.fromSubstanceId.isEmpty, "Step has empty fromSubstanceId")
                XCTAssertFalse(step.toSubstanceId.isEmpty, "Step has empty toSubstanceId")
                XCTAssertFalse(step.modification.en.isEmpty, "Step has empty EN modification")
                XCTAssertFalse(step.modification.fr.isEmpty, "Step has empty FR modification")
                XCTAssertFalse(step.pharmacologicalEffect.en.isEmpty, "Step has empty EN effect")
                XCTAssertFalse(step.pharmacologicalEffect.fr.isEmpty, "Step has empty FR effect")
            }
        }
    }

    func testTryptamineEvolutionChain() {
        let chains = EvolutionChain.chains(involving: "psilocybin")
        XCTAssertFalse(chains.isEmpty, "Psilocybin should appear in at least one evolution chain")
        let tryptamineChain = chains.first { $0.scaffold == .tryptamine }
        XCTAssertNotNil(tryptamineChain, "Psilocybin should be in a tryptamine chain")
    }

    // MARK: - New PK Profile Validation

    func testNewPKProfilesHaveValidRanges() {
        let newIds = ["dmt", "mescaline", "salvinorin-a", "ibogaine", "cathinone", "apigenin"]
        for id in newIds {
            let profile = PharmacokineticProfile.profile(for: id)
            XCTAssertNotNil(profile, "\(id) should have a PK profile")
            if let p = profile {
                XCTAssertLessThan(p.onsetMinutes, p.tmaxMinutes,
                    "\(id): onset (\(p.onsetMinutes)) should be < tmax (\(p.tmaxMinutes))")
                XCTAssertGreaterThan(p.halfLifeMinutes, 0, "\(id): half-life should be positive")
            }
        }
    }

    func testNewBindingEntropyProfilesExist() {
        let newIds = ["dmt", "mescaline", "salvinorin-a", "ibogaine", "cathinone", "apigenin"]
        for id in newIds {
            XCTAssertNotNil(
                BindingEntropyProfile.profile(for: id),
                "\(id) should have a binding entropy profile"
            )
        }
    }

    // MARK: - Types Helper

    func testTypesProperty() {
        let lsd = PokeDrugSpecies.species(for: "lsd")!
        XCTAssertEqual(lsd.types, [.serotonin, .dopamine])

        let psi = PokeDrugSpecies.species(for: "psilocybin")!
        XCTAssertEqual(psi.types, [.serotonin])
    }
}
