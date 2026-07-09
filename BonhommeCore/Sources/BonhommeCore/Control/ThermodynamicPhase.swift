import Foundation

// MARK: - Thermodynamic Phase

/// Direction of a Crooks non-equilibrium work cycle.
///
/// Forward phase accumulates binding / heating work; reverse phase accumulates
/// unbinding / cooling work. Cycle closure occurs when irreversible entropy
/// production σ_irr falls below the reversibility threshold.
public enum ThermodynamicPhase: String, Sendable, Codable, Equatable, CaseIterable {
    /// Binding / heating half-cycle (W_fwd accumulation).
    case forward
    /// Unbinding / cooling half-cycle (W_rev accumulation).
    case reverse

    /// Opposite phase for Crooks cycle flip.
    public var flipped: ThermodynamicPhase {
        switch self {
        case .forward: return .reverse
        case .reverse: return .forward
        }
    }
}

// MARK: - Thermodynamic State

/// Shared mutable phase state for Crooks-cycle control.
///
/// Thread-safe via actor isolation when accessed through `CrooksCycleController`.
/// This type is a value snapshot for UI/read paths.
public struct ThermodynamicStateSnapshot: Sendable, Equatable {
    public var phase: ThermodynamicPhase
    public var wFwd: Double
    public var wRev: Double
    public var deltaG: Double
    public var sigmaIrr: Double
    public var cycleCount: Int
    public var lastWork: Double
    public var lastUpdate: Date?

    public init(
        phase: ThermodynamicPhase = .forward,
        wFwd: Double = 0,
        wRev: Double = 0,
        deltaG: Double = CrooksCycleDefaults.deltaG,
        sigmaIrr: Double = 0,
        cycleCount: Int = 0,
        lastWork: Double = 0,
        lastUpdate: Date? = nil
    ) {
        self.phase = phase
        self.wFwd = wFwd
        self.wRev = wRev
        self.deltaG = deltaG
        self.sigmaIrr = sigmaIrr
        self.cycleCount = cycleCount
        self.lastWork = lastWork
        self.lastUpdate = lastUpdate
    }
}

// MARK: - Defaults

/// Production defaults for Crooks-cycle σ_irr control.
public enum CrooksCycleDefaults {
    /// Equilibrium free-energy scale (kcal/mol convention, typical mid-affinity binder).
    public static let deltaG: Double = -8.7

    /// σ_irr above which grounding actuators fire (bits-equivalent work units).
    public static let groundingThreshold: Double = 0.12

    /// σ_irr below which the Crooks cycle is considered closed → phase flip.
    public static let reversibilityThreshold: Double = 0.03

    /// Resting / grounding BPM for universal beat sync during recovery.
    public static let groundingBPM: Double = 92.0

    /// Nominal exercise BPM used as work-feature origin.
    public static let nominalBPM: Double = 128.0

    /// Soft clamp for |work| per tick to keep numerical stability.
    public static let maxAbsWorkPerTick: Double = 4.0

    /// Grounding corrective gain applied to accumulated work when minimizing σ_irr.
    public static let groundingCorrectiveGain: Double = 0.35
}
