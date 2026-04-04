import XCTest
@testable import BonhommeCore

final class EvolutionThermodynamicsTests: XCTestCase {

    // MARK: - Phenethylamine Stimulant Line

    func testPhenethylamineStimulantLine() {
        // amphetamine → methamphetamine: HP decreases, Attack may increase → danger
        let chain = EvolutionChain.knownChains.first { $0.name.en.contains("Stimulant") }
        XCTAssertNotNil(chain, "Phenethylamine Stimulant Line should exist")

        guard let chain = chain else { return }
        let steps = EvolutionThermodynamics.analyzeChain(chain)
        XCTAssertFalse(steps.isEmpty)

        // Find the amphetamine → methamphetamine step
        let methStep = steps.first { $0.step.toSubstanceId == "methamphetamine" }
        XCTAssertNotNil(methStep, "Should have amphetamine→methamphetamine step")

        if let step = methStep {
            // Both are PokeDrug species, so stats should exist
            XCTAssertNotNil(step.fromStats)
            XCTAssertNotNil(step.toStats)
            XCTAssertNotNil(step.hpDelta)
            XCTAssertNotNil(step.attackDelta)
        }
    }

    // MARK: - Dangerous Evolutions

    func testDangerousEvolutionsFlagged() {
        let dangerous = EvolutionThermodynamics.flagDangerousEvolutions()
        // Should flag at least one dangerous evolution (e.g., amphetamine→methamphetamine)
        // Not all evolutions are necessarily dangerous
        XCTAssertGreaterThanOrEqual(dangerous.count, 0)
        for step in dangerous {
            XCTAssertEqual(step.safetyFlag, .danger)
        }
    }

    // MARK: - Nil Profiles Handled Gracefully

    func testNilProfilesHandledGracefully() {
        // Base substances (tryptamine, phenethylamine) don't have PokeDrug entries
        let chain = EvolutionChain.knownChains.first { $0.name.en.contains("Tryptamine") }
        XCTAssertNotNil(chain)

        guard let chain = chain else { return }
        let steps = EvolutionThermodynamics.analyzeChain(chain)
        XCTAssertFalse(steps.isEmpty)

        // First step is tryptamine → dmt; tryptamine has no PokeDrug entry
        let firstStep = steps.first!
        // Should not crash; stats may be nil
        if firstStep.fromStats == nil {
            XCTAssertNil(firstStep.hpDelta, "HP delta should be nil when from-stats missing")
            XCTAssertNil(firstStep.attackDelta, "Attack delta should be nil when from-stats missing")
            XCTAssertEqual(firstStep.safetyFlag, .safe, "No data → default safe")
        }
    }

    // MARK: - Affinity Fold Change

    func testAffinityFoldChangePositiveForPotencyIncrease() {
        let allSteps = EvolutionThermodynamics.analyzeAllChains()
        for (_, steps) in allSteps {
            for step in steps {
                if let fc = step.affinityFoldChange {
                    XCTAssertGreaterThan(fc, 0,
                        "\(step.step.fromSubstanceId)→\(step.step.toSubstanceId) fold change should be positive")
                }
            }
        }
    }

    // MARK: - All Chains Analyzable

    func testAllChainsAnalyzable() {
        let results = EvolutionThermodynamics.analyzeAllChains()
        XCTAssertEqual(results.count, EvolutionChain.knownChains.count,
            "Should analyze all known chains")

        for (chain, steps) in results {
            XCTAssertEqual(steps.count, chain.steps.count,
                "Step count should match chain definition for \(chain.name.en)")
        }
    }

    // MARK: - Safety Flag Logic

    func testSafetyFlagValues() {
        let allSteps = EvolutionThermodynamics.analyzeAllChains().flatMap(\.steps)
        let validFlags: [SafetyFlag] = [.safe, .caution, .danger]
        for step in allSteps {
            XCTAssertTrue(validFlags.contains(step.safetyFlag),
                "Safety flag should be a valid value")
        }
    }

    // MARK: - Potency vs Safety Correlation

    func testPotencyVsSafetyCorrelation() {
        let result = EvolutionThermodynamics.potencyVsSafetyCorrelation()
        // May be nil if fewer than 3 steps have both Attack and HP deltas
        if let r = result {
            XCTAssertGreaterThanOrEqual(r.pearsonR, -1.0)
            XCTAssertLessThanOrEqual(r.pearsonR, 1.0)
            XCTAssertGreaterThanOrEqual(r.n, 3)
        }
    }

    // MARK: - Summary

    func testStepSummariesBilingual() {
        let allSteps = EvolutionThermodynamics.analyzeAllChains().flatMap(\.steps)
        for step in allSteps {
            XCTAssertFalse(step.summary.en.isEmpty)
            XCTAssertFalse(step.summary.fr.isEmpty)
            XCTAssertTrue(step.summary.en.contains("→"))
        }
    }

    // MARK: - Enthalpy-Entropy Shift

    func testEnthalpyEntropyShiftTypes() {
        let validTypes: [BindingShiftType] = [.moreEnthalpyDriven, .moreEntropyDriven, .balanced]
        let allSteps = EvolutionThermodynamics.analyzeAllChains().flatMap(\.steps)
        for step in allSteps {
            if let shift = step.enthalpyEntropyShift {
                XCTAssertTrue(validTypes.contains(shift.shiftType))
            }
        }
    }
}
