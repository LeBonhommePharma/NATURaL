import Foundation

// MARK: - Fleet device model

/// Hardware / transport class for a ClusterFleet member.
///
/// iOS exposes a **single** `AVAudioSession` — multi-device identity is derived
/// from route ports, AirPlay, WatchConnectivity companions, and TVRelay peers,
/// **not** from multiple session instances.
public enum FleetDeviceKind: String, Sendable, Codable, CaseIterable, Equatable {
    case builtInSpeaker
    case wiredHeadphones
    case airPods
    case airPodsPro
    case airPodsMax
    case bluetoothA2DP
    case airPlay
    case carAudio
    case watchCompanion
    case tvRelay
    /// Same-iCloud Apple device peer (iPhone / iPad / Mac) via presence sync.
    case icloudPeer
    case unknown

    /// Typical one-way latency priors (ms) when hardware has not measured yet.
    public var defaultLatencyMs: Double {
        switch self {
        case .builtInSpeaker: return 8
        case .wiredHeadphones: return 6
        case .airPods, .airPodsPro: return 30
        case .airPodsMax: return 32
        case .bluetoothA2DP: return 40
        case .airPlay: return 80
        case .carAudio: return 50
        case .watchCompanion: return 45
        case .tvRelay: return 90
        case .icloudPeer: return 60
        case .unknown: return 25
        }
    }

    public var supportsSpatialAudio: Bool {
        switch self {
        case .airPods, .airPodsPro, .airPodsMax, .airPlay: return true
        default: return false
        }
    }

    public var isHeadphoneRoute: Bool {
        switch self {
        case .wiredHeadphones, .airPods, .airPodsPro, .airPodsMax, .bluetoothA2DP:
            return true
        default:
            return false
        }
    }

    /// Non-route devices that must survive `refreshAudioRoutes` replacement.
    public var isCompanionMembership: Bool {
        switch self {
        case .watchCompanion, .tvRelay, .icloudPeer:
            return true
        default:
            return false
        }
    }
}

/// OS family for iCloud peer presence (same Apple ID).
public enum FleetPlatform: String, Sendable, Codable, CaseIterable, Equatable {
    case iOS
    case iPadOS
    case macOS
    case watchOS
    case tvOS
    case visionOS
    case unknown

    public var displayLabel: String { rawValue }

    /// Map to fleet device kind for presence records.
    public var companionKind: FleetDeviceKind {
        switch self {
        case .watchOS: return .watchCompanion
        case .tvOS: return .tvRelay
        case .iOS, .iPadOS, .macOS, .visionOS: return .icloudPeer
        case .unknown: return .icloudPeer
        }
    }
}

/// A single synchronized endpoint in the ClusterFleet.
public struct FleetDevice: Sendable, Equatable, Identifiable {
    public var id: String
    public var kind: FleetDeviceKind
    public var displayName: String
    public var isActive: Bool
    /// Measured or prior latency (ms).
    public var latencyMs: Double
    /// Applied compensation delay from the last plan (ms).
    public var compensationDelayMs: Double
    public var lastSeen: Date
    /// Platform for iCloud / Watch companions (nil for pure audio ports).
    public var platform: FleetPlatform?
    /// True when this entry is the local host device presence row.
    public var isLocalHost: Bool
    /// Last published IO buffer duration (ms) when known.
    public var bufferLatencyMs: Double?

    public init(
        id: String,
        kind: FleetDeviceKind,
        displayName: String,
        isActive: Bool = true,
        latencyMs: Double? = nil,
        compensationDelayMs: Double = 0,
        lastSeen: Date = Date(),
        platform: FleetPlatform? = nil,
        isLocalHost: Bool = false,
        bufferLatencyMs: Double? = nil
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.isActive = isActive
        self.latencyMs = latencyMs ?? kind.defaultLatencyMs
        self.compensationDelayMs = max(0, compensationDelayMs)
        self.lastSeen = lastSeen
        self.platform = platform
        self.isLocalHost = isLocalHost
        self.bufferLatencyMs = bufferLatencyMs
    }
}

/// Snapshot of fleet + spatial + tempo state for UI / session telemetry.
public struct ClusterFleetSnapshot: Sendable, Equatable {
    public var devices: [FleetDevice]
    public var spatialDepth: Double
    public var listenerYawDegrees: Double
    public var tempoBPM: Double
    public var crownBeta: Double
    public var isGrounding: Bool
    public var targetLatencyMs: Double
    public var lastPlan: LatencyCompensationPlan
    public var qualityProfile: AirFoilQualityProfile
    public var updatedAt: Date

    public var activeDevices: [FleetDevice] { devices.filter(\.isActive) }

    public var hasAirPodsRoute: Bool {
        activeDevices.contains { device in
            switch device.kind {
            case .airPods, .airPodsPro, .airPodsMax: return true
            default: return false
            }
        }
    }

    public var hasWatchCompanion: Bool {
        activeDevices.contains { $0.kind == .watchCompanion }
    }

    public var icloudPeers: [FleetDevice] {
        activeDevices.filter { $0.kind == .icloudPeer }
    }

    public init(
        devices: [FleetDevice] = [],
        spatialDepth: Double = 0,
        listenerYawDegrees: Double = 0,
        tempoBPM: Double = CrooksCycleDefaults.nominalBPM,
        crownBeta: Double = 0,
        isGrounding: Bool = false,
        targetLatencyMs: Double = 10,
        lastPlan: LatencyCompensationPlan = LatencyCompensationPlan(),
        qualityProfile: AirFoilQualityProfile = .standard,
        updatedAt: Date = Date()
    ) {
        self.devices = devices
        self.spatialDepth = spatialDepth
        self.listenerYawDegrees = listenerYawDegrees
        self.tempoBPM = tempoBPM
        self.crownBeta = crownBeta
        self.isGrounding = isGrounding
        self.targetLatencyMs = targetLatencyMs
        self.lastPlan = lastPlan
        self.qualityProfile = qualityProfile
        self.updatedAt = updatedAt
    }
}

// MARK: - Route port description (app → core, no AVFoundation in core model)

/// Platform-agnostic description of an audio output port (filled by app layer).
public struct FleetRoutePort: Sendable, Equatable {
    public var uid: String
    public var portType: String
    public var portName: String

    public init(uid: String, portType: String, portName: String) {
        self.uid = uid
        self.portType = portType
        self.portName = portName
    }

    /// Map AVAudioSessionPort raw values / names → fleet kind.
    public func resolvedKind() -> FleetDeviceKind {
        let type = portType.lowercased()
        let name = portName.lowercased()

        if name.contains("airpods max") { return .airPodsMax }
        if name.contains("airpods pro") { return .airPodsPro }
        if name.contains("airpods") { return .airPods }

        // Common AVAudioSession.Port raw values
        switch type {
        case "speaker", "builtinspeaker": return .builtInSpeaker
        case "headphones": return .wiredHeadphones
        case "bluetootha2dp", "bluetoothhfp", "bluetoothle":
            return name.contains("airpods") ? .airPods : .bluetoothA2DP
        case "airplay": return .airPlay
        case "caraudio": return .carAudio
        default:
            if name.contains("airplay") || name.contains("apple tv") { return .airPlay }
            if name.contains("headphone") { return .wiredHeadphones }
            return .unknown
        }
    }
}

// MARK: - ClusterFleet

/// Production multi-device sync orchestrator for NATURaL / ClusterFuck.
///
/// ## What this owns
/// - Fleet membership (route ports, Watch, TV relay)
/// - Spatial modulation **state** (yaw / depth for environment nodes)
/// - Latency compensation plan (σ_irr-aware)
/// - Quality profile hand-off to `AirFoilQualityRouter` / low-latency session setup
///
/// ## What this does **not** own
/// - `UniversalBeatSync.broadcast` (sole authority: `BeatSyncActuatorChannel`)
/// - Multiple `AVAudioSession` instances (impossible / incorrect on iOS)
/// - Tempo-as-volume (forbidden; tempo is playback rate via MusicService)
///
/// App layer feeds route ports and applies compensation delays to render graphs.
public actor ClusterFleet {
    public static let shared = ClusterFleet()

    private var devices: [String: FleetDevice] = [:]
    private var spatialDepth: Double = 0
    private var listenerYawDegrees: Double = 0
    private var tempoBPM: Double = CrooksCycleDefaults.nominalBPM
    private var crownBeta: Double = 0
    private var isGrounding = false
    private var targetLatencyMs: Double = 10
    private var lastPlan = LatencyCompensationPlan()
    private var qualityProfile: AirFoilQualityProfile = .standard
    private var lastSigmaIrr: Double = 0

    public init() {}

    // MARK: Snapshot

    public func snapshot() -> ClusterFleetSnapshot {
        ClusterFleetSnapshot(
            devices: devices.values.sorted { $0.id < $1.id },
            spatialDepth: spatialDepth,
            listenerYawDegrees: listenerYawDegrees,
            tempoBPM: tempoBPM,
            crownBeta: crownBeta,
            isGrounding: isGrounding,
            targetLatencyMs: targetLatencyMs,
            lastPlan: lastPlan,
            qualityProfile: qualityProfile,
            updatedAt: Date()
        )
    }

    // MARK: Membership

    /// Replace active audio-route devices from session route description.
    /// Companion devices (Watch / TV / iCloud peers / local host) are preserved.
    public func refreshAudioRoutes(_ ports: [FleetRoutePort]) {
        let now = Date()
        var keepCompanion: [String: FleetDevice] = [:]
        for (id, device) in devices {
            if device.kind.isCompanionMembership || device.isLocalHost {
                keepCompanion[id] = device
            }
        }

        var next: [String: FleetDevice] = keepCompanion
        for port in ports {
            let kind = port.resolvedKind()
            let id = port.uid.isEmpty ? "\(kind.rawValue)-\(port.portName)" : port.uid
            let prior = devices[id]
            next[id] = FleetDevice(
                id: id,
                kind: kind,
                displayName: port.portName.isEmpty ? kind.rawValue : port.portName,
                isActive: true,
                latencyMs: prior?.latencyMs ?? kind.defaultLatencyMs,
                compensationDelayMs: prior?.compensationDelayMs ?? 0,
                lastSeen: now,
                platform: prior?.platform,
                isLocalHost: prior?.isLocalHost ?? false,
                bufferLatencyMs: prior?.bufferLatencyMs
            )
        }
        devices = next
        recomputePlan()
        qualityProfile = AirFoilQualityRouter.profile(for: Array(devices.values), targetLatencyMs: targetLatencyMs)
    }

    /// Insert or update a companion (Watch, TV, iCloud peer, or local host row).
    public func upsertCompanion(
        id: String,
        kind: FleetDeviceKind,
        displayName: String,
        latencyMs: Double? = nil,
        active: Bool = true,
        platform: FleetPlatform? = nil,
        isLocalHost: Bool = false,
        bufferLatencyMs: Double? = nil
    ) {
        precondition(
            kind.isCompanionMembership || kind == .unknown || isLocalHost,
            "upsertCompanion is for companion membership, not audio ports"
        )
        let prior = devices[id]
        let resolvedLatency = latencyMs
            ?? bufferLatencyMs
            ?? prior?.latencyMs
            ?? kind.defaultLatencyMs
        devices[id] = FleetDevice(
            id: id,
            kind: kind,
            displayName: displayName,
            isActive: active,
            latencyMs: resolvedLatency,
            compensationDelayMs: prior?.compensationDelayMs ?? 0,
            lastSeen: Date(),
            platform: platform ?? prior?.platform,
            isLocalHost: isLocalHost || (prior?.isLocalHost ?? false),
            bufferLatencyMs: bufferLatencyMs ?? prior?.bufferLatencyMs
        )
        recomputePlan()
    }

    /// Ensure the local host row exists (iPhone / iPad / Mac running this process).
    public func ensureLocalHost(
        id: String,
        platform: FleetPlatform,
        displayName: String,
        bufferLatencyMs: Double? = nil
    ) {
        upsertCompanion(
            id: id,
            kind: .icloudPeer,
            displayName: displayName,
            latencyMs: bufferLatencyMs,
            active: true,
            platform: platform,
            isLocalHost: true,
            bufferLatencyMs: bufferLatencyMs
        )
    }

    /// Apply remote presence heartbeats from same-iCloud peers (and optional Watch rows).
    ///
    /// - Parameters:
    ///   - records: Decoded presence payloads (KVS / CloudKit / WCSession).
    ///   - localDeviceId: This process's stable id — never demoted by a remote copy.
    ///   - staleAfter: Peers not seen within this interval become inactive.
    public func applyPresenceRecords(
        _ records: [FleetPresenceRecord],
        localDeviceId: String,
        staleAfter: TimeInterval = FleetPresenceRecord.defaultStaleInterval
    ) {
        let now = Date()
        for record in records {
            // Never overwrite local host from a mirrored remote of ourselves.
            if record.deviceId == localDeviceId {
                continue
            }
            let age = now.timeIntervalSince(record.updatedAt)
            let active = record.isActive && age <= staleAfter
            let kind = record.platform.companionKind
            let prior = devices[record.deviceId]
            let latency = record.bufferLatencyMs
                ?? record.pathLatencyMs
                ?? prior?.latencyMs
                ?? kind.defaultLatencyMs
            devices[record.deviceId] = FleetDevice(
                id: record.deviceId,
                kind: kind,
                displayName: record.displayName,
                isActive: active,
                latencyMs: latency,
                compensationDelayMs: prior?.compensationDelayMs ?? 0,
                lastSeen: record.updatedAt,
                platform: record.platform,
                isLocalHost: false,
                bufferLatencyMs: record.bufferLatencyMs
            )
        }
        recomputePlan()
    }

    /// Mark companions inactive when `lastSeen` is older than `staleAfter`.
    public func pruneStaleCompanions(staleAfter: TimeInterval = FleetPresenceRecord.defaultStaleInterval) {
        let now = Date()
        var changed = false
        for (id, device) in devices {
            guard device.kind.isCompanionMembership, !device.isLocalHost else { continue }
            if device.isActive && now.timeIntervalSince(device.lastSeen) > staleAfter {
                var updated = device
                updated.isActive = false
                devices[id] = updated
                changed = true
            }
        }
        if changed { recomputePlan() }
    }

    public func removeDevice(id: String) {
        devices.removeValue(forKey: id)
        recomputePlan()
    }

    public func updateMeasuredLatency(deviceId: String, latencyMs: Double) {
        guard var device = devices[deviceId] else { return }
        device.latencyMs = latencyMs.isFinite ? max(0, latencyMs) : device.kind.defaultLatencyMs
        device.lastSeen = Date()
        devices[deviceId] = device
        recomputePlan()
    }

    /// Publish continuous IO buffer measurement onto a device row (creates local host if needed).
    public func publishBufferLatency(
        deviceId: String,
        bufferLatencyMs: Double,
        displayName: String? = nil,
        platform: FleetPlatform? = nil,
        asLocalHost: Bool = false
    ) {
        let ms = bufferLatencyMs.isFinite ? max(0, bufferLatencyMs) : 0
        if var device = devices[deviceId] {
            device.bufferLatencyMs = ms
            // Prefer measured buffer as path latency for compensation when positive.
            if ms > 0 { device.latencyMs = ms }
            device.lastSeen = Date()
            device.isActive = true
            if asLocalHost { device.isLocalHost = true }
            if let platform { device.platform = platform }
            if let displayName, !displayName.isEmpty { device.displayName = displayName }
            devices[deviceId] = device
            recomputePlan()
        } else if asLocalHost {
            ensureLocalHost(
                id: deviceId,
                platform: platform ?? .unknown,
                displayName: displayName ?? "This Device",
                bufferLatencyMs: ms
            )
        }
    }

    // MARK: Spatial + tempo (state only)

    /// Spatial depth ∈ [0, 1] and listener yaw from score / biometrics / β.
    ///
    /// `yaw = depth * 360 * sign(β)` — matches product intent without abusing
    /// mixer volume as a tempo control.
    public func applySpatialModulation(depth: Double, beta: Double) {
        let d = depth.isFinite ? max(0, min(1, depth)) : 0
        let b = beta.isFinite ? max(-1, min(1, beta)) : 0
        spatialDepth = d
        crownBeta = b
        let sign: Double = b >= 0 ? 1 : -1
        listenerYawDegrees = d * 360.0 * sign
    }

    /// Adopt beat snapshot from UniversalBeatSync listener path (not a second broadcast).
    public func adoptBeat(_ snap: BeatSyncSnapshot) {
        tempoBPM = snap.bpm
        crownBeta = snap.crownBeta
        isGrounding = snap.isGrounding
    }

    public func setTargetLatencyMs(_ ms: Double) {
        targetLatencyMs = ms.isFinite ? max(2, min(100, ms)) : 10
        qualityProfile = AirFoilQualityRouter.profile(for: Array(devices.values), targetLatencyMs: targetLatencyMs)
    }

    public func setSigmaIrr(_ sigma: Double) {
        lastSigmaIrr = sigma.isFinite ? max(0, sigma) : 0
        recomputePlan()
    }

    public func lastCompensationPlan() -> LatencyCompensationPlan { lastPlan }

    public func currentQualityProfile() -> AirFoilQualityProfile { qualityProfile }

    // MARK: Private

    private func recomputePlan() {
        let samples = devices.values
            .filter(\.isActive)
            .map { DeviceLatencySample(deviceId: $0.id, latencyMs: $0.latencyMs) }
        lastPlan = AudioSyncLatencyOptimizer.optimize(latencies: samples, sigmaIrr: lastSigmaIrr)
        for (id, delay) in lastPlan.delayMsByDevice {
            guard var device = devices[id] else { continue }
            device.compensationDelayMs = delay
            devices[id] = device
        }
        qualityProfile = AirFoilQualityRouter.profile(for: Array(devices.values), targetLatencyMs: targetLatencyMs)
    }
}

// MARK: - Actuator channel

/// ClusterFleet side-effects for Crooks commands (state + plan only; no beat broadcast).
public struct ClusterFleetActuatorChannel: ActuatorChannel {
    public let id = "cluster_fleet"
    private let fleet: ClusterFleet

    public init(fleet: ClusterFleet = .shared) {
        self.fleet = fleet
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding(let sigma, let bpm, let beta):
            await fleet.setSigmaIrr(sigma)
            await fleet.adoptBeat(
                BeatSyncSnapshot(bpm: CrooksCycleDefaults.groundingBPM, crownBeta: beta * 0.5, isGrounding: true)
            )
            await fleet.applySpatialModulation(depth: min(0.35, sigma), beta: beta * 0.5)
            let plan = await fleet.lastCompensationPlan()
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: "fleet ground bpm→\(CrooksCycleDefaults.groundingBPM) from \(bpm) refL=\(fmtMs(plan.referenceLatencyMs))"
            )
        case .beatBroadcast(let bpm, let beta, let grounding):
            await fleet.adoptBeat(BeatSyncSnapshot(bpm: bpm, crownBeta: beta, isGrounding: grounding))
            // Mild spatial coupling to |β| during beat ticks.
            await fleet.applySpatialModulation(depth: min(1, abs(beta)), beta: beta)
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: "fleet beat bpm=\(bpm) β=\(fmt3(beta)) g=\(grounding)"
            )
        case .phaseFlip(let from, let to, let cycle):
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: "fleet phase \(from.rawValue)→\(to.rawValue) #\(cycle)"
            )
        case .microSurveyLog:
            return ActuatorChannelResult(channelId: id, command: command, success: true, detail: "idle")
        }
    }
}

private func fmtMs(_ v: Double) -> String { String(format: "%.1fms", v) }
private func fmt3(_ v: Double) -> String { String(format: "%.3f", v) }
