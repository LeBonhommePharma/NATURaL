import Foundation

// MARK: - Snapshot

/// Headphone-route crown-equivalent β state (AirPods / Bluetooth audio).
///
/// AirPods have no Digital Crown. This maps crown-equivalent inputs
/// (volume rocker, stem press, mirrored Watch crown) onto β ∈ [-1, 1]
/// and participates in universal beat lock via `ActuatorBus`.
public struct AirPodsCrownBetaSnapshot: Sendable, Equatable {
    public var beta: Double
    public var routeActive: Bool
    public var bpm: Double
    public var isGrounding: Bool
    public var sceneLabel: String
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

// MARK: - Controller

/// AirPods crown-β controller.
///
/// ## Inputs
/// - `applyVolumeDelta` — volume rocker as crown proxy (β only)
/// - `applyStemPress` — Force Sensor → soft damp toward neutral (β only)
/// - `mirrorWatchCrown` — copy Watch Digital Crown β while route is live
/// - `setRouteActive` — AVAudioSession route change (app layer)
///
/// ## Beat authority
/// Session path uses `setBeta` / `adoptBeatState` only.
/// Tempo broadcasts go solely through `ActuatorBus` → `BeatSyncActuatorChannel`.
/// `debugBroadcastBeat` is for standalone / debug callers and must not be used
/// from `PharmaControlSessionManager` or Crooks session ticks.
public actor AirPodsCrownBetaController {
    public static let shared = AirPodsCrownBetaController()

    private var dial = CrownBetaDial(beta: 0, sensitivity: 0.06, smoothing: 0.4)
    private var routeActive = false
    private var lastBPM = CrooksCycleDefaults.nominalBPM
    private var isGrounding = false
    private var lastUpdate = Date()

    /// Volume step → crown scale (up → heating, down → binding).
    public var volumeSensitivity: Double = 0.08

    public init() {}

    /// Legacy init kept so call sites that previously injected a beat clock still compile.
    /// The `beatSync` parameter is **ignored** — AirPods never owns beat authority on the session path.
    @available(*, deprecated, message: "AirPodsCrownBetaController no longer holds UniversalBeatSync; use init()")
    public init(beatSync: UniversalBeatSync) {
        _ = beatSync
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

    public func setRouteActive(_ active: Bool) {
        routeActive = active
        lastUpdate = Date()
    }

    /// Positive delta (volume up) → heating β; negative → binding β.
    ///
    /// Mutates dial β only — does **not** call `UniversalBeatSync.broadcast`.
    /// When a Crooks session bus is active, end-of-tick `ActuatorBus.broadcastBeat`
    /// is sole tempo authority.
    @discardableResult
    public func applyVolumeDelta(_ delta: Double) async -> Double {
        let scaled = delta * volumeSensitivity / max(dial.sensitivity, 1e-6)
        let beta = dial.applyCrownDelta(scaled)
        lastUpdate = Date()
        return beta
    }

    /// Stem Force Sensor → damp β (micro-grounding).
    ///
    /// β-only (no beat broadcast) — same authority rules as `applyVolumeDelta`.
    @discardableResult
    public func applyStemPress(gain: Double = 0.25) async -> Double {
        let beta = dial.dampTowardNeutral(gain: gain)
        lastUpdate = Date()
        return beta
    }

    /// Mirror Watch Digital Crown β onto the headphone dial (no re-broadcast).
    @discardableResult
    public func mirrorWatchCrown(beta: Double) -> Double {
        lastUpdate = Date()
        return dial.setBeta(beta)
    }

    @discardableResult
    public func setBeta(_ value: Double) -> Double {
        lastUpdate = Date()
        return dial.setBeta(value)
    }

    @discardableResult
    public func dampTowardNeutral(gain: Double = 0.4) -> Double {
        lastUpdate = Date()
        return dial.dampTowardNeutral(gain: gain)
    }

    /// Record tempo metadata without touching `UniversalBeatSync` (session / bus path).
    public func adoptBeatState(bpm: Double, beta: Double, grounding: Bool) {
        _ = dial.setBeta(beta)
        lastBPM = max(40, min(220, bpm))
        isGrounding = grounding
        lastUpdate = Date()
    }

    // MARK: - Debug / standalone only

    /// **DEBUG / STANDALONE ONLY.** Direct `UniversalBeatSync.broadcast`.
    ///
    /// Session control must **not** call this. Prefer `ActuatorBus.broadcastBeat`
    /// so `BeatSyncActuatorChannel` remains sole beat authority.
    @discardableResult
    public func debugBroadcastBeat(
        bpm: Double,
        beta: Double,
        grounding: Bool = false,
        via beatSync: UniversalBeatSync
    ) async -> BeatSyncSnapshot {
        _ = dial.setBeta(beta)
        lastBPM = max(40, min(220, bpm))
        isGrounding = grounding
        lastUpdate = Date()
        return await beatSync.broadcast(bpm: lastBPM, beta: dial.beta, grounding: grounding)
    }

    /// - Warning: Deprecated alias of `debugBroadcastBeat`. Session path must use ActuatorBus.
    @available(*, deprecated, renamed: "debugBroadcastBeat")
    @discardableResult
    public func broadcastBeat(
        bpm: Double,
        beta: Double,
        grounding: Bool = false,
        via beatSync: UniversalBeatSync
    ) async -> BeatSyncSnapshot {
        await debugBroadcastBeat(bpm: bpm, beta: beta, grounding: grounding, via: beatSync)
    }
}

// MARK: - Actuator Channel

/// AirPods dial + route metadata. Does **not** call `UniversalBeatSync`
/// (that is sole duty of `BeatSyncActuatorChannel`).
///
/// Bus path: `setBeta` / `adoptBeatState` / `dampTowardNeutral` only.
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
            await airPods.adoptBeatState(
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
                    beta, sigma, CrooksCycleDefaults.groundingBPM, bpm,
                    String(await airPods.isRouteActive())
                )
            )
        case .beatBroadcast(let bpm, let beta, let grounding):
            await airPods.adoptBeatState(bpm: bpm, beta: beta, grounding: grounding)
            let scene = await airPods.snapshot().sceneLabel
            return ActuatorChannelResult(
                channelId: id,
                command: command,
                success: true,
                detail: String(
                    format: "airpods beat bpm=%.0f β=%.3f g=%@ scene=%@",
                    bpm, beta, String(grounding), scene
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
