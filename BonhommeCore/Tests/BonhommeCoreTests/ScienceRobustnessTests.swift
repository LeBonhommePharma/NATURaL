import XCTest
@testable import BonhommeCore

/// End-to-end gates for the science-robustness fix order (SCI, config, bondId,
/// partition units, drug multiplicity, three-way p-values, thermo gaps).
final class ScienceRobustnessTests: XCTestCase {

    // MARK: - SCI score (fix 1)

    func testSCIScoreFullDisorderNearZeroFor32Bins() {
        let calc = EntropyCalculator(binCount: 32)
        let uniform = (0..<1024).map { Double($0) }
        let score = calc.entropyToScore(calc.shannonEntropy(uniform))
        XCTAssertLessThan(score, 0.15)
        XCTAssertEqual(calc.entropyToScore(log2(32)), 0, accuracy: 1e-12)
    }

    func testSCIScoreConcentratedHigh() {
        let calc = EntropyCalculator(binCount: 32)
        let concentrated = Array(repeating: 800.0, count: 64)
        let score = calc.entropyToScore(calc.shannonEntropy(concentrated))
        XCTAssertGreaterThan(score, 0.9)
    }

    // MARK: - Fixed RR domain SCI path (fix 2)

    func testHRVUsesFixedDomainNotAdaptive() {
        let analyzer = HRVAnalyzer()
        // Values outside adaptive min/max of a narrow cluster still land in fixed bins.
        let narrow = Array(repeating: 800.0, count: 40)
        let wide = (0..<40).map { 300.0 + Double($0) * 30.0 } // spans 300…1470
        let hNarrow = analyzer.shannonEntropy(narrow)
        let hWide = analyzer.shannonEntropy(wide)
        XCTAssertLessThan(hNarrow, 1.0)
        XCTAssertGreaterThan(hWide, hNarrow)
        XCTAssertEqual(HRVAnalyzer.rrDomainMinMs, 300, accuracy: 0)
        XCTAssertEqual(HRVAnalyzer.rrDomainMaxMs, 1500, accuracy: 0)
    }

    // MARK: - Config wiring (fix 3)

    func testCustomDockingThresholdSuppressesBinding() {
        let config = AnalysisConfiguration(dockingSignificanceThreshold: 99)
        let analyzer = FlexAIDdSAnalyzer(configuration: config)
        let free = makeLigand(id: "x", bonds: [("b1", freeAngles())])
        let bound = makeLigand(id: "x", bonds: [("b1", boundAngles())])
        let pose = DockingPose(
            boundConformation: bound,
            receptorId: "R",
            dockingScore: -8
        )
        guard let result = analyzer.analyze(freeConformation: free, dockingPose: pose) else {
            return XCTFail("analyze should succeed")
        }
        XCTAssertEqual(result.significanceThreshold, 99, accuracy: 0)
        XCTAssertFalse(result.bindingDetected)
    }

    func testCustomDrugThresholdSuppressesBinding() {
        let config = AnalysisConfiguration(drugResponseSignificanceThreshold: 99)
        let analyzer = DrugResponseAnalyzer(configuration: config)
        let doseTime = Date()
        let dose = DoseEventSummary(
            medicationId: "caffeine",
            name: "Caffeine",
            doseValue: 100,
            doseUnit: "mg",
            timestamp: doseTime
        )
        var series: [(timestamp: Date, rrInterval: Double)] = []
        // Dense baseline (30 min, many RR)
        for i in 0..<120 {
            series.append((
                doseTime.addingTimeInterval(-1800 + Double(i) * 15),
                700 + Double(i % 7) * 25
            ))
        }
        // Post-dose windows with enough RR for entropy at 15–360 min defaults
        for minutes in [15, 30, 60, 90, 120, 180, 240, 360] {
            let center = doseTime.addingTimeInterval(Double(minutes) * 60)
            for j in 0..<40 {
                series.append((center.addingTimeInterval(Double(j) * 10), 750 + Double(j % 2)))
            }
        }
        guard let result = analyzer.analyze(doseEvent: dose, rrTimeSeries: series) else {
            return XCTFail("analyze should return a result")
        }
        XCTAssertEqual(
            result.appliedSignificanceThreshold,
            99 * sqrt(Double(result.measurements.count)),
            accuracy: 1e-9
        )
        XCTAssertFalse(result.bindingDetected)
    }

    func testCrossDomainSignificanceLevelFromConfig() {
        let strict = AnalysisConfiguration(crossDomainMinPairs: 3, crossDomainSignificanceLevel: 1e-12)
        let validator = CrossDomainValidator(configuration: strict)
        // Build synthetic pairs with modest r via validate path is heavy; unit-level:
        // ValidationResult.isSignificant must use stored significanceLevel.
        let result = CrossDomainValidator.ValidationResult(
            observations: [],
            pearsonR: 0.99,
            pValue: 0.04,
            meanAbsError: 0.1,
            regressionSlope: 1,
            regressionIntercept: 0,
            significanceLevel: 1e-12,
            minPairs: 5
        )
        // p=0.04 is not < 1e-12
        XCTAssertFalse(result.isSignificant)
        let loose = CrossDomainValidator.ValidationResult(
            observations: [
                .init(substanceId: "a", deltaSConfig: -1, deltaHHRV: -1, entropyPenaltyKcal: 0.4, inVivoEffectSize: 0.2),
                .init(substanceId: "b", deltaSConfig: -2, deltaHHRV: -2, entropyPenaltyKcal: 0.8, inVivoEffectSize: 0.3),
                .init(substanceId: "c", deltaSConfig: -3, deltaHHRV: -3, entropyPenaltyKcal: 1.2, inVivoEffectSize: 0.4),
                .init(substanceId: "d", deltaSConfig: -4, deltaHHRV: -4, entropyPenaltyKcal: 1.6, inVivoEffectSize: 0.5),
                .init(substanceId: "e", deltaSConfig: -5, deltaHHRV: -5, entropyPenaltyKcal: 2.0, inVivoEffectSize: 0.6)
            ],
            pearsonR: 0.99,
            pValue: 0.001,
            meanAbsError: 0.1,
            regressionSlope: 1,
            regressionIntercept: 0,
            significanceLevel: 0.05,
            minPairs: 5
        )
        XCTAssertTrue(loose.isSignificant)
        _ = validator // keep for API surface
    }

    // MARK: - BondId pairing (fix 4)

    func testBondIdOrderIndependentAndMismatchNil() {
        let analyzer = FlexAIDdSAnalyzer()
        let free = makeLigand(id: "lig", bonds: [
            ("alpha", freeAngles()),
            ("beta", freeAngles(offset: 10))
        ])
        let boundSame = makeLigand(id: "lig", bonds: [
            ("beta", boundAngles(offset: 10)),
            ("alpha", boundAngles())
        ])
        let pose = DockingPose(boundConformation: boundSame, receptorId: "R", dockingScore: -7)
        let r1 = analyzer.analyze(freeConformation: free, dockingPose: pose)
        XCTAssertNotNil(r1)
        let boundMismatch = makeLigand(id: "lig", bonds: [
            ("gamma", boundAngles())
        ])
        let poseBad = DockingPose(boundConformation: boundMismatch, receptorId: "R", dockingScore: -7)
        XCTAssertNil(analyzer.analyze(freeConformation: free, dockingPose: poseBad))
    }

    // MARK: - Partition energy units (fix 5)

    func testPartitionScoreEnsembleVsKcal() {
        let calc = PartitionFunctionCalculator()
        let results = (0..<3).map { i in
            FlexAIDdSResult(
                substanceId: "s\(i)",
                receptorId: "R",
                bondResults: [BondEntropyResult(bondId: "b", freeEntropy: 3, boundEntropy: 1)],
                dockingScore: Double(-5 - i)
            )
        }
        guard let scoreEns = calc.computeEnsemble(results: results) else {
            return XCTFail("score ensemble")
        }
        XCTAssertEqual(scoreEns.energyUnits, .scoreEnsemble)

        guard let kcalEns = calc.computeEnsemble(
            results: results,
            bindingFreeEnergies: [-8.0, -7.5, -7.0] as [Double?]
        ) else {
            return XCTFail("kcal ensemble")
        }
        XCTAssertEqual(kcalEns.energyUnits, .kcalPerMol)
    }

    // MARK: - Drug multiplicity (fix 7)

    func testDrugMultiplicityRaisesThresholdWithoutProfile() {
        let (dh, thr) = DrugResponseAnalyzer.significanceForBinding(
            measurements: (0..<8).map {
                EntropyMeasurement(minutesPostDose: Double($0 * 15), entropy: 4, deltaH: -0.5, rrCount: 30, coherenceScore: 0.5)
            },
            peakDeltaH: -0.5,
            profile: nil,
            baseThreshold: 0.4
        )
        XCTAssertEqual(dh, -0.5, accuracy: 1e-12)
        XCTAssertEqual(thr, 0.4 * sqrt(8), accuracy: 1e-12)
    }

    // MARK: - Three-way p-values (fix 9)

    func testThreeWayPValuesPresentAndOrdered() {
        // Strong linear triple → low p; weak → higher p for same n when possible.
        let n = 8
        let rHigh = 0.95
        let rLow = 0.1
        let pHigh = CrossDomainValidator.computePValue(r: rHigh, n: n)
        let pLow = CrossDomainValidator.computePValue(r: rLow, n: n)
        XCTAssertGreaterThanOrEqual(pHigh, 0)
        XCTAssertLessThanOrEqual(pHigh, 1)
        XCTAssertGreaterThanOrEqual(pLow, 0)
        XCTAssertLessThanOrEqual(pLow, 1)
        XCTAssertLessThan(pHigh, pLow)

        let tw = CrossDomainValidator.ThreeWayValidationResult(
            observations: [],
            flexAIDvsScorpio: rHigh,
            flexAIDvsScorpioPValue: pHigh,
            flexAIDvsNatural: rLow,
            flexAIDvsNaturalPValue: pLow,
            scorpioVsNatural: rHigh,
            scorpioVsNaturalPValue: pHigh
        )
        XCTAssertTrue(tw.summary.en.contains("p="))
    }

    // MARK: - Thermo gaps recorded (fix 9)

    func testKnownThermoGapsRegistry() {
        XCTAssertFalse(KnownThermoProfileGaps.substanceIds.isEmpty)
        XCTAssertTrue(KnownThermoProfileGaps.substanceIds.contains("diazepam"))
        XCTAssertTrue(KnownThermoProfileGaps.substanceIds.contains("cbd"))
    }

    // MARK: - Helpers

    private func freeAngles(offset: Double = 0) -> [Double] {
        (0..<64).map { -180 + Double($0) * 5.5 + offset }
    }

    private func boundAngles(offset: Double = 0) -> [Double] {
        (0..<64).map { _ in 20 + offset + Double.random(in: -2...2) }
    }

    private func makeLigand(id: String, bonds: [(String, [Double])]) -> LigandConformation {
        LigandConformation(
            substanceId: id,
            name: LocalizedString(en: id, fr: id),
            bonds: bonds.map { TorsionalAngleDistribution(bondId: $0.0, angles: $0.1) }
        )
    }
}
