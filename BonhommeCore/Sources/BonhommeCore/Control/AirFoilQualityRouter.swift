import Foundation

// MARK: - Quality profile

/// Session audio quality policy derived from fleet composition + latency budget.
///
/// Named after AirFoil-class multi-output discipline: prefer stable high sample
/// rate, small IO buffers when the route can sustain them, and explicit
/// Bluetooth / AirPlay trade-offs — **not** fake 96 kHz mutations of engine formats.
public struct AirFoilQualityProfile: Sendable, Equatable {
    public var sampleRate: Double
    /// Preferred `AVAudioSession` IO buffer duration (seconds).
    public var ioBufferDuration: TimeInterval
    /// Frames/slice hint for AudioUnit / engine render quantum.
    public var maxFramesPerSlice: Int
    public var allowAirPlay: Bool
    public var allowBluetoothA2DP: Bool
    public var preferSpatial: Bool
    public var label: String

    public init(
        sampleRate: Double,
        ioBufferDuration: TimeInterval,
        maxFramesPerSlice: Int,
        allowAirPlay: Bool,
        allowBluetoothA2DP: Bool,
        preferSpatial: Bool,
        label: String
    ) {
        self.sampleRate = sampleRate
        self.ioBufferDuration = ioBufferDuration
        self.maxFramesPerSlice = maxFramesPerSlice
        self.allowAirPlay = allowAirPlay
        self.allowBluetoothA2DP = allowBluetoothA2DP
        self.preferSpatial = preferSpatial
        self.label = label
    }

    /// Balanced default for MusicKit + local dual engine.
    public static let standard = AirFoilQualityProfile(
        sampleRate: 48_000,
        ioBufferDuration: 0.01,
        maxFramesPerSlice: 512,
        allowAirPlay: true,
        allowBluetoothA2DP: true,
        preferSpatial: false,
        label: "standard"
    )

    /// Aggressive low-latency (built-in / wired; sub-10 ms target when hardware cooperates).
    public static let ultraLowLatency = AirFoilQualityProfile(
        sampleRate: 48_000,
        ioBufferDuration: 0.005,
        maxFramesPerSlice: 256,
        allowAirPlay: false,
        allowBluetoothA2DP: false,
        preferSpatial: false,
        label: "ultra_low_latency"
    )

    /// AirPods / spatial path — slightly larger buffer for Bluetooth stability.
    public static let spatialAirPods = AirFoilQualityProfile(
        sampleRate: 48_000,
        ioBufferDuration: 0.01,
        maxFramesPerSlice: 512,
        allowAirPlay: true,
        allowBluetoothA2DP: true,
        preferSpatial: true,
        label: "spatial_airpods"
    )

    /// AirPlay / TV relay — larger buffer, stability over absolute latency.
    public static let airPlayStable = AirFoilQualityProfile(
        sampleRate: 48_000,
        ioBufferDuration: 0.02,
        maxFramesPerSlice: 1024,
        allowAirPlay: true,
        allowBluetoothA2DP: true,
        preferSpatial: true,
        label: "airplay_stable"
    )
}

// MARK: - Router

/// Chooses an `AirFoilQualityProfile` from fleet membership and latency budget.
public enum AirFoilQualityRouter: Sendable {
    public static func profile(
        for devices: [FleetDevice],
        targetLatencyMs: Double = 10
    ) -> AirFoilQualityProfile {
        let active = devices.filter(\.isActive)
        guard !active.isEmpty else { return .standard }

        let hasAirPlay = active.contains { $0.kind == .airPlay || $0.kind == .tvRelay }
        let hasAirPods = active.contains {
            switch $0.kind {
            case .airPods, .airPodsPro, .airPodsMax: return true
            default: return false
            }
        }
        let hasBT = active.contains { $0.kind == .bluetoothA2DP || $0.kind.isHeadphoneRoute && $0.kind != .wiredHeadphones }
        let onlyLocal = active.allSatisfy {
            $0.kind == .builtInSpeaker || $0.kind == .wiredHeadphones
        }

        if hasAirPlay {
            return .airPlayStable
        }
        if hasAirPods {
            var p = AirFoilQualityProfile.spatialAirPods
            // Tighten buffer slightly for Pro/Max when target is aggressive.
            if targetLatencyMs <= 12 {
                p = AirFoilQualityProfile(
                    sampleRate: 48_000,
                    ioBufferDuration: 0.008,
                    maxFramesPerSlice: 384,
                    allowAirPlay: true,
                    allowBluetoothA2DP: true,
                    preferSpatial: true,
                    label: "spatial_airpods_tight"
                )
            }
            return p
        }
        if onlyLocal && targetLatencyMs <= 10 {
            return .ultraLowLatency
        }
        if hasBT {
            return .standard
        }
        return .standard
    }

    /// Activate policy bookkeeping for a session (pure; session apply is app-layer).
    public static func activateProMode(devices: [FleetDevice], targetLatencyMs: Double = 10) -> AirFoilQualityProfile {
        profile(for: devices, targetLatencyMs: targetLatencyMs)
    }
}
