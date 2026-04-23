import XCTest
@testable import BonhommeCore

final class ThermodynamicBindingProfileTests: XCTestCase {

    // MARK: - Catalog Integrity

    func testKnownProfileCount() {
        XCTAssertGreaterThanOrEqual(
            ThermodynamicBindingProfile.knownProfiles.count, 48,
            "Should have at least 48 substance-target entries"
        )
    }

    func testUniqueSubstanceTargetPairs() {
        let pairs = ThermodynamicBindingProfile.knownProfiles.map {
            "\($0.substanceId):\($0.targetId)"
        }
        XCTAssertEqual(pairs.count, Set(pairs).count, "All substance-target pairs must be unique")
    }

    func testAllAffinitiesPositive() {
        for profile in ThermodynamicBindingProfile.knownProfiles {
            if let ki = profile.affinity.kiNM {
                XCTAssertGreaterThan(ki, 0, "\(profile.substanceId):\(profile.targetId) Ki should be positive")
            }
            if let kd = profile.affinity.kdNM {
                XCTAssertGreaterThan(kd, 0, "\(profile.substanceId):\(profile.targetId) Kd should be positive")
            }
        }
    }

    func testAllProfilesHaveBestAffinity() {
        for profile in ThermodynamicBindingProfile.knownProfiles {
            XCTAssertNotNil(
                profile.affinity.bestAffinityNM,
                "\(profile.substanceId):\(profile.targetId) should have at least one affinity value"
            )
        }
    }

    func testExactlyOnePrimaryPerSubstance() {
        let bySubstance = Dictionary(grouping: ThermodynamicBindingProfile.knownProfiles, by: \.substanceId)
        for (id, profiles) in bySubstance {
            let primaryCount = profiles.filter(\.isPrimaryTarget).count
            XCTAssertEqual(primaryCount, 1, "\(id) should have exactly 1 primary target, found \(primaryCount)")
        }
    }

    // MARK: - Affinity Measurement

    func testBestAffinityPreference() {
        // Ki should be preferred over IC50
        let withBoth = AffinityMeasurement(kiNM: 10, ic50NM: 100)
        XCTAssertEqual(withBoth.bestAffinityNM, 10, "Ki should be preferred over IC50")

        // IC50/2 when no Ki
        let ic50Only = AffinityMeasurement(ic50NM: 100)
        XCTAssertEqual(ic50Only.bestAffinityNM, 50, "IC50/2 should be used when no Ki")

        // EC50 as last resort
        let ec50Only = AffinityMeasurement(ec50NM: 200)
        XCTAssertEqual(ec50Only.bestAffinityNM, 200, "EC50 should be used as last resort")
    }

    func testComputedDeltaG() {
        // For Ki = 1 nM at 298K: ΔG = RT ln(1e-9) ≈ -12.3 kcal/mol
        let measurement = AffinityMeasurement(kiNM: 1.0)
        guard let deltaG = measurement.computedDeltaGKcal else {
            XCTFail("Should compute ΔG from Ki")
            return
        }
        XCTAssertLessThan(deltaG, 0, "ΔG should be negative for binding")
        XCTAssertEqual(deltaG, -12.3, accuracy: 0.2, "ΔG for 1 nM Ki ≈ -12.3 kcal/mol")
    }

    // MARK: - Thermodynamic Decomposition

    func testITCThermodynamicConsistency() {
        for profile in ThermodynamicBindingProfile.knownProfiles {
            guard let thermo = profile.thermodynamics else { continue }
            XCTAssertTrue(
                thermo.isThermodynamicallyConsistent,
                "\(profile.substanceId):\(profile.targetId) ITC not consistent: " +
                "ΔG=\(thermo.deltaGKcal), ΔH=\(thermo.deltaHKcal), -TΔS=\(thermo.minusTDeltaSKcal)"
            )
        }
    }

    func testEntropyDrivenClassification() {
        // Fentanyl-MOR: -TΔS (-5.3) > |ΔH| (-6.8) → entropy-driven = false
        let fentanyl = ThermodynamicBindingProfile.profile(for: "fentanyl")
        XCTAssertNotNil(fentanyl?.thermodynamics)
        XCTAssertTrue(fentanyl?.thermodynamics?.enthalpyDriven ?? false,
            "Fentanyl-MOR binding should be enthalpy-driven")

        // Caffeine-A2A: -TΔS (-4.5) > |ΔH| (-3.2) → entropy-driven = true
        let caffeine = ThermodynamicBindingProfile.profile(for: "caffeine")
        XCTAssertNotNil(caffeine?.thermodynamics)
        XCTAssertTrue(caffeine?.thermodynamics?.entropyDriven ?? false,
            "Caffeine-A2A binding should be entropy-driven")
    }

    func testDeltaSBitsConversion() {
        // -TΔS = -4.5 kcal/mol at 298K should give a positive deltaSBits value
        let thermo = ThermodynamicDecomposition(
            deltaGKcal: -7.7, deltaHKcal: -3.2, minusTDeltaSKcal: -4.5
        )
        // deltaSBits = -(-4.5) / (298 * 1.987e-3 * ln2) ≈ 10.97
        XCTAssertGreaterThan(thermo.deltaSBits, 0, "Negative -TΔS should give positive ΔS bits (entropy gain)")
        XCTAssertEqual(thermo.deltaSBits, 10.97, accuracy: 0.5)
    }

    // MARK: - Stereochemical Notes

    func testStereochemicalNotes() {
        let ketamine = ThermodynamicBindingProfile.knownProfiles.first {
            $0.substanceId == "ketamine" && $0.targetId == "NMDA-PCP"
        }
        XCTAssertNotNil(ketamine?.stereochemistry, "Ketamine should have stereochemical note")
        XCTAssertEqual(ketamine?.stereochemistry?.enantiomer, "S(+)")
        XCTAssertEqual(ketamine?.stereochemistry?.affinityRatio, 3.0)

        let amphetamine = ThermodynamicBindingProfile.knownProfiles.first {
            $0.substanceId == "amphetamine" && $0.targetId == "DAT"
        }
        XCTAssertNotNil(amphetamine?.stereochemistry)
        XCTAssertEqual(amphetamine?.stereochemistry?.affinityRatio, 4.0)

        let meth = ThermodynamicBindingProfile.knownProfiles.first {
            $0.substanceId == "methamphetamine" && $0.targetId == "DAT"
        }
        XCTAssertNotNil(meth?.stereochemistry)
        XCTAssertEqual(meth?.stereochemistry?.affinityRatio, 5.0)
    }

    // MARK: - Prodrug Relationships

    func testProdrugRelationships() {
        XCTAssertGreaterThanOrEqual(ProdrugRelationship.knownProdrugs.count, 4)

        let psilocybin = ProdrugRelationship.prodrug(for: "psilocybin")
        XCTAssertNotNil(psilocybin)
        XCTAssertEqual(psilocybin?.activeMetaboliteId, "psilocin")
        XCTAssertEqual(psilocybin?.activatingEnzyme, "alkaline phosphatase")

        let codeine = ProdrugRelationship.prodrug(for: "codeine")
        XCTAssertNotNil(codeine)
        XCTAssertEqual(codeine?.activeMetaboliteId, "morphine")
        XCTAssertEqual(codeine?.activatingEnzyme, "CYP2D6")
    }

    // MARK: - Multi-Target Lookups

    func testLSDMultiTarget() {
        let profiles = ThermodynamicBindingProfile.profiles(for: "lsd")
        XCTAssertEqual(profiles.count, 3, "LSD should have 3 target profiles")

        let primary = profiles.first { $0.isPrimaryTarget }
        XCTAssertNotNil(primary)
        XCTAssertEqual(primary?.targetId, "5-HT2A")
        XCTAssertNotNil(primary?.thermodynamics, "LSD primary should have ITC data")
    }

    func testIbogaineMultiTarget() {
        let profiles = ThermodynamicBindingProfile.profiles(for: "ibogaine")
        XCTAssertEqual(profiles.count, 6, "Ibogaine should have 6 target profiles")

        let primary = profiles.first { $0.isPrimaryTarget }
        XCTAssertEqual(primary?.targetId, "a3b4-nAChR")
    }

    func testSalvinorinASingleTarget() {
        let profiles = ThermodynamicBindingProfile.profiles(for: "salvinorin-a")
        XCTAssertEqual(profiles.count, 1, "Salvinorin A should have 1 target")
        XCTAssertEqual(profiles.first?.targetId, "KOR")
        XCTAssertNotNil(profiles.first?.thermodynamics, "Salvinorin A should have partial ITC")
    }

    func testProfilesForSubstance() {
        // Primary lookup
        let morphinePrimary = ThermodynamicBindingProfile.profile(for: "morphine")
        XCTAssertNotNil(morphinePrimary)
        XCTAssertEqual(morphinePrimary?.targetId, "MOR")

        // All targets lookup
        let morphineAll = ThermodynamicBindingProfile.profiles(for: "morphine")
        XCTAssertEqual(morphineAll.count, 3)
    }

    // MARK: - PokeDrug Species Cross-Reference

    /// Core species with published ITC/calorimetry data must have thermodynamic profiles.
    /// Expansion species (diazepam, psilocin, mda, etc.) may not yet have published
    /// thermodynamic data and are excluded from this check.
    func testCorePokeDrugSpeciesHaveThermodynamicProfile() {
        let expansionSpecies: Set<String> = [
            "diazepam", "psilocin", "mda", "scopolamine",
            "muscimol", "ephedrine", "mitragynine", "cbd", "harmine"
        ]
        for species in PokeDrugSpecies.knownSpecies where !expansionSpecies.contains(species.substanceId) {
            let profiles = species.thermodynamicProfiles
            XCTAssertFalse(
                profiles.isEmpty,
                "\(species.substanceId) has no thermodynamic binding profiles"
            )
        }
    }

    func testDerivedAttackMatchesCatalogRoughly() {
        // LSD Ki = 3.5 nM → deriveAttack = 5
        let lsd = PokeDrugSpecies.species(for: "lsd")!
        XCTAssertEqual(lsd.derivedAttack, 5, "LSD derived Attack should be 5 (Ki 3.5 nM)")

        // Caffeine Ki = 2400 nM → deriveAttack = 2
        let caffeine = PokeDrugSpecies.species(for: "caffeine")!
        XCTAssertEqual(caffeine.derivedAttack, 2, "Caffeine derived Attack should be 2 (Ki 2400 nM)")

        // Apigenin Ki = 3000 nM → deriveAttack = 2
        let apigenin = PokeDrugSpecies.species(for: "apigenin")!
        XCTAssertEqual(apigenin.derivedAttack, 2, "Apigenin derived Attack should be 2 (Ki 3000 nM)")
    }

    func testDerivedSpecialAttack() {
        // Salvinorin A: single target → max selectivity = 5
        let sal = PokeDrugSpecies.species(for: "salvinorin-a")!
        XCTAssertEqual(sal.derivedSpecialAttack, 5, "Salvinorin A should have max derived Sp.Atk (single target)")

        // Ibogaine: 6 targets, primary Ki 20, next best 31 → ratio ~1.55 → 1
        let ibo = PokeDrugSpecies.species(for: "ibogaine")!
        XCTAssertEqual(ibo.derivedSpecialAttack, 1, "Ibogaine should have min derived Sp.Atk (6+ targets)")
    }

    // MARK: - Stat Derivation Helpers

    func testDeriveAttackFromKi() {
        XCTAssertEqual(PokeDrugStats.deriveAttack(kiNM: 1.5), 5)    // < 10
        XCTAssertEqual(PokeDrugStats.deriveAttack(kiNM: 50), 4)     // 10-100
        XCTAssertEqual(PokeDrugStats.deriveAttack(kiNM: 500), 3)    // 100-1K
        XCTAssertEqual(PokeDrugStats.deriveAttack(kiNM: 5000), 2)   // 1K-10K
        XCTAssertEqual(PokeDrugStats.deriveAttack(kiNM: 50000), 1)  // > 10K
    }

    func testDeriveSpecialAttackFromSelectivity() {
        XCTAssertEqual(PokeDrugStats.deriveSpecialAttack(selectivityRatio: 5000), 5)  // > 1000
        XCTAssertEqual(PokeDrugStats.deriveSpecialAttack(selectivityRatio: 500), 4)   // 100-1000
        XCTAssertEqual(PokeDrugStats.deriveSpecialAttack(selectivityRatio: 50), 3)    // 10-100
        XCTAssertEqual(PokeDrugStats.deriveSpecialAttack(selectivityRatio: 5), 2)     // 3-10
        XCTAssertEqual(PokeDrugStats.deriveSpecialAttack(selectivityRatio: 1.5), 1)   // < 3
    }

    // MARK: - Source Enum

    func testThermodynamicSourceCases() {
        XCTAssertEqual(ThermodynamicSource.allCases.count, 6)
    }

    // MARK: - Assay Conditions

    func testAssayConditionsDefaults() {
        let standard = AssayConditions.standard
        XCTAssertEqual(standard.temperatureK, 298.0)
        XCTAssertEqual(standard.pH, 7.4)

        let physiological = AssayConditions.physiological
        XCTAssertEqual(physiological.temperatureK, 310.0)
    }
}
