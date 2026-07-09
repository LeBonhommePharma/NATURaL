import Foundation

// MARK: - Crown β Dial

/// Digital Crown β control dial for Crooks-cycle heating / binding bias.
///
/// β ∈ [-1, 1]:
/// - β > 0 → heating / forward drive
/// - β < 0 → binding / reverse drive
/// - β ≈ 0 → neutral (minimum work contribution)
///
/// Production path used by Watch Digital Crown, RemoteControl, and session manager.
public struct CrownBetaDial: Sendable, Equatable {
    /// Current β in [-1, 1].
    public private(set) var beta: Double

    /// Sensitivity: crown rotation delta → Δβ scale.
    public var sensitivity: Double

    /// Low-pass smoothing coefficient in (0, 1]. 1 = no smoothing.
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

    /// Set absolute β (e.g. from UI slider or remote).
    @discardableResult
    public mutating func setBeta(_ value: Double) -> Double {
        beta = Self.clamp(value)
        return beta
    }

    /// Soft-return toward zero (used during grounding σ_irr minimization).
    @discardableResult
    public mutating func dampTowardNeutral(gain: Double = 0.4) -> Double {
        let g = max(0, min(1, gain))
        beta *= (1 - g)
        if abs(beta) < 1e-4 { beta = 0 }
        return beta
    }

    /// Scene label for actuators / UI.
    public var sceneLabel: String {
        if beta > 0.05 { return "heating" }
        if beta < -0.05 { return "binding" }
        return "neutral"
    }

    private static func clamp(_ v: Double) -> Double {
        max(-1, min(1, v))
    }
}

// MARK: - Crown Controller

/// Broadcasts crown-driven beat + scene state to the universal beat bus.
public actor CrownController {
    public static let shared = CrownController()

    private var dial = CrownBetaDial()
    private let beatSync: UniversalBeatSync

    public init(beatSync: UniversalBeatSync = .shared) {
        self.beatSync = beatSync
    }

    public func currentBeta() -> Double { dial.beta }

    public func dialSnapshot() -> CrownBetaDial { dial }

    /// Digital Crown gesture update.
    @discardableResult
    public func applyCrownDelta(_ delta: Double) -> Double {
        dial.applyCrownDelta(delta)
    }

    /// Absolute β set.
    @discardableResult
    public func setBeta(_ value: Double) -> Double {
        dial.setBeta(value)
    }

    /// Damp β during grounding.
    @discardableResult
    public func dampTowardNeutral(gain: Double = 0.4) -> Double {
        dial.dampTowardNeutral(gain: gain)
    }

    /// Broadcast tempo + β to all beat-synced channels.
    public func broadcastBeat(bpm: Double, beta: Double, grounding: Bool = false) async {
        _ = dial.setBeta(beta)
        _ = await beatSync.broadcast(bpm: bpm, beta: dial.beta, grounding: grounding)
    }
}
