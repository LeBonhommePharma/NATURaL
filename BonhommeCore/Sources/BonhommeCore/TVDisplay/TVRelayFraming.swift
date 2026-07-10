import Foundation

/// Length-prefixed framing for Bonjour / NWConnection TV relay (iOS ↔ tvOS).
///
/// Wire format: `UInt32` big-endian body length + UTF-8 JSON body.
/// Pure helpers so payload bounds and framing are unit-testable without Network.framework.
public enum TVRelayFraming {
    /// Practical upper bound for a single `TVDisplayPayload` frame.
    /// Rejects pathological lengths that would allocate huge buffers on receive.
    public static let maxPayloadBytes = 64 * 1024

    /// Soft target for a well-formed lean payload (no full insight dictionaries).
    public static let recommendedMaxPayloadBytes = 10_000

    /// Builds a length-prefixed frame. Returns `nil` if body exceeds `maxPayloadBytes`.
    public static func encodeLengthPrefixed(_ body: Data) -> Data? {
        guard body.count <= maxPayloadBytes else { return nil }
        var length = UInt32(body.count).bigEndian
        var frame = Data(bytes: &length, count: 4)
        frame.append(body)
        return frame
    }

    /// Parses a 4-byte big-endian length header.
    /// Returns `nil` if header size is wrong, length is zero, or exceeds `maxPayloadBytes`.
    public static func decodeBodyLength(fromHeader header: Data) -> Int? {
        guard header.count == 4 else { return nil }
        let length = header.withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        guard length > 0, length <= UInt32(maxPayloadBytes) else { return nil }
        return Int(length)
    }

    /// Splits a complete frame into (length, body). Returns `nil` if truncated or oversized.
    public static func splitFrame(_ frame: Data) -> (length: Int, body: Data)? {
        guard frame.count >= 4 else { return nil }
        guard let length = decodeBodyLength(fromHeader: frame.prefix(4)) else { return nil }
        guard frame.count >= 4 + length else { return nil }
        let body = frame.subdata(in: 4..<(4 + length))
        return (length, body)
    }
}
