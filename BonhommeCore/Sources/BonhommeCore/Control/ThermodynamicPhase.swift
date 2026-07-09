import Foundation

// MARK: - Thermodynamic Phase

/// Direction of a Crooks-inspired control half-cycle (heuristic, not FT path averages).
///
/// Forward accumulates binding / heating feature-work; reverse accumulates unbinding /
/// cooling feature-work. Cycle closure when heuristic σ_irr falls below the
/// reversibility threshold. Labels borrow non-equilibrium language for control UX only.
public enum ThermodynamicPhase: String, Sendable, Codable, Equatable, CaseIterable {
    /// Binding / heating half-cycle (W_fwd).
    case forward
    /// Unbinding / cooling half-cycle (W_rev).
    case reverse

    public var flipped: ThermodynamicPhase {
        switch self {
        case .forward: return .reverse
        case .reverse: return .forward
        }
    }
}

// MARK: - Thermodynamic State

/// Value snapshot of Crooks-inspired control state for UI / read paths.
/// Mutable state lives on `CrooksCycleController` (actor-isolated).
/// `sigmaIrr` is a heuristic control index, not a verified fluctuation-theorem quantity.
public struct ThermodynamicStateSnapshot: Sendable, Equatable {
    public var phase: ThermodynamicPhase
    public var wFwd: Double
    public var wRev: Double
    public var deltaG: Double
    /// Heuristic irreversibility index for control policy (not FT-derived σ_irr).
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

/// Crooks-inspired control defaults (heuristic σ_irr thresholds, not FT constants).
public enum CrooksCycleDefaults {
    /// Free-energy scale used only as a control budget (kcal/mol → work units).
    /// Not estimated from ensemble path averages.
    public static let deltaG: Double = -8.7

    /// Heuristic σ_irr above which grounding actuators fire.
    public static let groundingThreshold: Double = 0.12

    /// Heuristic σ_irr below which the control cycle is closed → phase flip.
    public static let reversibilityThreshold: Double = 0.03

    /// Recovery tempo for universal beat sync (≈ 6 breaths/min via breathing guide).
    public static let groundingBPM: Double = 92.0

    /// Nominal exercise BPM (work-feature origin).
    public static let nominalBPM: Double = 128.0

    /// Soft clamp for |work| per tick.
    public static let maxAbsWorkPerTick: Double = 4.0

    /// Corrective gain on accumulated work during heuristic σ_irr minimization.
    public static let groundingCorrectiveGain: Double = 0.35
}
