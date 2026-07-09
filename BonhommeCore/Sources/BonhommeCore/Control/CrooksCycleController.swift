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

/// Production Crooks-cycle controller for non-equilibrium work and σ_irr minimization.
///
/// ## Theory
/// Crooks fluctuation theorem relates forward and reverse path work to free energy:
///
/// ```
///   ⟨e^{−βW}⟩_fwd / ⟨e^{−βW}⟩_rev = e^{−βΔG}
/// ```
///
/// Irreversible entropy production for a closed pair of half-cycles:
///
/// ```
///   σ_irr = max(0, W_fwd + W_rev − 2ΔG)
/// ```
///
/// (with ΔG ≤ 0 for binding; work units are EigenMetal-weighted feature work).
///
/// ## Control
/// - σ_irr > groundingThreshold → `ActuatorBus.executeGrounding` + corrective work
/// - σ_irr < reversibilityThreshold → phase flip (cycle closure)
/// - Every tick → universal beat broadcast via crown β
///
/// ## NATURaL reuse (zero stubs)
/// - `EigenMetalWorkKernel` — Accelerate/ANE + eigen basis work
/// - `DeltaHRVFlexAIDMapper` — BindingEntropyProfile / cross-domain residual
/// - `ActuatorBus` — beat sync, crown, AirPods β, breathing, session log
/// - `AirPodsCrownBetaController` — headphone route crown-β mirror (beta)
/// - `EntropyCalculator` — work-history entropy (Metal/SIMD when BONHOMME_ACCEL)
public actor CrooksCycleController {
    public static let shared = CrooksCycleController()

    // Accumulated half-cycle work
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
    private let airPodsCrown: AirPodsCrownBetaController
    private let mapper: DeltaHRVFlexAIDMapper
    private let beatSync: UniversalBeatSync

    public private(set) var sigmaIrr: Double = 0

    public init(
        deltaG: Double = CrooksCycleDefaults.deltaG,
        kernel: EigenMetalWorkKernel = EigenMetalWorkKernel(),
        actuators: ActuatorBus = .shared,
        crown: CrownController = .shared,
        airPodsCrown: AirPodsCrownBetaController = .shared,
        mapper: DeltaHRVFlexAIDMapper = .shared,
        beatSync: UniversalBeatSync = .shared
    ) {
        self.deltaG = deltaG
        self.kernel = kernel
        self.actuators = actuators
        self.crown = crown
        self.airPodsCrown = airPodsCrown
        self.mapper = mapper
        self.beatSync = beatSync
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
        workHistory.removeAll()
    }

    // MARK: - Control tick

    /// Primary update path: ingest ΔHRV, FlexAID ΔS, crown β, BPM.
    @discardableResult
    public func update(
        deltaHRV: Double,
        flexAIDDeltaS: Double,
        crownBeta: Double,
        bpm: Double,
        substanceId: String? = nil
    ) async -> CrooksCycleUpdateResult {
        // Sync crown dial to provided β.
        _ = await crown.setBeta(crownBeta)

        // Cross-domain residual (assists grounding decision).
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
        workHistory.append(work)
        if workHistory.count > 256 {
            workHistory.removeFirst(workHistory.count - 256)
        }

        // Accumulate phase work.
        switch phase {
        case .forward: wFwd += work
        case .reverse: wRev += work
        }

        recomputeSigma()

        var didGround = false
        var didFlip = false

        // High irreversibility → grounding actuators + σ_irr minimization.
        if sigmaIrr > CrooksCycleDefaults.groundingThreshold || prediction.shouldGround {
            await minimizeSigmaIrr(bpm: bpm, beta: crownBeta)
            didGround = true
        }

        // Near-reversible → cycle closure (phase flip).
        if sigmaIrr < CrooksCycleDefaults.reversibilityThreshold {
            let from = phase
            phase = phase.flipped
            if phase == .forward {
                // Completed a full fwd+rev pair.
                cycleCount += 1
                // Soft reset residual work to keep long sessions bounded.
                wFwd *= 0.5
                wRev *= 0.5
                recomputeSigma()
            }
            await actuators.executePhaseFlip(from: from, to: phase, cycleCount: cycleCount)
            await logClosure(from: from, to: phase)
            didFlip = true
        }

        // Always broadcast universal beat (Watch crown + AirPods route + all actuators).
        await crown.broadcastBeat(bpm: bpm, beta: crownBeta, grounding: didGround)
        _ = await airPodsCrown.mirrorWatchCrown(beta: crownBeta)
        _ = await airPodsCrown.broadcastBeat(bpm: bpm, beta: crownBeta, grounding: didGround)
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

    /// Work-history Shannon entropy (NATURaL EntropyCalculator / Metal path).
    public func workEntropy() -> Double {
        kernel.workHistoryEntropy(workHistory)
    }

    // MARK: - σ_irr math

    /// Irreversible entropy production from Crooks cycle half-works.
    ///
    /// ```
    ///   σ_irr = max(0, |W_fwd + W_rev| − 2|ΔG|_work)
    /// ```
    ///
    /// `deltaG` is stored in kcal/mol (binding convention, typically negative).
    /// It is mapped into EigenMetal work units via `kcalToWorkScale` so control
    /// thresholds (0.03 / 0.12) sit on the same scale as feature-weighted work ticks.
    ///
    /// Near-reversible protocols keep W_fwd ≈ −W_rev (or both near zero after
    /// minimization), so σ_irr → 0 and the cycle closes (phase flip).
    private func recomputeSigma() {
        let totalWork = wFwd + wRev
        let deltaGWork = abs(deltaG) * Self.kcalToWorkScale
        sigmaIrr = max(0, abs(totalWork) - 2.0 * deltaGWork)
    }

    /// Maps kcal/mol free energy into Crooks work units.
    /// 8.7 kcal × 0.002 ≈ 0.017 work units of reversible budget per half-cycle.
    private static let kcalToWorkScale: Double = 0.002

    /// Corrective grounding: reduce accumulated phase work and fire actuators.
    private func minimizeSigmaIrr(bpm: Double, beta: Double) async {
        let gain = CrooksCycleDefaults.groundingCorrectiveGain
        switch phase {
        case .forward:
            wFwd *= (1 - gain)
        case .reverse:
            wRev *= (1 - gain)
        }
        // Cross-term damping pulls both half-cycles toward each other.
        let mean = 0.5 * (wFwd + wRev)
        wFwd = wFwd * (1 - gain * 0.5) + mean * (gain * 0.5)
        wRev = wRev * (1 - gain * 0.5) + mean * (gain * 0.5)

        recomputeSigma()

        await actuators.executeGrounding(sigmaIrr: sigmaIrr, bpm: bpm, beta: beta)
        await actuators.logMicroSurvey(sigmaIrr: sigmaIrr, work: lastWork)
        _ = await mapper.predictAndGround(deltaHRV: 0, flexAIDDeltaS: 0)
        let damped = await crown.dampTowardNeutral(gain: gain)
        _ = await airPodsCrown.dampTowardNeutral(gain: gain)
        _ = await airPodsCrown.broadcastBeat(
            bpm: CrooksCycleDefaults.groundingBPM,
            beta: damped,
            grounding: true
        )
        _ = await beatSync.broadcast(
            bpm: CrooksCycleDefaults.groundingBPM,
            beta: damped,
            grounding: true
        )
    }

    private func logClosure(from: ThermodynamicPhase, to: ThermodynamicPhase) async {
        await SessionEventLog.shared.append(
            "crooks_closure \(from.rawValue)→\(to.rawValue) σ_irr=\(String(format: "%.4f", sigmaIrr)) cycle=\(cycleCount)"
        )
    }
}
