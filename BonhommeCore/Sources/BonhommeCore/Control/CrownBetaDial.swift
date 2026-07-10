import Foundation

// MARK: - Crown β Dial

/// Digital Crown β control dial for Crooks-cycle heating / binding bias.
///
/// β ∈ [-1, 1]:
/// - β > 0 → heating / forward drive
/// - β < 0 → binding / reverse drive
/// - β ≈ 0 → neutral (minimum work contribution)
///
/// Shared by Watch Digital Crown, RemoteControl, and AirPods crown-equivalent inputs.
public struct CrownBetaDial: Sendable, Equatable {
    /// Current β in [-1, 1].
    public private(set) var beta: Double

    /// Crown rotation delta → Δβ scale.
    public var sensitivity: Double

    /// Low-pass coefficient in (0, 1]. 1 = no smoothing.
    public var smoothing: Double

    public init(beta: Double = 0, sensitivity: Double = 0.04, smoothing: Double = 0.35) {
        self.beta = Self.clamp(beta)
        self.sensitivity = max(0.001, sensitivity)
        self.smoothing = max(0.01, min(1, smoothing))
    }

    /// Apply a raw Digital Crown rotation delta (radians or detents).
    @discardableResult
    public mutating func applyCrownDelta(_ delta: Double) -> Double {
        let target = Self.clamp(beta + delta * sensitivity)
        beta = beta * (1 - smoothing) + target * smoothing
        beta = Self.clamp(beta)
        return beta
    }

    /// Absolute β (UI slider / remote / mirrored crown).
    @discardableResult
    public mutating func setBeta(_ value: Double) -> Double {
        beta = Self.clamp(value)
        return beta
    }

    /// Soft return toward zero (grounding σ_irr minimization).
    @discardableResult
    public mutating func dampTowardNeutral(gain: Double = 0.4) -> Double {
        let g = max(0, min(1, gain))
        beta *= (1 - g)
        if abs(beta) < 1e-4 { beta = 0 }
        return beta
    }

    public var sceneLabel: String {
        if beta > 0.05 { return "heating" }
        if beta < -0.05 { return "binding" }
        return "neutral"
    }

    private static func clamp(_ v: Double) -> Double {
        guard v.isFinite else { return 0 }
        return max(-1, min(1, v))
    }
}

// MARK: - Crown Controller

/// Watch crown dial state.
///
/// ## Beat authority
/// Session control **never** calls `UniversalBeatSync` from this type.
/// Tempo broadcasts go solely through `ActuatorBus` → `BeatSyncActuatorChannel`.
/// Production paths use `setBeta` / `adoptBeatState` only.
public actor CrownController {
    public static let shared = CrownController()

    private var dial = CrownBetaDial()

    public init() {}

    /// Legacy init kept so call sites that previously injected a beat clock still compile.
    /// The `beatSync` parameter is **ignored** — Crown never owns beat authority.
    @available(*, deprecated, message: "CrownController no longer holds UniversalBeatSync; use init()")
    public init(beatSync: UniversalBeatSync) {
        // Intentionally unused — bus-only beat broadcasts.
        _ = beatSync
    }

    public func currentBeta() -> Double { dial.beta }

    public func dialSnapshot() -> CrownBetaDial { dial }

    /// Mutates dial β only — does **not** call `UniversalBeatSync.broadcast`.
    @discardableResult
    public func applyCrownDelta(_ delta: Double) -> Double {
        dial.applyCrownDelta(delta)
    }

    /// Mutates dial β only — does **not** call `UniversalBeatSync.broadcast`.
    @discardableResult
    public func setBeta(_ value: Double) -> Double {
        dial.setBeta(value)
    }

    @discardableResult
    public func dampTowardNeutral(gain: Double = 0.4) -> Double {
        dial.dampTowardNeutral(gain: gain)
    }

    /// Record β without touching `UniversalBeatSync` (session / bus path).
    public func adoptBeatState(beta: Double) {
        _ = dial.setBeta(beta)
    }

    // MARK: - Debug / standalone only

    /// **DEBUG / STANDALONE ONLY.** Direct `UniversalBeatSync.broadcast`.
    ///
    /// Session control (`PharmaControlSessionManager`, `CrooksCycleController`,
    /// `CrownActuatorChannel`) must **not** call this. Prefer
    /// `ActuatorBus.broadcastBeat` so `BeatSyncActuatorChannel` remains sole authority.
    @discardableResult
    public func debugBroadcastBeat(
        bpm: Double,
        beta: Double,
        grounding: Bool = false,
        via beatSync: UniversalBeatSync
    ) async -> BeatSyncSnapshot {
        _ = dial.setBeta(beta)
        return await beatSync.broadcast(bpm: bpm, beta: dial.beta, grounding: grounding)
    }
}
