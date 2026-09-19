import Foundation

public struct TVRelayMessage: Codable, Sendable {
    public enum Kind: String, Codable, Sendable { case state, clear, end }
    public var version = 1
    public let sessionID: UUID
    public let sequence: UInt64
    public let kind: Kind
    public let payload: TVDisplayPayload?
    public init(sessionID: UUID, sequence: UInt64, kind: Kind, payload: TVDisplayPayload? = nil) {
        self.sessionID = sessionID; self.sequence = sequence; self.kind = kind; self.payload = payload
    }
}

/// Exactly one authenticated session per connection. Freshness uses receipt time,
/// so differences between the phone and television clocks cannot keep stale data alive.
public struct TVRelayReceiveState {
    public static let freshnessTimeout: TimeInterval = 6
    public private(set) var payload: TVDisplayPayload?
    public private(set) var ended = false
    private var sessionID: UUID?
    private var sequence: UInt64 = 0
    private var lastReceipt: TimeInterval?
    public init() {}
    @discardableResult public mutating func accept(_ message: TVRelayMessage, at now: TimeInterval) -> Bool {
        guard now.isFinite, !ended, message.version == 1, message.sequence > sequence,
              sessionID == nil || sessionID == message.sessionID else { return false }
        if message.kind == .state {
            guard let p = message.payload, p.poseTimeRemaining.isFinite, p.poseTimeRemaining >= 0,
                  p.totalPoseTime.isFinite, p.totalPoseTime >= 0, p.sessionElapsed.isFinite, p.sessionElapsed >= 0,
                  p.sequenceIndex >= 0, p.sequenceTotal >= 0,
                  p.sequenceTotal == 0 || p.sequenceIndex < p.sequenceTotal else { return false }
        } else if message.payload != nil { return false }
        sessionID = message.sessionID; sequence = message.sequence; lastReceipt = now
        payload = message.kind == .state ? message.payload : nil
        ended = message.kind == .end
        return true
    }
    public func isStale(at now: TimeInterval) -> Bool {
        guard let lastReceipt else { return false }
        return !now.isFinite || now < lastReceipt || now - lastReceipt > Self.freshnessTimeout
    }
}

/// Backpressure: at most one frame submitted to NWConnection and one pending
/// replacement. A slow television never accumulates an unbounded workout history.
public struct TVRelayLatestFrameBuffer {
    public private(set) var isSending = false
    private var pending: Data?
    public init() {}
    public mutating func offer(_ data: Data) { pending = data }
    public mutating func takeNext() -> Data? {
        guard !isSending, let data = pending else { return nil }
        pending = nil; isSending = true; return data
    }
    public mutating func completed() { isSending = false }
    public mutating func reset() { isSending = false; pending = nil }
}
