import Foundation

// MARK: - Presence record (iCloud KVS / CloudKit / WCSession)

/// Heartbeat published by each Apple device on the same iCloud account so
/// ClusterFleet can auto-upsert peers (iPhone, iPad, Mac) without Multipeer.
///
/// Wire format is JSON under `NSUbiquitousKeyValueStore` keys
/// `natural.fleet.presence.<deviceId>` (see app-layer coordinator).
public struct FleetPresenceRecord: Sendable, Codable, Equatable, Identifiable {
    public var id: String { deviceId }

    public var deviceId: String
    public var displayName: String
    public var platform: FleetPlatform
    /// Measured AVAudioSession / engine IO buffer (ms), when running.
    public var bufferLatencyMs: Double?
    /// Optional total path estimate (ms) if the publisher knows more than buffer.
    public var pathLatencyMs: Double?
    public var isActive: Bool
    public var sessionActive: Bool
    public var updatedAt: Date
    /// Schema version for forward compatibility.
    public var schemaVersion: Int

    public static let currentSchemaVersion = 1
    /// Peers older than this are treated as inactive (5 minutes).
    public static let defaultStaleInterval: TimeInterval = 300
    /// Ubiquitous key prefix (device id appended).
    public static let kvsKeyPrefix = "natural.fleet.presence."

    public init(
        deviceId: String,
        displayName: String,
        platform: FleetPlatform,
        bufferLatencyMs: Double? = nil,
        pathLatencyMs: Double? = nil,
        isActive: Bool = true,
        sessionActive: Bool = false,
        updatedAt: Date = Date(),
        schemaVersion: Int = FleetPresenceRecord.currentSchemaVersion
    ) {
        self.deviceId = deviceId
        self.displayName = displayName
        self.platform = platform
        self.bufferLatencyMs = bufferLatencyMs
        self.pathLatencyMs = pathLatencyMs
        self.isActive = isActive
        self.sessionActive = sessionActive
        self.updatedAt = updatedAt
        self.schemaVersion = schemaVersion
    }

    public static func kvsKey(for deviceId: String) -> String {
        kvsKeyPrefix + deviceId
    }

    public static func deviceId(fromKVSKey key: String) -> String? {
        guard key.hasPrefix(kvsKeyPrefix) else { return nil }
        let id = String(key.dropFirst(kvsKeyPrefix.count))
        return id.isEmpty ? nil : id
    }
}

// MARK: - Stable local device identity (pure helpers)

/// Helpers for building local presence identity without UIKit/AppKit coupling.
public enum FleetLocalIdentity: Sendable {
    public static let userDefaultsKey = "natural.clusterFleet.deviceId"

    /// Return existing id from a string store or create a new UUID string.
    public static func stableDeviceId(stored: String?, persist: (String) -> Void) -> String {
        if let stored, !stored.isEmpty { return stored }
        let id = UUID().uuidString
        persist(id)
        return id
    }

    /// Human-readable default name for a platform.
    public static func defaultDisplayName(platform: FleetPlatform, systemName: String?) -> String {
        if let systemName, !systemName.isEmpty { return systemName }
        switch platform {
        case .iOS: return "iPhone"
        case .iPadOS: return "iPad"
        case .macOS: return "Mac"
        case .watchOS: return "Apple Watch"
        case .tvOS: return "Apple TV"
        case .visionOS: return "Vision"
        case .unknown: return "Apple Device"
        }
    }
}

// MARK: - Decode batch

public enum FleetPresenceCodec: Sendable {
    public static func encode(_ record: FleetPresenceRecord) throws -> Data {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return try enc.encode(record)
    }

    public static func decode(_ data: Data) throws -> FleetPresenceRecord {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return try dec.decode(FleetPresenceRecord.self, from: data)
    }

    /// Decode all presence values from a key→data map (KVS snapshot).
    public static func decodeAll(from keyValues: [String: Data]) -> [FleetPresenceRecord] {
        var out: [FleetPresenceRecord] = []
        out.reserveCapacity(keyValues.count)
        for (key, data) in keyValues {
            guard key.hasPrefix(FleetPresenceRecord.kvsKeyPrefix) else { continue }
            if let record = try? decode(data) {
                out.append(record)
            }
        }
        return out
    }
}
