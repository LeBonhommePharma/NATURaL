import Foundation

// MARK: - Update Result

/// Result of one Crooks-cycle control tick.
public struct CrooksCycleUpdateResult: Sendable, Equatable {
    public let work: Double
    public let sigmaIrr: Double
    public let phase: ThermodynamicPhase
    public let didGround: Bool
    public let didFlipPhase: Bool
    public let cycleCount: Int
    public let eigenBackend: String
    public let usedANEPath: Bool

    public init(
        work: Double,
        sigmaIrr: Double,
        phase: ThermodynamicPhase,
        didGround: Bool,
        didFlipPhase: Bool,
        cycleCount: Int,
        eigenBackend: String,
        usedANEPath: Bool
    ) {
        self.work = work
        self.sigmaIrr = sigmaIrr
        self.phase = phase
        self.didGround = didGround
        self.didFlipPhase = didFlipPhase
        self.cycleCount = cycleCount
        self.eigenBackend = eigenBackend
        self.usedANEPath = usedANEPath
    }
}

// MARK: - Crooks Cycle Controller

/// Crooks-cycle controller for non-equilibrium work and irreversible entropy production (σ_irr).
///
/// ## Theory
/// Crooks fluctuation theorem relates forward and reverse path work to free energy:
///
/// ```
///   ⟨e^{−βW}⟩_fwd / ⟨e^{−βW}⟩_rev = e^{−βΔG}
/// ```
///
/// For a closed pair of half-cycles (work units = EigenMetal-weighted features):
///
/// ```
///   σ_irr = max(0, |W_fwd + W_rev| − 2|ΔG|_work)
/// ```
///
/// ## Control policy
/// | Condition | Action |
/// |---|---|
/// | σ_irr > groundingThreshold **or** cross-domain residual high | Ground via `ActuatorBus` + damp phase work |
/// | σ_irr < reversibilityThreshold | Phase flip (cycle closure) |
/// | every tick | Single beat broadcast (Watch crown β · AirPods · Music · breathing) |
///
/// ## Stack (all live, no placeholders)
/// - `EigenMetalWorkKernel` — Accelerate/ANE eigen projection
/// - `DeltaHRVFlexAIDMapper` — BindingEntropyProfile / residual grounding assist
/// - `ActuatorBus` — sole side-effect multiplex (beat, crown, AirPods, log, breath)
/// - `EntropyCalculator` — work-history Shannon entropy (Metal/SIMD under `BONHOMME_ACCEL`)
public actor CrooksCycleController {
    public static let shared = CrooksCycleController()

    private var wFwd: Double = 0
    private var wRev: Double = 0
    private var deltaG: Double
    private var phase: ThermodynamicPhase = .forward
    private var cycleCount: Int = 0
    private var lastWork: Double = 0
    private var lastUpdate: Date?
    private var workHistory: [Double] = []

    private let kernel: EigenMetalWorkKernel
    private let actuators: ActuatorBus
    private let crown: CrownController
    private let mapper: DeltaHRVFlexAIDMapper

    public private(set) var sigmaIrr: Double = 0

    /// Maps kcal/mol free energy into EigenMetal work units so control thresholds
    /// (0.03 / 0.12) share scale with feature-weighted ticks.
    /// Example: 8.7 kcal × 0.002 ≈ 0.017 work units of reversible budget.
    private static let kcalToWorkScale: Double = 0.002

    private static let maxWorkHistory = 256

    public init(
        deltaG: Double = CrooksCycleDefaults.deltaG,
        kernel: EigenMetalWorkKernel = EigenMetalWorkKernel(),
        actuators: ActuatorBus = .shared,
        crown: CrownController = .shared,
        mapper: DeltaHRVFlexAIDMapper = .shared
    ) {
        self.deltaG = deltaG
        self.kernel = kernel
        self.actuators = actuators
        self.crown = crown
        self.mapper = mapper
    }

    // MARK: - Public state

    public func snapshot() -> ThermodynamicStateSnapshot {
        ThermodynamicStateSnapshot(
            phase: phase,
            wFwd: wFwd,
            wRev: wRev,
            deltaG: deltaG,
            sigmaIrr: sigmaIrr,
            cycleCount: cycleCount,
            lastWork: lastWork,
            lastUpdate: lastUpdate
        )
    }

    public func setDeltaG(_ value: Double) {
        deltaG = value
        recomputeSigma()
    }

    public func reset() {
        wFwd = 0
        wRev = 0
        phase = .forward
        cycleCount = 0
        sigmaIrr = 0
        lastWork = 0
        lastUpdate = nil
        workHistory.removeAll(keepingCapacity: true)
    }

    // MARK: - Control tick

    /// Ingest ΔH_hrv, FlexAID ΔS_config, crown β, and BPM; apply Crooks policy.
    @discardableResult
    public func update(
        deltaHRV: Double,
        flexAIDDeltaS: Double,
        crownBeta: Double,
        bpm: Double,
        substanceId: String? = nil
    ) async -> CrooksCycleUpdateResult {
        _ = await crown.setBeta(crownBeta)

        let prediction = await mapper.predict(
            deltaHRV: deltaHRV,
            flexAIDDeltaS: flexAIDDeltaS,
            substanceId: substanceId
        )

        let features = CrooksFeatureVector(
            deltaHRV: deltaHRV,
            flexAIDDeltaS: flexAIDDeltaS,
            crownBeta: crownBeta,
            bpm: bpm
        )
        let eval = kernel.evaluate(features)
        let work = eval.work
        lastWork = work
        lastUpdate = Date()
        appendWork(work)

        switch phase {
        case .forward: wFwd += work
        case .reverse: wRev += work
        }

        recomputeSigma()

        var didGround = false
        var didFlip = false

        if sigmaIrr > CrooksCycleDefaults.groundingThreshold || prediction.shouldGround {
            await minimizeSigmaIrr(bpm: bpm, beta: crownBeta)
            didGround = true
        }

        if sigmaIrr < CrooksCycleDefaults.reversibilityThreshold {
            let from = phase
            phase = phase.flipped
            if phase == .forward {
                // Full fwd+rev pair closed — soft-halve residual so long sessions stay bounded.
                cycleCount += 1
                wFwd *= 0.5
                wRev *= 0.5
                recomputeSigma()
            }
            await actuators.executePhaseFlip(from: from, to: phase, cycleCount: cycleCount)
            await SessionEventLog.shared.append(
                "crooks_closure \(from.rawValue)→\(phase.rawValue) σ_irr=\(String(format: "%.4f", sigmaIrr)) cycle=\(cycleCount)"
            )
            didFlip = true
        }

        // One multiplexed beat: bus owns UniversalBeatSync + crown/AirPods dial mirrors.
        await actuators.broadcastBeat(bpm: bpm, beta: crownBeta, grounding: didGround)

        return CrooksCycleUpdateResult(
            work: work,
            sigmaIrr: sigmaIrr,
            phase: phase,
            didGround: didGround,
            didFlipPhase: didFlip,
            cycleCount: cycleCount,
            eigenBackend: eval.backendLabel,
            usedANEPath: eval.usedANEPath
        )
    }

    /// Shannon entropy of the work history (Metal/SIMD path when linked).
    public func workEntropy() -> Double {
        kernel.workHistoryEntropy(workHistory)
    }

    // MARK: - σ_irr

    /// ```
    ///   σ_irr = max(0, |W_fwd + W_rev| − 2|ΔG|_work)
    /// ```
    /// Near-reversible protocols keep W_fwd ≈ −W_rev → σ_irr → 0 → phase flip.
    private func recomputeSigma() {
        let totalWork = wFwd + wRev
        let deltaGWork = abs(deltaG) * Self.kcalToWorkScale
        sigmaIrr = max(0, abs(totalWork) - 2.0 * deltaGWork)
    }

    /// Damp accumulated half-cycle work and fire grounding actuators once via the bus.
    private func minimizeSigmaIrr(bpm: Double, beta: Double) async {
        let gain = CrooksCycleDefaults.groundingCorrectiveGain
        switch phase {
        case .forward: wFwd *= (1 - gain)
        case .reverse: wRev *= (1 - gain)
        }

        // Cross-term pull: both half-cycles toward their mean.
        let mean = 0.5 * (wFwd + wRev)
        let cross = gain * 0.5
        wFwd = wFwd * (1 - cross) + mean * cross
        wRev = wRev * (1 - cross) + mean * cross

        recomputeSigma()

        await actuators.executeGrounding(sigmaIrr: sigmaIrr, bpm: bpm, beta: beta)
        await actuators.logMicroSurvey(sigmaIrr: sigmaIrr, work: lastWork)
    }

    private func appendWork(_ work: Double) {
        workHistory.append(work)
        if workHistory.count > Self.maxWorkHistory {
            workHistory.removeFirst(workHistory.count - Self.maxWorkHistory)
        }
    }
}
