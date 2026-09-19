import XCTest
@testable import BonhommeCore
@testable import Bonhomme

/// Hosted iOS tests for the real coordinator state and relay encoding.
/// These do not browse, connect to a television, or claim transport validation.
final class TVDisplayCoordinatorTests: XCTestCase {

    // MARK: - Real coordinator consent and lifecycle (no discovery or pairing)

    @MainActor
    func testCoordinatorDoesNotPublishBeforeOptIn() {
        let coordinator = TVDisplayCoordinator()
        defer { coordinator.stopTVDiscovery() }

        coordinator.send(payload: samplePayload())

        XCTAssertFalse(coordinator.displayEnabled)
        XCTAssertNil(coordinator.currentPayload)
        XCTAssertFalse(coordinator.nativeConnected)
        XCTAssertFalse(coordinator.nativeConnecting)
        XCTAssertTrue(coordinator.discoveredTVs.isEmpty)
        XCTAssertEqual(coordinator.mode, .idle)
    }

    @MainActor
    func testDisabledSharingRejectsNextPayloadAndClearsPriorDisplay() throws {
        let coordinator = TVDisplayCoordinator()
        defer { coordinator.stopTVDiscovery() }
        coordinator.displayEnabled = true
        coordinator.send(payload: samplePayload())
        XCTAssertEqual(try XCTUnwrap(coordinator.currentPayload).sessionElapsed, 20)

        coordinator.displayEnabled = false
        coordinator.send(payload: samplePayload(elapsed: 99))

        XCTAssertNil(coordinator.currentPayload, "Revoked display must not retain or replace health/pose data")
        XCTAssertFalse(coordinator.nativeConnected)
        XCTAssertFalse(coordinator.nativeConnecting)
    }

    @MainActor
    func testStopClearsPayloadAndRequiresFreshOptIn() throws {
        let coordinator = TVDisplayCoordinator()
        coordinator.displayEnabled = true
        coordinator.send(payload: samplePayload())
        XCTAssertNotNil(coordinator.currentPayload)

        coordinator.stopTVDiscovery()

        XCTAssertFalse(coordinator.displayEnabled)
        XCTAssertNil(coordinator.currentPayload)
        XCTAssertFalse(coordinator.nativeConnected)
        XCTAssertFalse(coordinator.nativeConnecting)
        XCTAssertTrue(coordinator.discoveredTVs.isEmpty)
        XCTAssertEqual(coordinator.mode, .idle)
        coordinator.send(payload: samplePayload(elapsed: 45))
        XCTAssertNil(coordinator.currentPayload, "Stopping must not implicitly authorize a later sender")

        coordinator.displayEnabled = true
        coordinator.send(payload: samplePayload(elapsed: 60))
        XCTAssertEqual(try XCTUnwrap(coordinator.currentPayload).sessionElapsed, 60)
        coordinator.stopTVDiscovery()
    }

    private func samplePayload(elapsed: TimeInterval = 20) -> TVDisplayPayload {
        TVDisplayPayload(currentPose: PoseCatalog.seatedMountain, poseTimeRemaining: 10,
                         totalPoseTime: 30, biofeedback: BiofeedbackSnapshot(),
                         sessionElapsed: elapsed, isPaused: false, sequenceIndex: 0, sequenceTotal: 1)
    }

    // MARK: - Payload Serialization

    func testPayloadSerializationSize() throws {
        let pose = PoseCatalog.seatedWarriorII
        let bio = BiofeedbackSnapshot(
            heartRate: 110,
            heartRateVariability: 38,
            sciScore: 0.65,
            sciTrend: .stable,
            activeCalories: 55
        )
        let payload = TVDisplayPayload(
            currentPose: pose,
            poseTimeRemaining: 25,
            totalPoseTime: 40,
            biofeedback: bio,
            sessionElapsed: 180,
            isPaused: false,
            sequenceIndex: 5,
            sequenceTotal: 16
        )

        let data = try JSONEncoder().encode(payload)
        // Should be well under the ~65KB WatchConnectivity/NWConnection practical limit
        XCTAssertLessThan(data.count, 10_000, "Payload too large: \(data.count) bytes")
    }

    func testLengthPrefixedFraming() throws {
        let pose = PoseCatalog.seatedMountain
        let payload = TVDisplayPayload(
            currentPose: pose,
            poseTimeRemaining: 10,
            totalPoseTime: 30,
            biofeedback: BiofeedbackSnapshot(),
            sessionElapsed: 20,
            isPaused: false,
            sequenceIndex: 0,
            sequenceTotal: 1
        )

        let jsonData = try JSONEncoder().encode(payload)
        let framed = try XCTUnwrap(TVRelayFraming.encodeLengthPrefixed(jsonData))
        let split = try XCTUnwrap(TVRelayFraming.splitFrame(framed))
        XCTAssertEqual(split.length, jsonData.count)

        let decoded = try JSONDecoder().decode(TVDisplayPayload.self, from: split.body)
        XCTAssertEqual(decoded.currentPose.id, "seated-mountain")
        // Nil biofeedback metrics remain nil after wire round-trip.
        XCTAssertNil(decoded.biofeedback.heartRate)
        XCTAssertNil(decoded.biofeedback.sciScore)
    }

    // MARK: - Bonjour Service Type

    func testBonjourServiceType() {
        // The service type must match between iOS browser and tvOS listener
        let serviceType = TVRelayPairing.serviceType
        XCTAssertEqual(serviceType, "_bonhomme._tcp")
        XCTAssertTrue(serviceType.hasPrefix("_"))
        XCTAssertTrue(serviceType.hasSuffix("._tcp"))
    }

    func testFramingRejectsPathologicalLength() {
        var huge = UInt32(TVRelayFraming.maxPayloadBytes + 100).bigEndian
        let header = Data(bytes: &huge, count: 4)
        XCTAssertNil(TVRelayFraming.decodeBodyLength(fromHeader: header))
    }
}
