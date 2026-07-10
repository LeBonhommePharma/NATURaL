import XCTest
@testable import BonhommeCore

/// Crooks-cycle control stack: σ_irr math, EigenMetal/ANE work, ActuatorBus,
/// universal beat, crown β, AirPods mirror, and ΔHRV↔FlexAID mapping.
final class CrooksCycleControllerTests: XCTestCase {

    // MARK: - EigenMetal Work Kernel

    func testProductionWeightsSumToOne() {
        let sum = EigenMetalWorkKernel.productionWeights.reduce(0, +)
        XCTAssertEqual(sum, 1.0, accuracy: 1e-12)
    }

    func testEigenBasisIsOrthonormal() {
        let basis = EigenMetalWorkKernel.eigenBasis
        XCTAssertEqual(basis.count, 4)
        for i in 0..<4 {
            let norm = sqrt(basis[i].map { $0 * $0 }.reduce(0, +))
            XCTAssertEqual(norm, 1.0, accuracy: 1e-9, "basis[\(i)] should be unit")
            for j in (i + 1)..<4 {
                let dot = zip(basis[i], basis[j]).map(*).reduce(0, +)
                XCTAssertEqual(dot, 0, accuracy: 1e-9, "basis[\(i)]·basis[\(j)] should be 0")
            }
        }
    }

    func testWorkEvaluationIsFiniteAndClamped() {
        let kernel = EigenMetalWorkKernel()
        let features = CrooksFeatureVector(
            deltaHRV: -2.5,
            flexAIDDeltaS: -3.0,
            crownBeta: 0.5,
            bpm: 140
        )
        let result = kernel.evaluate(features)
        XCTAssertTrue(result.work.isFinite)
        XCTAssertLessThanOrEqual(abs(result.work), CrooksCycleDefaults.maxAbsWorkPerTick)
        XCTAssertEqual(result.eigenCoords.count, 4)
        XCTAssertFalse(result.backendLabel.isEmpty)
    }

    func testWorkMonotonicWithPositiveDeltaHRV() {
        let kernel = EigenMetalWorkKernel()
        let low = kernel.evaluate(CrooksFeatureVector(
            deltaHRV: 0.1, flexAIDDeltaS: 0, crownBeta: 0, bpm: CrooksCycleDefaults.nominalBPM
        )).work
        let high = kernel.evaluate(CrooksFeatureVector(
            deltaHRV: 1.0, flexAIDDeltaS: 0, crownBeta: 0, bpm: CrooksCycleDefaults.nominalBPM
        )).work
        XCTAssertGreaterThan(high, low)
    }

    /// Seated yoga HR (~70–90) must not produce near-max |work| from BPM alone.
    func testRestingBPMDoesNotDominateWork() {
        let kernel = EigenMetalWorkKernel()
        let atNominal = kernel.evaluate(CrooksFeatureVector(
            deltaHRV: 0, flexAIDDeltaS: 0, crownBeta: 0, bpm: CrooksCycleDefaults.nominalBPM
        )).work
        let seated = kernel.evaluate(CrooksFeatureVector(
            deltaHRV: 0, flexAIDDeltaS: 0, crownBeta: 0, bpm: 75
        )).work
        XCTAssertEqual(atNominal, 0, accuracy: 1e-9)
        // Fractional BPM channel weight 0.09 → |work| ≪ maxAbsWorkPerTick at yoga HR.
        XCTAssertLessThan(abs(seated), 0.15)
        XCTAssertLessThan(abs(seated), CrooksCycleDefaults.maxAbsWorkPerTick * 0.1)

        let features = CrooksFeatureVector(
            deltaHRV: 0, flexAIDDeltaS: 0, crownBeta: 0, bpm: 75
        )
        XCTAssertEqual(
            features.bpmFractionalDeviation,
            (75 - CrooksCycleDefaults.nominalBPM) / CrooksCycleDefaults.nominalBPM,
            accuracy: 1e-12
        )
    }

    func testWorkHistoryEntropyNonNegative() {
        let kernel = EigenMetalWorkKernel()
        let works = (0..<64).map { i in
            kernel.evaluate(CrooksFeatureVector(
                deltaHRV: Double(i % 5) * 0.2 - 0.4,
                flexAIDDeltaS: -1.0,
                crownBeta: 0,
                bpm: 120 + Double(i % 10)
            )).work
        }
        let h = kernel.workHistoryEntropy(works)
        XCTAssertGreaterThanOrEqual(h, 0)
    }

    // MARK: - Crown β Dial

    func testCrownBetaClampAndScene() {
        var dial = CrownBetaDial(beta: 0)
        dial.setBeta(2.0)
        XCTAssertEqual(dial.beta, 1.0, accuracy: 1e-12)
        XCTAssertEqual(dial.sceneLabel, "heating")

        dial.setBeta(-2.0)
        XCTAssertEqual(dial.beta, -1.0, accuracy: 1e-12)
        XCTAssertEqual(dial.sceneLabel, "binding")

        dial.setBeta(0)
        XCTAssertEqual(dial.sceneLabel, "neutral")
    }

    func testCrownDeltaSmoothing() {
        var dial = CrownBetaDial(beta: 0, sensitivity: 0.1, smoothing: 0.5)
        let b1 = dial.applyCrownDelta(1.0)
        XCTAssertGreaterThan(b1, 0)
        XCTAssertLessThan(b1, 0.1) // smoothed step
        dial.dampTowardNeutral(gain: 1.0)
        XCTAssertEqual(dial.beta, 0, accuracy: 1e-6)
    }

    // MARK: - Universal Beat Sync

    func testBeatSyncBroadcastAndPhase() async {
        let sync = UniversalBeatSync()
        let snap = await sync.broadcast(bpm: 92, beta: -0.2, grounding: true)
        XCTAssertEqual(snap.bpm, 92, accuracy: 1e-9)
        XCTAssertTrue(snap.isGrounding)
        XCTAssertEqual(snap.crownBeta, -0.2, accuracy: 1e-9)

        // Advance phase with a tick in the future.
        try? await Task.sleep(nanoseconds: 50_000_000)
        let ticked = await sync.tick()
        XCTAssertGreaterThanOrEqual(ticked.phase, 0)
        XCTAssertLessThan(ticked.phase, 1)
    }

    func testBeatSyncClampsBPM() async {
        let sync = UniversalBeatSync()
        let high = await sync.broadcast(bpm: 999, beta: 0)
        XCTAssertEqual(high.bpm, 220, accuracy: 1e-9)
        let low = await sync.broadcast(bpm: 1, beta: 0)
        XCTAssertEqual(low.bpm, 40, accuracy: 1e-9)
    }

    // MARK: - DeltaHRV FlexAID Mapper

    func testMapperPredictsFromProfile() async {
        let mapper = DeltaHRVFlexAIDMapper()
        let pred = await mapper.predict(
            deltaHRV: -1.5,
            flexAIDDeltaS: 0,
            substanceId: "fentanyl"
        )
        XCTAssertEqual(pred.flexAIDDeltaS, -10.2, accuracy: 0.01)
        XCTAssertTrue(pred.source.contains("profile") || pred.source == "BindingEntropyProfile")
        XCTAssertGreaterThanOrEqual(pred.residual, 0)
        XCTAssertEqual(pred.substanceId, "fentanyl")
    }

    /// Without live FlexAID or profile substance, residual must not request grounding.
    func testMapperDoesNotGroundWithoutMolecularAnchor() async {
        let mapper = DeltaHRVFlexAIDMapper()
        let pred = await mapper.predict(
            deltaHRV: -2.0,
            flexAIDDeltaS: 0,
            substanceId: nil
        )
        XCTAssertFalse(pred.shouldGround)
        XCTAssertEqual(pred.source, "live")
        // With profile anchor, large residual may ground.
        let anchored = await mapper.predict(
            deltaHRV: -2.0,
            flexAIDDeltaS: 0,
            substanceId: "fentanyl"
        )
        XCTAssertTrue(anchored.source.contains("profile") || anchored.source == "BindingEntropyProfile")
    }

    func testMapperEntropyPenaltyMatchesThermodynamicConstants() async {
        let mapper = DeltaHRVFlexAIDMapper()
        let bits = -3.0
        let kcal = mapper.entropyPenaltyKcal(deltaSBits: bits)
        let expected = ThermodynamicConstants.entropyPenaltyKcal(deltaSBits: bits)
        XCTAssertEqual(kcal, expected, accuracy: 1e-12)
    }

    // MARK: - ActuatorBus

    func testActuatorBusProductionChannelsPresent() async {
        let bus = ActuatorBus.makeProduction()
        let ids = await bus.channelIds()
        XCTAssertTrue(ids.contains("universal_beat_sync"))
        XCTAssertTrue(ids.contains("crown_beta_dial"))
        XCTAssertTrue(ids.contains("airpods_crown_beta"))
        XCTAssertTrue(ids.contains("delta_hrv_flexaid"))
        XCTAssertTrue(ids.contains("session_log"))
        XCTAssertTrue(ids.contains("breathing_guide"))
        XCTAssertEqual(ids.count, 6)
    }

    func testActuatorBusGroundingAllSucceed() async {
        let bus = ActuatorBus.makeProduction()
        let results = await bus.executeGrounding(sigmaIrr: 0.2, bpm: 140, beta: 0.5)
        XCTAssertEqual(results.count, 6)
        for r in results {
            XCTAssertTrue(r.success, "channel \(r.channelId) failed: \(r.detail)")
            XCTAssertFalse(r.detail.isEmpty)
        }
        let log = await SessionEventLog.shared.all()
        XCTAssertFalse(log.isEmpty)
    }

    // MARK: - AirPods Crown β

    func testAirPodsVolumeDeltaAndStemPress() async {
        let airPods = AirPodsCrownBetaController(beatSync: UniversalBeatSync())
        await airPods.setRouteActive(true)
        let betaUp = await airPods.applyVolumeDelta(1.0)
        XCTAssertGreaterThan(betaUp, 0)
        let afterStem = await airPods.applyStemPress(gain: 1.0)
        XCTAssertEqual(afterStem, 0, accuracy: 1e-6)
        let snap = await airPods.snapshot()
        XCTAssertTrue(snap.routeActive)
        XCTAssertEqual(snap.sceneLabel, "neutral")
    }

    func testAirPodsMirrorsWatchCrownAndBroadcasts() async {
        let beat = UniversalBeatSync()
        let airPods = AirPodsCrownBetaController(beatSync: beat)
        await airPods.setRouteActive(true)
        _ = await airPods.mirrorWatchCrown(beta: 0.75)
        let beatSnap = await airPods.broadcastBeat(bpm: 110, beta: 0.75, grounding: false)
        XCTAssertEqual(beatSnap.bpm, 110, accuracy: 1e-9)
        XCTAssertEqual(beatSnap.crownBeta, 0.75, accuracy: 1e-9)
        let snap = await airPods.snapshot()
        XCTAssertEqual(snap.beta, 0.75, accuracy: 1e-9)
        XCTAssertEqual(snap.sceneLabel, "heating")
    }

    func testBeatSyncChannelIsSoleBroadcastOnBusTick() async {
        let beat = UniversalBeatSync()
        let counter = ListenerCounter()
        await beat.addListener { _ in await counter.increment() }
        let bus = ActuatorBus(channels: [
            BeatSyncActuatorChannel(beatSync: beat),
            CrownActuatorChannel(crown: CrownController(beatSync: beat)),
            AirPodsCrownActuatorChannel(airPods: AirPodsCrownBetaController(beatSync: beat)),
            BreathingGuideActuatorChannel()
        ])
        _ = await bus.broadcastBeat(bpm: 100, beta: 0.2, grounding: false)
        // Crown + AirPods adopt state only; one UniversalBeatSync.broadcast → one listener fire.
        let count = await counter.value
        XCTAssertEqual(count, 1)
    }

    /// Phase flip must be log-only on the beat channel — end-of-tick owns broadcast.
    func testPhaseFlipDoesNotBroadcastBeat() async {
        let beat = UniversalBeatSync()
        let counter = ListenerCounter()
        await beat.addListener { _ in await counter.increment() }
        // Seed a known tempo.
        _ = await beat.broadcast(bpm: 100, beta: 0.1, grounding: false)
        let afterSeed = await counter.value
        XCTAssertEqual(afterSeed, 1)

        let bus = ActuatorBus(channels: [
            BeatSyncActuatorChannel(beatSync: beat),
            CrownActuatorChannel(crown: CrownController(beatSync: beat)),
            SessionLogActuatorChannel()
        ])
        _ = await bus.executePhaseFlip(from: .forward, to: .reverse, cycleCount: 1)
        let afterFlip = await counter.value
        XCTAssertEqual(afterFlip, afterSeed, "phaseFlip must not re-broadcast (was double-beat bug)")

        // End-of-tick sole broadcast still works.
        _ = await bus.broadcastBeat(bpm: 100, beta: 0.1, grounding: false)
        let afterTick = await counter.value
        XCTAssertEqual(afterTick, afterSeed + 1)
    }

    func testRemoveAllListenersClearsBeatSubscribers() async {
        let beat = UniversalBeatSync()
        let counter = ListenerCounter()
        await beat.addListener { _ in await counter.increment() }
        _ = await beat.broadcast(bpm: 90, beta: 0, grounding: false)
        let afterFirst = await counter.value
        XCTAssertEqual(afterFirst, 1)
        await beat.removeAllListeners()
        _ = await beat.broadcast(bpm: 95, beta: 0, grounding: false)
        let afterClear = await counter.value
        XCTAssertEqual(afterClear, 1, "listeners cleared — no further fires")
    }

    func testBreathingGuidePublishesToSnapshotStore() async {
        await ControlActuatorSnapshotStore.shared.reset()
        let channel = BreathingGuideActuatorChannel()
        _ = await channel.execute(.beatBroadcast(bpm: CrooksCycleDefaults.groundingBPM, beta: 0, grounding: true))
        let rate = await ControlActuatorSnapshotStore.shared.breathsPerMinute
        let expected = CrooksCycleDefaults.groundingBPM / BreathingGuideActuatorChannel.bpmPerBreath
        XCTAssertEqual(rate, expected, accuracy: 1e-9)
    }

    /// Volume / stem mutate β only — never UniversalBeatSync.broadcast.
    func testAirPodsVolumeStemDoNotBroadcast() async {
        let beat = UniversalBeatSync()
        let counter = ListenerCounter()
        await beat.addListener { _ in await counter.increment() }
        let airPods = AirPodsCrownBetaController(beatSync: beat)
        await airPods.setRouteActive(true)
        _ = await airPods.applyVolumeDelta(1.0)
        _ = await airPods.applyStemPress(gain: 0.5)
        let count = await counter.value
        XCTAssertEqual(count, 0, "volume/stem must not bypass ActuatorBus beat authority")
    }

    func testANEWorkPathLabelPresent() {
        let kernel = EigenMetalWorkKernel()
        let result = kernel.evaluate(CrooksFeatureVector(
            deltaHRV: -1, flexAIDDeltaS: -2, crownBeta: 0.1, bpm: 120
        ))
        // Length-4 control hot path is intentionally scalar (vDSP loses for N=4).
        XCTAssertFalse(result.usedANEPath)
        XCTAssertEqual(result.backendLabel, "Scalar/Eigen")
        // Compile-time Accelerate remains available for larger vectors if needed.
        #if canImport(Accelerate)
        XCTAssertTrue(EigenMetalWorkKernel.accelerateAvailable)
        #else
        XCTAssertFalse(EigenMetalWorkKernel.accelerateAvailable)
        #endif
        XCTAssertTrue(result.work.isFinite)
    }

    /// Work-history entropy must call shipped `EntropyCalculator` (not a reimplementation).
    func testWorkHistoryEntropyMatchesEntropyCalculator() {
        let kernel = EigenMetalWorkKernel()
        var works = [Double]()
        works.reserveCapacity(128)
        for i in 0..<128 {
            let di = Double(i)
            let features = CrooksFeatureVector(
                deltaHRV: sin(di) * 1.5,
                flexAIDDeltaS: cos(di) * 0.8,
                crownBeta: Double(i % 7) * 0.1 - 0.3,
                bpm: 110 + Double(i % 20)
            )
            works.append(kernel.evaluate(features).work)
        }
        let viaKernel = kernel.workHistoryEntropy(works)
        let viaCalc = EntropyCalculator(binCount: 32).shannonEntropy(works)
        XCTAssertEqual(viaKernel, viaCalc, accuracy: 1e-12)
        XCTAssertGreaterThanOrEqual(viaKernel, 0)
    }

    /// Non-finite features must not poison work (production clamp).
    func testExtremeNaNInputsProduceFiniteWork() {
        let kernel = EigenMetalWorkKernel()
        let result = kernel.evaluate(CrooksFeatureVector(
            deltaHRV: .nan,
            flexAIDDeltaS: .infinity,
            crownBeta: -.infinity,
            bpm: .nan
        ))
        XCTAssertTrue(result.work.isFinite)
        XCTAssertEqual(result.work, 0, accuracy: 1e-12)
        XCTAssertTrue(result.eigenCoords.allSatisfy(\.isFinite))
    }

    // MARK: - CrooksCycleController

    func testSigmaIrrNonNegative() async {
        let controller = CrooksCycleController(
            actuators: ActuatorBus.makeProduction(),
            crown: CrownController(),
            mapper: DeltaHRVFlexAIDMapper()
        )
        let result = await controller.update(
            deltaHRV: 0.5,
            flexAIDDeltaS: -1.0,
            crownBeta: 0.2,
            bpm: 130
        )
        XCTAssertGreaterThanOrEqual(result.sigmaIrr, 0)
        XCTAssertTrue(result.work.isFinite)
    }

    func testGroundingFiresWhenWorkAccumulates() async {
        let controller = CrooksCycleController(
            deltaG: -0.01, // tiny free-energy floor → easy grounding
            actuators: ActuatorBus.makeProduction(),
            crown: CrownController(),
            mapper: DeltaHRVFlexAIDMapper()
        )
        var grounded = false
        for _ in 0..<40 {
            let r = await controller.update(
                deltaHRV: 2.0,
                flexAIDDeltaS: 2.0,
                crownBeta: 1.0,
                bpm: 160
            )
            if r.didGround {
                grounded = true
                break
            }
        }
        XCTAssertTrue(grounded, "expected grounding after sustained high work")
        let snap = await controller.snapshot()
        XCTAssertGreaterThanOrEqual(snap.sigmaIrr, 0)
    }

    /// After a full `update()` that grounds, beat sync and crown must retain recovery policy.
    /// Regression: end-of-tick broadcast used to overwrite groundingBPM/β with the input.
    func testGroundingPolicyPersistsOnBeatAndCrown() async {
        let beat = UniversalBeatSync()
        let crown = CrownController(beatSync: beat)
        let airPods = AirPodsCrownBetaController(beatSync: beat)
        let bus = ActuatorBus(channels: [
            BeatSyncActuatorChannel(beatSync: beat),
            CrownActuatorChannel(crown: crown),
            AirPodsCrownActuatorChannel(airPods: airPods),
            BreathingGuideActuatorChannel(),
            SessionLogActuatorChannel()
        ])
        let controller = CrooksCycleController(
            deltaG: -0.01,
            actuators: bus,
            crown: crown,
            mapper: DeltaHRVFlexAIDMapper()
        )

        let inputBeta = 0.80
        let inputBPM = 170.0
        var grounded = false

        for _ in 0..<50 {
            let r = await controller.update(
                deltaHRV: 3.0,
                flexAIDDeltaS: 3.0,
                crownBeta: inputBeta,
                bpm: inputBPM
            )
            if r.didGround {
                grounded = true
                let beatSnap = await beat.current()
                let betaAfter = await crown.currentBeta()
                let airSnap = await airPods.snapshot()

                XCTAssertEqual(
                    beatSnap.bpm, CrooksCycleDefaults.groundingBPM, accuracy: 1e-9,
                    "grounding must leave UniversalBeatSync at recovery BPM, not input \(inputBPM)"
                )
                XCTAssertTrue(beatSnap.isGrounding, "beat snapshot must flag grounding")
                XCTAssertLessThan(
                    abs(betaAfter), abs(inputBeta) - 1e-6,
                    "crown β must remain damped after full update (was \(betaAfter), input \(inputBeta))"
                )
                XCTAssertEqual(
                    airSnap.bpm, CrooksCycleDefaults.groundingBPM, accuracy: 1e-9,
                    "AirPods route state must adopt grounding BPM"
                )
                XCTAssertTrue(airSnap.isGrounding)
                XCTAssertLessThan(abs(airSnap.beta), abs(inputBeta) - 1e-6)
                break
            }
        }
        XCTAssertTrue(grounded, "expected grounding under high work")
    }

    /// σ_irr minimization must keep accumulated irreversibility bounded under sustained high work.
    /// Without damp, 80 ticks × ~4 work would grow without bound.
    func testGroundingBoundsSigmaIrrUnderSustainedLoad() async {
        let controller = CrooksCycleController(
            deltaG: -0.01,
            actuators: ActuatorBus.makeProduction(),
            crown: CrownController(),
            mapper: DeltaHRVFlexAIDMapper()
        )
        var maxSigma = 0.0
        var groundCount = 0
        for _ in 0..<80 {
            let r = await controller.update(
                deltaHRV: 3.0,
                flexAIDDeltaS: 3.0,
                crownBeta: 1.0,
                bpm: 180
            )
            XCTAssertTrue(r.work.isFinite)
            XCTAssertTrue(r.sigmaIrr.isFinite)
            XCTAssertGreaterThanOrEqual(r.sigmaIrr, 0)
            maxSigma = max(maxSigma, r.sigmaIrr)
            if r.didGround { groundCount += 1 }
        }
        XCTAssertGreaterThan(groundCount, 0, "grounding must fire under load")
        // Undamped: 80 * maxAbsWork ≈ 320. Production damp must keep σ_irr far below that.
        XCTAssertLessThan(maxSigma, 50.0, "σ_irr minimization must bound accumulated irreversibility")
    }

    /// Grounding tick must reduce σ_irr vs the pre-minimize post-accumulation value.
    func testGroundingReducesSigmaIrrOnFire() async {
        let controller = CrooksCycleController(
            deltaG: -0.01,
            actuators: ActuatorBus.makeProduction(),
            crown: CrownController(),
            mapper: DeltaHRVFlexAIDMapper()
        )
        var reduced = false
        for _ in 0..<50 {
            let before = await controller.snapshot()
            let r = await controller.update(
                deltaHRV: 2.5,
                flexAIDDeltaS: 2.5,
                crownBeta: 1.0,
                bpm: 170
            )
            if r.didGround {
                // After add-work + minimize: sigma must be strictly less than
                // pre-tick sigma + |work| (undamped upper bound).
                let undampedUpper = before.sigmaIrr + abs(r.work) + 1e-9
                XCTAssertLessThan(r.sigmaIrr, undampedUpper)
                // And when pre-tick was already above threshold, post-minimize should drop.
                if before.sigmaIrr > CrooksCycleDefaults.groundingThreshold {
                    XCTAssertLessThan(r.sigmaIrr, before.sigmaIrr + abs(r.work) * 0.5)
                    reduced = true
                    break
                }
                // First ground from below threshold: still prove damp vs undamped.
                reduced = r.sigmaIrr < undampedUpper
                if reduced { break }
            }
        }
        XCTAssertTrue(reduced, "expected at least one grounding reduction event")
    }

    func testControllerSurvivesNaNInfInputs() async {
        let controller = CrooksCycleController(
            actuators: ActuatorBus.makeProduction(),
            crown: CrownController(),
            mapper: DeltaHRVFlexAIDMapper()
        )
        let r = await controller.update(
            deltaHRV: .nan,
            flexAIDDeltaS: .infinity,
            crownBeta: .nan,
            bpm: -.infinity
        )
        XCTAssertTrue(r.work.isFinite)
        XCTAssertTrue(r.sigmaIrr.isFinite)
        XCTAssertGreaterThanOrEqual(r.sigmaIrr, 0)
        let snap = await controller.snapshot()
        XCTAssertTrue(snap.wFwd.isFinite)
        XCTAssertTrue(snap.wRev.isFinite)
    }

    func testPhaseFlipOnNearReversible() async {
        let controller = CrooksCycleController(
            deltaG: -8.7,
            actuators: ActuatorBus.makeProduction(),
            crown: CrownController(),
            mapper: DeltaHRVFlexAIDMapper()
        )
        // Single tiny update → total work near 0 → below reversibility threshold.
        let r = await controller.update(
            deltaHRV: 0,
            flexAIDDeltaS: 0,
            crownBeta: 0,
            bpm: CrooksCycleDefaults.nominalBPM
        )
        // With zero work, σ_irr ≈ 0 < 0.03 → phase flip expected (no grounding).
        XCTAssertFalse(r.didGround)
        XCTAssertTrue(r.didFlipPhase, "near-reversible tick must flip phase")
        XCTAssertEqual(r.phase, .reverse)
    }

    func testResetClearsState() async {
        let controller = CrooksCycleController(
            actuators: ActuatorBus.makeProduction(),
            crown: CrownController(),
            mapper: DeltaHRVFlexAIDMapper()
        )
        _ = await controller.update(deltaHRV: 1, flexAIDDeltaS: -1, crownBeta: 0.3, bpm: 140)
        await controller.reset()
        let snap = await controller.snapshot()
        XCTAssertEqual(snap.wFwd, 0, accuracy: 1e-12)
        XCTAssertEqual(snap.wRev, 0, accuracy: 1e-12)
        XCTAssertEqual(snap.phase, .forward)
        XCTAssertEqual(snap.cycleCount, 0)
        XCTAssertEqual(snap.sigmaIrr, 0, accuracy: 1e-12)
    }

    func testCrownBetaRejectsNaN() {
        var dial = CrownBetaDial(beta: 0.5)
        dial.setBeta(.nan)
        XCTAssertEqual(dial.beta, 0, accuracy: 1e-12)
        dial.setBeta(0.4)
        dial.applyCrownDelta(.infinity)
        XCTAssertTrue(dial.beta.isFinite)
        XCTAssertLessThanOrEqual(abs(dial.beta), 1)
    }

    func testBeatSyncRejectsNaNBPM() async {
        let sync = UniversalBeatSync()
        let snap = await sync.broadcast(bpm: .nan, beta: .nan, grounding: false)
        XCTAssertTrue(snap.bpm.isFinite)
        XCTAssertEqual(snap.bpm, CrooksCycleDefaults.nominalBPM, accuracy: 1e-9)
        XCTAssertEqual(snap.crownBeta, 0, accuracy: 1e-9)
    }

    // MARK: - PharmaControlSessionManager

    func testSessionManagerTickFromSCI() async {
        let manager = PharmaControlSessionManager(
            controller: CrooksCycleController(
                actuators: ActuatorBus.makeProduction(),
                crown: CrownController(),
                mapper: DeltaHRVFlexAIDMapper()
            ),
            crown: CrownController(),
            beatSync: UniversalBeatSync(),
            mapper: DeltaHRVFlexAIDMapper()
        )
        await manager.start()
        let r1 = await manager.tickFromSCI(sciScore: 0.4, bpm: 120)
        XCTAssertTrue(r1.work.isFinite)
        let r2 = await manager.tickFromSCI(sciScore: 0.8, bpm: 118)
        // Rising SCI → negative deltaHRV (collapse) → work changes
        XCTAssertTrue(r2.work.isFinite)

        let snap = await manager.snapshot()
        XCTAssertTrue(snap.isRunning)
        XCTAssertEqual(snap.tickCount, 2)
        XCTAssertFalse(snap.sigmaIrrDisplay.isEmpty)

        await manager.stop()
        let stopped = await manager.snapshot()
        XCTAssertFalse(stopped.isRunning)
    }

    func testSessionManagerCrownDelta() async {
        let crown = CrownController()
        let manager = PharmaControlSessionManager(
            controller: CrooksCycleController(
                actuators: ActuatorBus(channels: []),
                crown: crown,
                mapper: DeltaHRVFlexAIDMapper()
            ),
            crown: crown,
            beatSync: UniversalBeatSync(),
            mapper: DeltaHRVFlexAIDMapper()
        )
        let beta = await manager.applyCrownDelta(5.0)
        XCTAssertNotEqual(beta, 0)
    }

    func testReferenceDeltaSFromProfiles() async {
        let manager = PharmaControlSessionManager()
        let morphine = manager.referenceDeltaS(for: "morphine")
        XCTAssertEqual(morphine, -2.4, accuracy: 0.01)
        let unknown = manager.referenceDeltaS(for: "not_a_drug_xyz")
        XCTAssertEqual(unknown, 0, accuracy: 1e-12)
    }

    // MARK: - Thermodynamic phase

    func testPhaseFlipHelper() {
        XCTAssertEqual(ThermodynamicPhase.forward.flipped, .reverse)
        XCTAssertEqual(ThermodynamicPhase.reverse.flipped, .forward)
    }
}

// MARK: - Test helpers

private actor ListenerCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}
