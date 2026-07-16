import XCTest
@testable import BonhommeCore

final class ClusterFleetTests: XCTestCase {

    // MARK: - Latency optimizer

    func testLatencyOptimizerAlignsToSlowest() {
        let samples = [
            DeviceLatencySample(deviceId: "local", latencyMs: 8),
            DeviceLatencySample(deviceId: "airpods", latencyMs: 30),
            DeviceLatencySample(deviceId: "airplay", latencyMs: 80)
        ]
        let plan = AudioSyncLatencyOptimizer.optimize(latencies: samples, sigmaIrr: 0)
        XCTAssertEqual(plan.referenceLatencyMs, 80, accuracy: 1e-9)
        XCTAssertEqual(plan.delayMsByDevice["airplay"] ?? -1, 0, accuracy: 1e-9)
        XCTAssertEqual(plan.delayMsByDevice["airpods"] ?? -1, 50, accuracy: 1e-9)
        XCTAssertEqual(plan.delayMsByDevice["local"] ?? -1, 72, accuracy: 1e-9)
        XCTAssertEqual(plan.sigmaScale, 1.0, accuracy: 1e-9)
    }

    func testLatencyOptimizerShrinksUnderHighSigma() {
        let samples = [
            DeviceLatencySample(deviceId: "a", latencyMs: 10),
            DeviceLatencySample(deviceId: "b", latencyMs: 50)
        ]
        let calm = AudioSyncLatencyOptimizer.optimize(latencies: samples, sigmaIrr: 0)
        let stressed = AudioSyncLatencyOptimizer.optimize(latencies: samples, sigmaIrr: 0.5)
        XCTAssertGreaterThan(calm.delayMsByDevice["a"] ?? 0, stressed.delayMsByDevice["a"] ?? 0)
        XCTAssertEqual(stressed.sigmaScale, 0.75, accuracy: 1e-9)
    }

    func testLatencyOptimizerEmptyAndCap() {
        let empty = AudioSyncLatencyOptimizer.optimize(latencies: [])
        XCTAssertTrue(empty.delayMsByDevice.isEmpty)

        // Delay is applied to the *faster* path (low L). Cap max compensation.
        let plan = AudioSyncLatencyOptimizer.optimize(latencies: [
            DeviceLatencySample(deviceId: "fast", latencyMs: 0),
            DeviceLatencySample(deviceId: "slow", latencyMs: 1000)
        ])
        XCTAssertEqual(
            plan.delayMsByDevice["fast"] ?? -1,
            AudioSyncLatencyOptimizer.maxCompensationMs,
            accuracy: 1e-9
        )
    }

    func testPreferredIOBufferDurationAndBufferMs() {
        let dur = AudioSyncLatencyOptimizer.preferredIOBufferDuration(forTargetLatencyMs: 10)
        XCTAssertEqual(dur, 0.005, accuracy: 1e-9)
        let ms = AudioSyncLatencyOptimizer.bufferLatencyMs(frames: 256, sampleRate: 48_000)
        XCTAssertEqual(ms, 256.0 / 48_000.0 * 1000.0, accuracy: 1e-9)
    }

    // MARK: - Route kind resolution

    func testFleetRoutePortResolvesAirPodsVariants() {
        XCTAssertEqual(
            FleetRoutePort(uid: "1", portType: "BluetoothA2DP", portName: "LP’s AirPods Pro").resolvedKind(),
            .airPodsPro
        )
        XCTAssertEqual(
            FleetRoutePort(uid: "2", portType: "BluetoothA2DP", portName: "AirPods Max").resolvedKind(),
            .airPodsMax
        )
        XCTAssertEqual(
            FleetRoutePort(uid: "3", portType: "Speaker", portName: "Speaker").resolvedKind(),
            .builtInSpeaker
        )
        XCTAssertEqual(
            FleetRoutePort(uid: "4", portType: "AirPlay", portName: "Living Room").resolvedKind(),
            .airPlay
        )
    }

    // MARK: - ClusterFleet actor

    func testClusterFleetRefreshAndCompensation() async {
        let fleet = ClusterFleet()
        await fleet.refreshAudioRoutes([
            FleetRoutePort(uid: "sp", portType: "Speaker", portName: "Speaker"),
            FleetRoutePort(uid: "ap", portType: "BluetoothA2DP", portName: "AirPods Pro")
        ])
        var snap = await fleet.snapshot()
        XCTAssertEqual(snap.devices.count, 2)
        XCTAssertTrue(snap.hasAirPodsRoute)

        await fleet.updateMeasuredLatency(deviceId: "sp", latencyMs: 8)
        await fleet.updateMeasuredLatency(deviceId: "ap", latencyMs: 30)
        await fleet.setSigmaIrr(0)
        snap = await fleet.snapshot()
        let spDelay = snap.devices.first { $0.id == "sp" }?.compensationDelayMs ?? -1
        let apDelay = snap.devices.first { $0.id == "ap" }?.compensationDelayMs ?? -1
        XCTAssertEqual(apDelay, 0, accuracy: 1e-6)
        XCTAssertEqual(spDelay, 22, accuracy: 1e-6)
        XCTAssertEqual(snap.qualityProfile.preferSpatial, true)
    }

    func testClusterFleetSpatialModulation() async {
        let fleet = ClusterFleet()
        await fleet.applySpatialModulation(depth: 0.5, beta: -0.8)
        let snap = await fleet.snapshot()
        XCTAssertEqual(snap.spatialDepth, 0.5, accuracy: 1e-9)
        XCTAssertEqual(snap.listenerYawDegrees, -180, accuracy: 1e-9)
        XCTAssertEqual(snap.crownBeta, -0.8, accuracy: 1e-9)
    }

    func testClusterFleetPreservesWatchCompanion() async {
        let fleet = ClusterFleet()
        await fleet.upsertCompanion(id: "watch-1", kind: .watchCompanion, displayName: "Watch")
        await fleet.refreshAudioRoutes([
            FleetRoutePort(uid: "sp", portType: "Speaker", portName: "Speaker")
        ])
        let snap = await fleet.snapshot()
        XCTAssertEqual(snap.devices.count, 2)
        XCTAssertTrue(snap.devices.contains { $0.id == "watch-1" })
    }

    func testClusterFleetActuatorChannel() async {
        let fleet = ClusterFleet()
        let channel = ClusterFleetActuatorChannel(fleet: fleet)
        let r = await channel.execute(.beatBroadcast(bpm: 110, beta: 0.4, grounding: false))
        XCTAssertTrue(r.success)
        XCTAssertEqual(r.channelId, "cluster_fleet")
        let snap = await fleet.snapshot()
        XCTAssertEqual(snap.tempoBPM, 110, accuracy: 1e-9)
    }

    // MARK: - AirFoil quality

    func testAirFoilProfilesByFleet() {
        let local = [FleetDevice(id: "s", kind: .builtInSpeaker, displayName: "Speaker")]
        XCTAssertEqual(AirFoilQualityRouter.profile(for: local, targetLatencyMs: 10).label, "ultra_low_latency")

        let pods = [FleetDevice(id: "a", kind: .airPodsPro, displayName: "Pro")]
        XCTAssertTrue(AirFoilQualityRouter.profile(for: pods).preferSpatial)

        let airplay = [FleetDevice(id: "t", kind: .airPlay, displayName: "TV")]
        XCTAssertEqual(AirFoilQualityRouter.profile(for: airplay).maxFramesPerSlice, 1024)
    }

    // MARK: - Haptics

    func testHapticEngineSoftFailWithoutHardware() async {
        let engine = HapticFeedbackEngine()
        let r = await engine.playValidation(valid: true, intensity: 0.5)
        // Always succeeds (no-op on unsupported).
        XCTAssertTrue(r.success)
        let bio = await engine.playBiometricModulated(heartRateBPM: 90, score: 0.8)
        XCTAssertTrue(bio.success)
    }

    func testHapticActuatorChannel() async {
        let engine = HapticFeedbackEngine()
        let channel = HapticActuatorChannel(engine: engine)
        let r = await channel.execute(.grounding(sigmaIrr: 0.2, bpm: 140, beta: 0.3))
        XCTAssertTrue(r.success)
        XCTAssertEqual(r.channelId, "haptic_feedback")
    }

    // MARK: - Bus channel set

    func testProductionBusIncludesFleetAndHaptics() async {
        let bus = ActuatorBus.makeProduction()
        let ids = await bus.channelIds()
        XCTAssertTrue(ids.contains("cluster_fleet"))
        XCTAssertTrue(ids.contains("haptic_feedback"))
        XCTAssertTrue(ids.contains("universal_beat_sync"))
        XCTAssertEqual(ids.count, 8)
    }

    func testProductionBusGroundingAllSucceed() async {
        let bus = ActuatorBus.makeProduction()
        let results = await bus.executeGrounding(sigmaIrr: 0.2, bpm: 140, beta: 0.5)
        XCTAssertEqual(results.count, 8)
        for r in results {
            XCTAssertTrue(r.success, "channel \(r.channelId) failed: \(r.detail)")
        }
    }
}
