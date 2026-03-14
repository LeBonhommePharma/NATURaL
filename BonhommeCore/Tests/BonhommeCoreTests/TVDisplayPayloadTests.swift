import XCTest
@testable import BonhommeCore

final class TVDisplayPayloadTests: XCTestCase {

    func testPayloadCodableRoundTrip() throws {
        let pose = PoseCatalog.seatedMountain
        let snapshot = BiofeedbackSnapshot(
            heartRate: 72,
            heartRateVariability: 45,
            sciScore: 0.85,
            sciTrend: .improving,
            activeCalories: 34.5,
            timestamp: Date()
        )
        let payload = TVDisplayPayload(
            currentPose: pose,
            poseTimeRemaining: 15,
            totalPoseTime: 30,
            biofeedback: snapshot,
            sessionElapsed: 120,
            isPaused: false,
            sequenceIndex: 2,
            sequenceTotal: 10
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(TVDisplayPayload.self, from: data)

        XCTAssertEqual(decoded.currentPose.id, pose.id)
        XCTAssertEqual(decoded.poseTimeRemaining, 15)
        XCTAssertEqual(decoded.totalPoseTime, 30)
        XCTAssertEqual(decoded.sessionElapsed, 120)
        XCTAssertFalse(decoded.isPaused)
        XCTAssertEqual(decoded.sequenceIndex, 2)
        XCTAssertEqual(decoded.sequenceTotal, 10)
        XCTAssertEqual(decoded.biofeedback.heartRate, 72)
        XCTAssertEqual(decoded.biofeedback.sciScore, 0.85)
        XCTAssertEqual(decoded.biofeedback.sciTrend, .improving)
    }

    func testPayloadWithNilBiofeedback() throws {
        let pose = PoseCatalog.seatedMeditation
        let snapshot = BiofeedbackSnapshot(
            heartRate: nil,
            sciScore: nil,
            sciTrend: .stable,
            activeCalories: 0
        )
        let payload = TVDisplayPayload(
            currentPose: pose,
            poseTimeRemaining: 60,
            totalPoseTime: 60,
            biofeedback: snapshot,
            sessionElapsed: 0,
            isPaused: true,
            sequenceIndex: 0,
            sequenceTotal: 1
        )

        let data = try JSONEncoder().encode(payload)
        let decoded = try JSONDecoder().decode(TVDisplayPayload.self, from: data)

        XCTAssertNil(decoded.biofeedback.heartRate)
        XCTAssertNil(decoded.biofeedback.sciScore)
        XCTAssertTrue(decoded.isPaused)
    }

    func testBiofeedbackSnapshotDefaults() {
        let snapshot = BiofeedbackSnapshot()
        XCTAssertNil(snapshot.heartRate)
        XCTAssertNil(snapshot.heartRateVariability)
        XCTAssertNil(snapshot.sciScore)
        XCTAssertEqual(snapshot.sciTrend, .stable)
        XCTAssertEqual(snapshot.activeCalories, 0)
    }

    func testSCITrendCodable() throws {
        for trend in [SCITrend.improving, .stable, .declining] {
            let data = try JSONEncoder().encode(trend)
            let decoded = try JSONDecoder().decode(SCITrend.self, from: data)
            XCTAssertEqual(decoded, trend)
        }
    }
}
