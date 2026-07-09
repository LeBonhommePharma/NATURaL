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
        max(-1, min(1, v))
    }
}

// MARK: - Crown Controller

/// Watch crown dial state. Beat broadcasts go through `ActuatorBus` /
/// `UniversalBeatSync` — this type only owns β.
public actor CrownController {
    public static let shared = CrownController()

    private var dial = CrownBetaDial()
    private let beatSync: UniversalBeatSync

    public init(beatSync: UniversalBeatSync = .shared) {
        self.beatSync = beatSync
    }

    public func currentBeta() -> Double { dial.beta }

    public func dialSnapshot() -> CrownBetaDial { dial }

    @discardableResult
    public func applyCrownDelta(_ delta: Double) -> Double {
        dial.applyCrownDelta(delta)
    }

    @discardableResult
    public func setBeta(_ value: Double) -> Double {
        dial.setBeta(value)
    }

    @discardableResult
    public func dampTowardNeutral(gain: Double = 0.4) -> Double {
        dial.dampTowardNeutral(gain: gain)
    }

    /// Direct broadcast for standalone callers; session control prefers ActuatorBus.
    public func broadcastBeat(bpm: Double, beta: Double, grounding: Bool = false) async {
        _ = dial.setBeta(beta)
        _ = await beatSync.broadcast(bpm: bpm, beta: dial.beta, grounding: grounding)
    }
}
