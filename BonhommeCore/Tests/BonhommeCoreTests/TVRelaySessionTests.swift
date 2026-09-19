import XCTest
@testable import BonhommeCore

final class TVRelaySessionTests: XCTestCase {
    private func payload(remaining: Double = 10) -> TVDisplayPayload {
        TVDisplayPayload(currentPose: PoseCatalog.seatedMountain, poseTimeRemaining: remaining,
                         totalPoseTime: 30, biofeedback: BiofeedbackSnapshot(), sessionElapsed: 20,
                         isPaused: false, sequenceIndex: 0, sequenceTotal: 1)
    }

    func testPairingRoundTripKeepsHighEntropyKeyOutOfServiceName() throws {
        let invitation = try TVRelayPairing.generate()
        XCTAssertEqual(invitation.code.count, 43)
        XCTAssertFalse(invitation.serviceName.contains(invitation.code))
        XCTAssertEqual(TVRelayPairing.identifier(serviceName: invitation.serviceName), invitation.id)
        let decoded = try TVRelayPairing(url: invitation.url)
        XCTAssertEqual(decoded.id, invitation.id)
        XCTAssertEqual(decoded.code, invitation.code)
        XCTAssertNotEqual(try TVRelayPairing.generate().code, invitation.code)
    }

    func testPairingRejectsShortPinAndWrongURL() throws {
        XCTAssertThrowsError(try TVRelayPairing(id: UUID(), code: "123456"))
        XCTAssertThrowsError(try TVRelayPairing(id: UUID(), code: String(repeating: "!", count: 43)))
        let invitation = try TVRelayPairing.generate()
        let malicious = try XCTUnwrap(URL(string: invitation.url.absoluteString.replacingOccurrences(of: "natural-tv:", with: "https:")))
        XCTAssertThrowsError(try TVRelayPairing(url: malicious))
        let duplicate = try XCTUnwrap(URL(string: invitation.url.absoluteString + "&key=123456"))
        XCTAssertThrowsError(try TVRelayPairing(url: duplicate))
        XCTAssertNil(TVRelayPairing.identifier(serviceName: "Someone else's TV"))
    }

    func testReceiverRejectsOldSequenceAndDifferentSession() {
        var state = TVRelayReceiveState()
        let id = UUID()
        XCTAssertTrue(state.accept(TVRelayMessage(sessionID: id, sequence: 2, kind: .state, payload: payload()), at: 1))
        XCTAssertFalse(state.accept(TVRelayMessage(sessionID: id, sequence: 1, kind: .clear), at: 2))
        XCTAssertFalse(state.accept(TVRelayMessage(sessionID: UUID(), sequence: 3, kind: .clear), at: 2))
        XCTAssertNotNil(state.payload)
        XCTAssertTrue(state.isStale(at: 8), "Rejected messages must not refresh stale data")
    }

    func testClearAndEndNeverLeaveHealthDataOnScreen() {
        var state = TVRelayReceiveState()
        let id = UUID()
        XCTAssertTrue(state.accept(TVRelayMessage(sessionID: id, sequence: 1, kind: .state, payload: payload()), at: 1))
        XCTAssertTrue(state.accept(TVRelayMessage(sessionID: id, sequence: 2, kind: .clear), at: 2))
        XCTAssertNil(state.payload)
        XCTAssertTrue(state.accept(TVRelayMessage(sessionID: id, sequence: 3, kind: .state, payload: payload()), at: 3))
        XCTAssertTrue(state.accept(TVRelayMessage(sessionID: id, sequence: 4, kind: .end), at: 4))
        XCTAssertTrue(state.ended)
        XCTAssertNil(state.payload)
        XCTAssertFalse(state.accept(TVRelayMessage(sessionID: id, sequence: 5, kind: .state, payload: payload()), at: 5))
    }

    func testReceiverRejectsMalformedAndUnsupportedMessages() {
        var state = TVRelayReceiveState()
        let id = UUID()
        XCTAssertFalse(state.accept(TVRelayMessage(sessionID: id, sequence: 1, kind: .state), at: 0))
        XCTAssertFalse(state.accept(TVRelayMessage(sessionID: id, sequence: 1, kind: .state, payload: payload(remaining: -1)), at: 0))
        XCTAssertFalse(state.accept(TVRelayMessage(sessionID: id, sequence: 1, kind: .clear, payload: payload()), at: 0))
        var future = TVRelayMessage(sessionID: id, sequence: 1, kind: .clear)
        future.version = 2
        XCTAssertFalse(state.accept(future, at: 0))
        XCTAssertNil(state.payload)
    }

    func testOneInFlightRetainsOnlyLatestPendingFrame() {
        var buffer = TVRelayLatestFrameBuffer()
        buffer.offer(Data([1]))
        XCTAssertEqual(buffer.takeNext(), Data([1]))
        for value in 2...100 { buffer.offer(Data([UInt8(value)])) }
        XCTAssertNil(buffer.takeNext(), "No parallel send while the first is in flight")
        buffer.completed()
        XCTAssertEqual(buffer.takeNext(), Data([100]))
        buffer.completed()
        XCTAssertNil(buffer.takeNext())
        buffer.offer(Data([2])); buffer.reset()
        XCTAssertNil(buffer.takeNext())
        XCTAssertFalse(buffer.isSending)
    }

    func testFramingAcceptsUnalignedSlicesAndRejectsEmptyBody() {
        let storage = Data([0xFF, 0, 0, 0, 10])
        XCTAssertEqual(TVRelayFraming.decodeBodyLength(fromHeader: storage.dropFirst()), 10)
        XCTAssertNil(TVRelayFraming.encodeLengthPrefixed(Data()))
    }
}
