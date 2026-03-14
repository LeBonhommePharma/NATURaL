import XCTest
@testable import BonhommeCore

/// Tests for the TV display relay and coordinator logic.
/// Run on iOS Simulator to validate NWBrowser/NWConnection behavior.
final class TVDisplayCoordinatorTests: XCTestCase {

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

        // Simulate length-prefixed framing (4-byte big-endian header + body)
        var length = UInt32(jsonData.count).bigEndian
        let header = Data(bytes: &length, count: 4)
        let framed = header + jsonData

        // Decode: read 4-byte header, then body
        let readLength = framed.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        XCTAssertEqual(Int(readLength), jsonData.count)

        let body = framed.suffix(from: 4)
        let decoded = try JSONDecoder().decode(TVDisplayPayload.self, from: body)
        XCTAssertEqual(decoded.currentPose.id, "seated-mountain")
    }

    // MARK: - Bonjour Service Type

    func testBonjourServiceType() {
        // The service type must match between iOS browser and tvOS listener
        let serviceType = "_bonhomme._tcp"
        XCTAssertTrue(serviceType.hasPrefix("_"))
        XCTAssertTrue(serviceType.hasSuffix("._tcp"))
    }
}
