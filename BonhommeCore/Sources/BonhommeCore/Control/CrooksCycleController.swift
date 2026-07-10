import Foundation

// MARK: - Update Result

/// Result of one Crooks-inspired control tick.
public struct CrooksCycleUpdateResult: Sendable, Equatable {
    public let work: Double
    /// Heuristic irreversibility index used for control policy (not a verified FT σ_irr).
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

/// Crooks-inspired session controller: heuristic work accumulation and σ_irr index.
///
/// ## Scope (not a verified fluctuation theorem)
/// This is a **control heuristic** inspired by Crooks-style forward/reverse half-cycles.
/// It does **not** compute Crooks FT path averages ⟨e^{−βW}⟩, does not estimate free
/// energy from trajectory ensembles, and does not claim thermodynamic equality with
/// laboratory non-equilibrium work theorems.
///
/// Instantaneous “work” is an EigenMetal-weighted feature score (ΔH_hrv, FlexAID ΔS,
/// crown β, BPM). Accumulated half-cycle totals feed a scalar **heuristic σ_irr**:
///
/// ```
///   σ_irr = max(0, |W_fwd + W_rev| − 2|ΔG|_work)
/// ```
///
/// where `|ΔG|_work` is a scaled free-energy budget in the same ad-hoc work units.
/// Treat σ_irr as a session control index for grounding / phase-flip policy only.
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

    /// Heuristic irreversibility index (control only; not FT-derived).
    public private(set) var sigmaIrr: Double = 0

    /// Maps a kcal/mol free-energy scale into EigenMetal work units so control
    /// thresholds (0.03 / 0.12) share scale with feature-weighted ticks.
    /// Ad-hoc unit bridge only — not a thermodynamic conversion from path work.
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

    /// Ingest ΔH_hrv, FlexAID ΔS_config, crown β, and BPM; apply Crooks-inspired policy.
    @discardableResult
    public func update(
        deltaHRV: Double,
        flexAIDDeltaS: Double,
        crownBeta: Double,
        bpm: Double,
        substanceId: String? = nil
    ) async -> CrooksCycleUpdateResult {
        // Sanitize at the boundary (feature vector also sanitizes; belt-and-suspenders).
        let safeHRV = deltaHRV.isFinite ? deltaHRV : 0
        let safeFlex = flexAIDDeltaS.isFinite ? flexAIDDeltaS : 0
        let safeBeta = crownBeta.isFinite ? max(-1, min(1, crownBeta)) : 0
        let safeBPM = bpm.isFinite ? bpm : CrooksCycleDefaults.nominalBPM

        _ = await crown.setBeta(safeBeta)

        let prediction = await mapper.predict(
            deltaHRV: safeHRV,
            flexAIDDeltaS: safeFlex,
            substanceId: substanceId
        )

        let features = CrooksFeatureVector(
            deltaHRV: safeHRV,
            flexAIDDeltaS: safeFlex,
            crownBeta: safeBeta,
            bpm: safeBPM
        )
        let eval = kernel.evaluate(features)
        let work = eval.work.isFinite ? eval.work : 0
        lastWork = work
        lastUpdate = Date()
        appendWork(work)

        switch phase {
        case .forward: wFwd += work
        case .reverse: wRev += work
        }
        // Guard accumulation against any residual non-finite state.
        if !wFwd.isFinite { wFwd = 0 }
        if !wRev.isFinite { wRev = 0 }

        recomputeSigma()

        var didGround = false
        var didFlip = false

        if sigmaIrr > CrooksCycleDefaults.groundingThreshold || prediction.shouldGround {
            await minimizeSigmaIrr(bpm: safeBPM, beta: safeBeta)
            didGround = true
        }

        // Phase flip only when near-reversible *and* we did not just ground
        // (grounding already damped work; flipping on the same tick confuses cycle accounting).
        if !didGround && sigmaIrr < CrooksCycleDefaults.reversibilityThreshold {
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

        // One multiplexed beat — sole end-of-tick authority.
        // After grounding, preserve recovery tempo (92 BPM) and damped β; do not
        // re-broadcast the pre-ground input BPM/β (that undoes executeGrounding).
        if didGround {
            let dampedBeta = await crown.currentBeta()
            await actuators.broadcastBeat(
                bpm: CrooksCycleDefaults.groundingBPM,
                beta: dampedBeta,
                grounding: true
            )
        } else {
            await actuators.broadcastBeat(bpm: safeBPM, beta: safeBeta, grounding: false)
        }

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

    // MARK: - Heuristic σ_irr

    /// Heuristic control index (not Crooks FT path-average entropy production):
    /// ```
    ///   σ_irr = max(0, |W_fwd + W_rev| − 2|ΔG|_work)
    /// ```
    /// When feature work nearly cancels across half-cycles, the index → 0 → phase flip.
    private func recomputeSigma() {
        let totalWork = wFwd + wRev
        guard totalWork.isFinite else {
            sigmaIrr = 0
            return
        }
        let deltaGWork = abs(deltaG.isFinite ? deltaG : 0) * Self.kcalToWorkScale
        sigmaIrr = max(0, abs(totalWork) - 2.0 * deltaGWork)
    }

    /// Damp accumulated half-cycle work and fire grounding actuators once via the bus.
    ///
    /// Returns the pre-damp σ_irr so callers/tests can prove minimization reduces irreversibility.
    @discardableResult
    private func minimizeSigmaIrr(bpm: Double, beta: Double) async -> Double {
        let sigmaBefore = sigmaIrr
        let gain = CrooksCycleDefaults.groundingCorrectiveGain
        switch phase {
        case .forward: wFwd *= (1 - gain)
        case .reverse: wRev *= (1 - gain)
        }

        // Cross-term pull: both half-cycles toward their mean (cancels opposing residuals).
        let mean = 0.5 * (wFwd + wRev)
        let cross = gain * 0.5
        wFwd = wFwd * (1 - cross) + mean * cross
        wRev = wRev * (1 - cross) + mean * cross
        if !wFwd.isFinite { wFwd = 0 }
        if !wRev.isFinite { wRev = 0 }

        recomputeSigma()

        await actuators.executeGrounding(sigmaIrr: sigmaIrr, bpm: bpm, beta: beta)
        await actuators.logMicroSurvey(sigmaIrr: sigmaIrr, work: lastWork)
        return sigmaBefore
    }

    private func appendWork(_ work: Double) {
        guard work.isFinite else { return }
        workHistory.append(work)
        // Batch-trim to avoid O(n) shift on every append once at capacity.
        if workHistory.count > Self.maxWorkHistory + 32 {
            workHistory.removeFirst(workHistory.count - Self.maxWorkHistory)
        }
    }
}
