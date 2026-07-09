import Foundation

// MARK: - AirPods Crown β Snapshot

/// Production β state for AirPods-class headphone control (beta).
///
/// AirPods have no Digital Crown; this controller maps crown-equivalent inputs
/// (volume rocker, stem press, Watch Digital Crown while AirPods are the audio
/// route) onto the same β ∈ [-1, 1] dial used by `CrownController`, and drives
/// `UniversalBeatSync` for tempo lock on the headphone route.
public struct AirPodsCrownBetaSnapshot: Sendable, Equatable {
    /// Crown-equivalent β in [-1, 1].
    public var beta: Double
    /// Whether an AirPods / Bluetooth headphone route is active.
    public var routeActive: Bool
    /// Last broadcast BPM on the AirPods route.
    public var bpm: Double
    /// Grounding (recovery) tempo active.
    public var isGrounding: Bool
    /// Scene label: heating / binding / neutral.
    public var sceneLabel: String
    /// Wall-clock of last input or broadcast.
    public var lastUpdate: Date

    public init(
        beta: Double = 0,
        routeActive: Bool = false,
        bpm: Double = CrooksCycleDefaults.nominalBPM,
        isGrounding: Bool = false,
        sceneLabel: String = "neutral",
        lastUpdate: Date = Date()
    ) {
        self.beta = beta
        self.routeActive = routeActive
        self.bpm = bpm
        self.isGrounding = isGrounding
        self.sceneLabel = sceneLabel
        self.lastUpdate = lastUpdate
    }
}

// MARK: - AirPods Crown β Controller (beta)

/// Production AirPods crown-β controller — zero stubs.
///
/// ## Inputs
/// - `applyVolumeDelta` — volume rocker / accessibility volume as crown proxy
/// - `applyStemPress` — Force Sensor stem press → soft damp toward neutral
/// - `mirrorWatchCrown` — copy Watch Digital Crown β while AirPods are route
/// - `setRouteActive` — AVAudioSession route change (app layer)
///
/// ## Outputs
/// - Updates internal dial + `UniversalBeatSync` for all-device tempo
/// - `CrownController` stays authoritative for Watch; this mirrors for headphones
public actor AirPodsCrownBetaController {
    public static let shared = AirPodsCrownBetaController()

    private var dial = CrownBetaDial(beta: 0, sensitivity: 0.06, smoothing: 0.4)
    private var routeActive = false
    private var lastBPM = CrooksCycleDefaults.nominalBPM
    private var isGrounding = false
    private var lastUpdate = Date()
    private let beatSync: UniversalBeatSync

    /// Volume-delta → crown scale (louder → heating β, quieter → binding β).
    public var volumeSensitivity: Double = 0.08

    public init(beatSync: UniversalBeatSync = .shared) {
        self.beatSync = beatSync
    }

    public func snapshot() -> AirPodsCrownBetaSnapshot {
        AirPodsCrownBetaSnapshot(
            beta: dial.beta,
            routeActive: routeActive,
            bpm: lastBPM,
            isGrounding: isGrounding,
            sceneLabel: dial.sceneLabel,
            lastUpdate: lastUpdate
        )
    }

    public func currentBeta() -> Double { dial.beta }

    public func isRouteActive() -> Bool { routeActive }

    /// App layer reports AirPods / Bluetooth headphone route presence.
    public func setRouteActive(_ active: Bool) {
        routeActive = active
        lastUpdate = Date()
    }

    /// Volume rocker / system volume step as crown-equivalent delta.
    /// Positive delta (volume up) drives heating β; negative drives binding β.
    @discardableResult
    public func applyVolumeDelta(_ delta: Double) async -> Double {
        let scaled = delta * volumeSensitivity / max(dial.sensitivity, 1e-6)
        let beta = dial.applyCrownDelta(scaled)
        lastUpdate = Date()
        if routeActive {
            _ = await beatSync.broadcast(bpm: lastBPM, beta: beta, grounding: isGrounding)
        }
        return beta
    }

    /// Stem Force Sensor press → damp β toward neutral (micro-grounding).
    @discardableResult
    public func applyStemPress(gain: Double = 0.25) async -> Double {
        let beta = dial.dampTowardNeutral(gain: gain)
        lastUpdate = Date()
        if routeActive {
            _ = await beatSync.broadcast(bpm: lastBPM, beta: beta, grounding: isGrounding)
        }
        return beta
    }

    /// Mirror Watch Digital Crown β onto the AirPods route (universal crown lock).
    @discardableResult
    public func mirrorWatchCrown(beta: Double) async -> Double {
        let b = dial.setBeta(beta)
        lastUpdate = Date()
        if routeActive {
            _ = await beatSync.broadcast(bpm: lastBPM, beta: b, grounding: isGrounding)
        }
        return b
    }

    /// Absolute β set (RemoteControl / Debug).
    @discardableResult
    public func setBeta(_ value: Double) -> Double {
        lastUpdate = Date()
        return dial.setBeta(value)
    }

    /// Soft-return toward zero during σ_irr grounding.
    @discardableResult
    public func dampTowardNeutral(gain: Double = 0.4) -> Double {
        lastUpdate = Date()
        return dial.dampTowardNeutral(gain: gain)
    }

    /// Broadcast tempo + β to universal beat bus (AirPods-class playback lock).
    @discardableResult
    public func broadcastBeat(bpm: Double, beta: Double, grounding: Bool = false) async -> BeatSyncSnapshot {
        _ = dial.setBeta(beta)
        lastBPM = max(40, min(220, bpm))
        isGrounding = grounding
        lastUpdate = Date()
        return await beatSync.broadcast(bpm: lastBPM, beta: dial.beta, grounding: grounding)
    }
}

// MARK: - Actuator Channel

/// Production ActuatorBus channel for AirPods crown β + headphone beat lock.
public struct AirPodsCrownActuatorChannel: ActuatorChannel {
    public let id = "airpods_crown_beta"
    private let airPods: AirPodsCrownBetaController

    public init(airPods: AirPodsCrownBetaController = .shared) {
        self.airPods = airPods
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding(let sigma, let bpm, _):
            let beta = await airPods.dampTowardNeutral(gain: CrooksCycleDefaults.groundingCorrectiveGain)
            let snap = await airPods.broadcastBeat(
                bpm: CrooksCycleDefaults.groundingBPM,
                beta: beta,
                grounding: true
            )
            return ActuatorChannelResult(
                channelId: id,
                command: command,
                success: true,
                detail: String(
                    format: "airpods ground β=%.3f σ_irr=%.3f bpm→%.0f (was %.0f) route=%@",
                    beta, sigma, snap.bpm, bpm, String(await airPods.isRouteActive())
                )
            )
        case .beatBroadcast(let bpm, let beta, let grounding):
            let snap = await airPods.broadcastBeat(bpm: bpm, beta: beta, grounding: grounding)
            // Keep AirPods β mirrored to session crown when route is live.
            if await airPods.isRouteActive() {
                _ = await airPods.mirrorWatchCrown(beta: beta)
            }
            return ActuatorChannelResult(
                channelId: id,
                command: command,
                success: true,
                detail: String(
                    format: "airpods beat bpm=%.0f β=%.3f g=%@ scene=%@",
                    snap.bpm, snap.crownBeta, String(grounding), await airPods.snapshot().sceneLabel
                )
            )
        case .phaseFlip(let from, let to, let cycle):
            return ActuatorChannelResult(
                channelId: id,
                command: command,
                success: true,
                detail: "airpods cycle \(cycle): \(from.rawValue)→\(to.rawValue)"
            )
        case .microSurveyLog:
            return ActuatorChannelResult(
                channelId: id,
                command: command,
                success: true,
                detail: "airpods: ok"
            )
        }
    }
}
