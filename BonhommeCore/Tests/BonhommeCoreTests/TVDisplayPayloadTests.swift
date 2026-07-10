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
        // Payload init always strips insight maps for wire size.
        XCTAssertTrue(decoded.biofeedback.insights.isEmpty)
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

    func testStrippedForRelayClearsInsights() {
        let insight = AnalysisInsight(
            signalType: .heartRateVariability,
            score: 0.9,
            trend: .improving,
            status: .normal,
            summary: LocalizedString(en: "ok", fr: "ok", es: "ok", ja: "ok", zh: "ok", ko: "ok", ru: "ok", de: "ok", ar: "ok")
        )
        let full = BiofeedbackSnapshot(
            heartRate: 80,
            sciScore: 0.9,
            sciTrend: .improving,
            activeCalories: 10,
            insights: [.heartRateVariability: insight]
        )
        let stripped = full.strippedForRelay()
        XCTAssertTrue(stripped.insights.isEmpty)
        XCTAssertEqual(stripped.heartRate, 80)
        XCTAssertEqual(stripped.sciScore, 0.9)
    }

    func testFeedbackInsightsDefaultExcludesInsightsMap() {
        let insight = AnalysisInsight(
            signalType: .heartRateVariability,
            score: 0.5,
            trend: .stable,
            status: .normal,
            summary: LocalizedString(en: "s", fr: "s", es: "s", ja: "s", zh: "s", ko: "s", ru: "s", de: "s", ar: "s")
        )
        let snap = BiofeedbackSnapshot(
            heartRate: 70,
            activeCalories: 1,
            feedbackInsights: [.heartRateVariability: insight]
        )
        XCTAssertEqual(snap.sciScore, 0.5)
        XCTAssertTrue(snap.insights.isEmpty)

        let withInsights = BiofeedbackSnapshot(
            heartRate: 70,
            activeCalories: 1,
            feedbackInsights: [.heartRateVariability: insight],
            includeInsights: true
        )
        XCTAssertEqual(withInsights.insights.count, 1)
    }

    // MARK: - TVRelayFraming (pure helpers)

    func testLengthPrefixedRoundTrip() throws {
        let body = Data("{\"ok\":true}".utf8)
        let frame = try XCTUnwrap(TVRelayFraming.encodeLengthPrefixed(body))
        let split = try XCTUnwrap(TVRelayFraming.splitFrame(frame))
        XCTAssertEqual(split.length, body.count)
        XCTAssertEqual(split.body, body)
    }

    func testDecodeBodyLengthRejectsOversized() {
        var huge = UInt32(TVRelayFraming.maxPayloadBytes + 1).bigEndian
        let header = Data(bytes: &huge, count: 4)
        XCTAssertNil(TVRelayFraming.decodeBodyLength(fromHeader: header))
    }

    func testDecodeBodyLengthRejectsZeroAndShortHeader() {
        var zero = UInt32(0).bigEndian
        XCTAssertNil(TVRelayFraming.decodeBodyLength(fromHeader: Data(bytes: &zero, count: 4)))
        XCTAssertNil(TVRelayFraming.decodeBodyLength(fromHeader: Data([0x00, 0x01])))
    }

    func testEncodeRejectsOversizedBody() {
        let body = Data(repeating: 0xAB, count: TVRelayFraming.maxPayloadBytes + 1)
        XCTAssertNil(TVRelayFraming.encodeLengthPrefixed(body))
    }

    func testPayloadSerializationUnderRecommendedBudget() throws {
        let pose = PoseCatalog.seatedWarriorII
        let payload = TVDisplayPayload(
            currentPose: pose,
            poseTimeRemaining: 25,
            totalPoseTime: 40,
            biofeedback: BiofeedbackSnapshot(
                heartRate: 110,
                heartRateVariability: 38,
                sciScore: 0.65,
                sciTrend: .stable,
                activeCalories: 55
            ),
            sessionElapsed: 180,
            isPaused: false,
            sequenceIndex: 5,
            sequenceTotal: 16
        )
        let data = try JSONEncoder().encode(payload)
        XCTAssertLessThan(data.count, TVRelayFraming.recommendedMaxPayloadBytes)
        XCTAssertNotNil(TVRelayFraming.encodeLengthPrefixed(data))
    }
}
