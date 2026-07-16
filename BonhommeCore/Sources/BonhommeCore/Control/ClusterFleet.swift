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

    public init(
        id: String,
        kind: FleetDeviceKind,
        displayName: String,
        isActive: Bool = true,
        latencyMs: Double? = nil,
        compensationDelayMs: Double = 0,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.isActive = isActive
        self.latencyMs = latencyMs ?? kind.defaultLatencyMs
        self.compensationDelayMs = max(0, compensationDelayMs)
        self.lastSeen = lastSeen
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
    /// Companion devices (Watch / TV) with ids outside this set are preserved.
    public func refreshAudioRoutes(_ ports: [FleetRoutePort]) {
        let now = Date()
        var keepCompanion: [String: FleetDevice] = [:]
        for (id, device) in devices {
            switch device.kind {
            case .watchCompanion, .tvRelay:
                keepCompanion[id] = device
            default:
                break
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
                lastSeen: now
            )
        }
        devices = next
        recomputePlan()
        qualityProfile = AirFoilQualityRouter.profile(for: Array(devices.values), targetLatencyMs: targetLatencyMs)
    }

    public func upsertCompanion(
        id: String,
        kind: FleetDeviceKind,
        displayName: String,
        latencyMs: Double? = nil,
        active: Bool = true
    ) {
        precondition(kind == .watchCompanion || kind == .tvRelay || kind == .unknown)
        let prior = devices[id]
        devices[id] = FleetDevice(
            id: id,
            kind: kind,
            displayName: displayName,
            isActive: active,
            latencyMs: latencyMs ?? prior?.latencyMs ?? kind.defaultLatencyMs,
            compensationDelayMs: prior?.compensationDelayMs ?? 0,
            lastSeen: Date()
        )
        recomputePlan()
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
