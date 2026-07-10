import Foundation

// MARK: - Session Tick Input

/// One multi-domain sample for the pharma-control session loop.
public struct PharmaControlTick: Sendable, Equatable {
    public var deltaHRV: Double
    public var flexAIDDeltaS: Double
    public var crownBeta: Double
    public var bpm: Double
    public var substanceId: String?
    public var sciScore: Double?

    public init(
        deltaHRV: Double,
        flexAIDDeltaS: Double = 0,
        crownBeta: Double = 0,
        bpm: Double,
        substanceId: String? = nil,
        sciScore: Double? = nil
    ) {
        self.deltaHRV = deltaHRV
        self.flexAIDDeltaS = flexAIDDeltaS
        self.crownBeta = crownBeta
        self.bpm = bpm
        self.substanceId = substanceId
        self.sciScore = sciScore
    }
}

// MARK: - Session Snapshot

/// Observable session state for UI (RemoteControl, Watch, Debug).
public struct PharmaControlSessionSnapshot: Sendable, Equatable {
    public var isRunning: Bool
    public var thermodynamic: ThermodynamicStateSnapshot
    public var lastResult: CrooksCycleUpdateResult?
    public var beat: BeatSyncSnapshot?
    public var crownBeta: Double
    public var tickCount: Int
    public var lastPrediction: DeltaHRVFlexAIDPrediction?
    /// Breathing-guide rate (breaths/min) from `BreathingGuideActuatorChannel`.
    public var breathsPerMinute: Double
    /// True while Crooks grounding policy is active (beat / breath channel / residual).
    public var isGrounding: Bool
    /// Latest cross-domain residual bits from `CrossDomainActuatorChannel` / mapper.
    public var crossDomainResidual: Double
    public var crossDomainShouldGround: Bool
    public var crossDomainSource: String
    /// Session HRV entropy baseline (bits). Set at start or captured from first good SCI window.
    public var baselineEntropy: Double?
    /// Last ΔH_hrv (bits) fed to Crooks — baseline-relative when baseline is available.
    public var lastDeltaHRV: Double?

    public init(
        isRunning: Bool = false,
        thermodynamic: ThermodynamicStateSnapshot = ThermodynamicStateSnapshot(),
        lastResult: CrooksCycleUpdateResult? = nil,
        beat: BeatSyncSnapshot? = nil,
        crownBeta: Double = 0,
        tickCount: Int = 0,
        lastPrediction: DeltaHRVFlexAIDPrediction? = nil,
        breathsPerMinute: Double = 0,
        isGrounding: Bool = false,
        crossDomainResidual: Double = 0,
        crossDomainShouldGround: Bool = false,
        crossDomainSource: String = "none",
        baselineEntropy: Double? = nil,
        lastDeltaHRV: Double? = nil
    ) {
        self.isRunning = isRunning
        self.thermodynamic = thermodynamic
        self.lastResult = lastResult
        self.beat = beat
        self.crownBeta = crownBeta
        self.tickCount = tickCount
        self.lastPrediction = lastPrediction
        self.breathsPerMinute = breathsPerMinute
        self.isGrounding = isGrounding
        self.crossDomainResidual = crossDomainResidual
        self.crossDomainShouldGround = crossDomainShouldGround
        self.crossDomainSource = crossDomainSource
        self.baselineEntropy = baselineEntropy
        self.lastDeltaHRV = lastDeltaHRV
    }

    /// Heuristic irreversibility index from the thermodynamic controller state.
    public var sigmaIrr: Double { thermodynamic.sigmaIrr }

    public var sigmaIrrDisplay: String {
        String(format: "%.3f", sigmaIrr)
    }

    /// Breath rate for UI / haptics: published rate, or nominal default when idle.
    public var effectiveBreathsPerMinute: Double {
        if breathsPerMinute.isFinite && breathsPerMinute > 0.1 {
            return breathsPerMinute
        }
        return BreathingGuideActuatorChannel.defaultBreathsPerMinute
    }

    /// Full inhale+exhale period (seconds) from `effectiveBreathsPerMinute`.
    public var breathPeriodSeconds: Double {
        BreathingGuideActuatorChannel.breathPeriodSeconds(rate: effectiveBreathsPerMinute)
    }
}

// MARK: - Pharma Control Session Manager

/// Session orchestrator: SCI / HRV / FlexAID / Crown → `CrooksCycleController`.
///
/// | Integration | Path |
/// |---|---|
/// | `WorkoutFlowViewModel` timer | `tickFromSCI(sciScore:bpm:)` |
/// | Watch Digital Crown | `applyCrownDelta` |
/// | AirPods volume / stem | `applyAirPodsVolumeDelta` / `applyAirPodsStemPress` |
/// | Remote / Debug UI | `snapshot().sigmaIrrDisplay` |
public actor PharmaControlSessionManager {
    public static let shared = PharmaControlSessionManager()

    /// SCI → ΔH_hrv scale for the differential fallback (no baseline yet).
    /// Rising coherence → negative ΔH (collapse).
    private static let sciToDeltaHRVScale: Double = 4.0

    /// Max Shannon entropy for 32-bin HRV (log₂(32) = 5 bits).
    /// Used to invert SCI score → entropy: `H = (1 − SCI) · H_max`.
    public static let sciMaxEntropy: Double = log2(32.0)

    private let controller: CrooksCycleController
    private let crown: CrownController
    private let airPodsCrown: AirPodsCrownBetaController
    private let beatSync: UniversalBeatSync
    private let mapper: DeltaHRVFlexAIDMapper

    private var isRunning = false
    private var tickCount = 0
    private var lastResult: CrooksCycleUpdateResult?
    private var lastSCI: Double?
    /// Session baseline HRV entropy in bits (DrugResponseAnalyzer-aligned).
    private var baselineEntropy: Double?
    /// Last ΔH_hrv (bits) passed into Crooks.
    private var lastDeltaHRV: Double?
    /// Plan/kind-aware origin for Crooks fractional BPM channel.
    private var sessionNominalBPM: Double = CrooksCycleDefaults.nominalBPM
    /// Plan/kind-aware recovery tempo when grounding fires.
    private var sessionGroundingBPM: Double = CrooksCycleDefaults.groundingBPM

    public init(
        controller: CrooksCycleController = .shared,
        crown: CrownController = .shared,
        airPodsCrown: AirPodsCrownBetaController = .shared,
        beatSync: UniversalBeatSync = .shared,
        mapper: DeltaHRVFlexAIDMapper = .shared
    ) {
        self.controller = controller
        self.crown = crown
        self.airPodsCrown = airPodsCrown
        self.beatSync = beatSync
        self.mapper = mapper
    }

    /// Invert a 0–1 SCI coherence score to Shannon entropy bits.
    ///
    /// ```
    ///   score = 1 − H / H_max  ⇒  H = (1 − score) · H_max
    /// ```
    /// Non-finite / out-of-range SCI is clamped; non-finite max → default 5 bits.
    public nonisolated static func entropyFromSCI(
        _ sci: Double,
        maxEntropy: Double = PharmaControlSessionManager.sciMaxEntropy
    ) -> Double {
        let s = sci.isFinite ? max(0, min(1, sci)) : 0.5
        let hMax = (maxEntropy.isFinite && maxEntropy > 0)
            ? maxEntropy
            : Self.sciMaxEntropy
        let h = (1.0 - s) * hMax
        return h.isFinite ? h : 0
    }

    /// Sanitize an optional baseline entropy (bits). Rejects non-finite and negative.
    public nonisolated static func sanitizedBaselineEntropy(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }

    /// Start a control session. Pass plan-aware BPM defaults from `WorkoutPlan.style`.
    ///
    /// - Parameter baselineEntropy: Optional pre-session HRV Shannon entropy (bits).
    ///   When nil/non-finite, the first good SCI window captures baseline automatically.
    public func start(
        baselineEntropy: Double? = nil,
        nominalBPM: Double = CrooksCycleDefaults.nominalBPM,
        groundingBPM: Double = CrooksCycleDefaults.groundingBPM
    ) async {
        isRunning = true
        tickCount = 0
        lastResult = nil
        lastSCI = nil
        lastDeltaHRV = nil
        self.baselineEntropy = Self.sanitizedBaselineEntropy(baselineEntropy)
        sessionNominalBPM = (nominalBPM.isFinite && nominalBPM > 0) ? nominalBPM : CrooksCycleDefaults.nominalBPM
        sessionGroundingBPM = (groundingBPM.isFinite && groundingBPM > 0) ? groundingBPM : CrooksCycleDefaults.groundingBPM
        await controller.reset()
        await ControlActuatorSnapshotStore.shared.reset()
        let baseNote = self.baselineEntropy.map { String(format: " baselineH=%.3f" , $0) } ?? " baselineH=auto"
        await SessionEventLog.shared.append(
            "pharma_session_start nominalBPM=\(sessionNominalBPM) groundingBPM=\(sessionGroundingBPM)\(baseNote)"
        )
    }

    public func stop() async {
        isRunning = false
        // Drop beat listeners so the next session can rebind without stacking.
        await beatSync.removeAllListeners()
        await SessionEventLog.shared.append("pharma_session_stop ticks=\(tickCount)")
    }

    /// Digital Crown gesture (Watch). Mirrors β to AirPods dial.
    ///
    /// β-only — does **not** call `UniversalBeatSync.broadcast`.
    /// Tempo is owned by the next Crooks tick via `ActuatorBus.broadcastBeat`.
    @discardableResult
    public func applyCrownDelta(_ delta: Double) async -> Double {
        let beta = await crown.applyCrownDelta(delta)
        _ = await airPodsCrown.mirrorWatchCrown(beta: beta)
        return beta
    }

    /// Absolute crown β (remote / slider). β-only — no beat broadcast.
    @discardableResult
    public func setCrownBeta(_ beta: Double) async -> Double {
        let b = await crown.setBeta(beta)
        _ = await airPodsCrown.mirrorWatchCrown(beta: b)
        return b
    }

    /// AirPods volume rocker as crown-equivalent (β only; no beat broadcast).
    @discardableResult
    public func applyAirPodsVolumeDelta(_ delta: Double) async -> Double {
        await airPodsCrown.applyVolumeDelta(delta)
    }

    /// AirPods stem Force Sensor press → soft β damp (β only; no beat broadcast).
    @discardableResult
    public func applyAirPodsStemPress(gain: Double = 0.25) async -> Double {
        await airPodsCrown.applyStemPress(gain: gain)
    }

    /// App layer: AirPods / Bluetooth headphone route presence.
    public func setAirPodsRouteActive(_ active: Bool) async {
        await airPodsCrown.setRouteActive(active)
    }

    /// Primary tick with explicit multi-domain features.
    @discardableResult
    public func tick(_ input: PharmaControlTick) async -> CrooksCycleUpdateResult {
        guard isRunning else {
            return CrooksCycleUpdateResult(
                work: 0, sigmaIrr: 0, phase: .forward,
                didGround: false, didFlipPhase: false, cycleCount: 0,
                eigenBackend: "idle", usedANEPath: false
            )
        }

        let safeDelta = input.deltaHRV.isFinite ? input.deltaHRV : 0
        lastDeltaHRV = safeDelta

        let beta = input.crownBeta.isFinite
            ? input.crownBeta
            : await crown.currentBeta()

        let result = await controller.update(
            deltaHRV: safeDelta,
            flexAIDDeltaS: input.flexAIDDeltaS,
            crownBeta: beta,
            bpm: input.bpm,
            substanceId: input.substanceId,
            nominalBPM: sessionNominalBPM,
            groundingBPM: sessionGroundingBPM
        )
        lastResult = result
        tickCount += 1
        if let sci = input.sciScore {
            lastSCI = sci
        }
        return result
    }

    /// Derive ΔH_hrv from SCI and optional FlexAID ΔS, then tick Crooks.
    ///
    /// ## Baseline-relative ΔH (preferred)
    /// SCI is 0–1 coherence (1 = low entropy). Invert to bits and subtract session baseline:
    /// ```
    ///   H      = (1 − SCI) · H_max          // H_max = log₂(32) = 5 bits
    ///   ΔH_hrv = H − H_baseline             // matches DrugResponseAnalyzer
    /// ```
    /// Baseline is taken from `start(baselineEntropy:)` when finite, otherwise captured
    /// from the first good SCI window (finite score → finite H). Capture tick has ΔH = 0.
    ///
    /// ## Differential fallback (no baseline yet)
    /// ```
    ///   ΔH_hrv ≈ −(SCI − lastSCI) × 4
    /// ```
    /// Rising coherence → negative ΔH (collapse).
    @discardableResult
    public func tickFromSCI(
        sciScore: Double?,
        bpm: Double,
        flexAIDDeltaS: Double = 0,
        substanceId: String? = nil,
        crownBeta: Double? = nil
    ) async -> CrooksCycleUpdateResult {
        let rawSCI = sciScore ?? lastSCI ?? 0.5
        let sci = rawSCI.isFinite ? max(0, min(1, rawSCI)) : 0.5
        let deltaHRV = resolveDeltaHRV(sci: sci)
        lastSCI = sci

        let beta: Double
        if let crownBeta, crownBeta.isFinite {
            beta = crownBeta
        } else {
            beta = await crown.currentBeta()
        }
        let safeBPM = bpm.isFinite ? bpm : sessionNominalBPM
        let safeFlex = flexAIDDeltaS.isFinite ? flexAIDDeltaS : 0

        return await tick(PharmaControlTick(
            deltaHRV: deltaHRV,
            flexAIDDeltaS: safeFlex,
            crownBeta: beta,
            bpm: safeBPM,
            substanceId: substanceId,
            sciScore: sci
        ))
    }

    /// Resolve ΔH_hrv (bits) for a sanitized SCI score.
    /// Captures baseline from the first good window when none was provided at start.
    private func resolveDeltaHRV(sci: Double) -> Double {
        let h = Self.entropyFromSCI(sci)

        // Capture baseline from first good SCI window (finite H after clamp).
        if baselineEntropy == nil {
            if h.isFinite {
                baselineEntropy = h
                // Relative to the just-captured baseline → ΔH = 0 on capture tick.
                return 0
            }
            // No usable window yet — differential fallback.
            let prev = lastSCI ?? sci
            let d = -(sci - prev) * Self.sciToDeltaHRVScale
            return d.isFinite ? d : 0
        }

        guard let base = baselineEntropy, base.isFinite else {
            let prev = lastSCI ?? sci
            let d = -(sci - prev) * Self.sciToDeltaHRVScale
            return d.isFinite ? d : 0
        }

        let delta = h - base
        return delta.isFinite ? delta : 0
    }

    public func snapshot() async -> PharmaControlSessionSnapshot {
        let thermo = await controller.snapshot()
        let beat = await beatSync.current()
        let beta = await crown.currentBeta()
        let pred = await mapper.last()
        let actuators = ControlActuatorSnapshotStore.shared
        let breath = await actuators.breathsPerMinute
        let breathGrounding = await actuators.isGrounding
        let residual = await actuators.crossDomainResidual
        let residualGround = await actuators.crossDomainShouldGround
        let residualSource = await actuators.crossDomainSource
        // Sticky grounding: breath channel, beat lock, last tick, residual, or σ_irr.
        let grounding = breathGrounding
            || beat.isGrounding
            || (lastResult?.didGround == true)
            || residualGround
            || thermo.sigmaIrr > CrooksCycleDefaults.groundingThreshold
        return PharmaControlSessionSnapshot(
            isRunning: isRunning,
            thermodynamic: thermo,
            lastResult: lastResult,
            beat: beat,
            crownBeta: beta,
            tickCount: tickCount,
            lastPrediction: pred,
            breathsPerMinute: breath,
            isGrounding: grounding,
            crossDomainResidual: residual,
            crossDomainShouldGround: residualGround,
            crossDomainSource: residualSource,
            baselineEntropy: baselineEntropy,
            lastDeltaHRV: lastDeltaHRV
        )
    }

    /// FlexAID ΔS from `BindingEntropyProfile` when docking data is offline.
    public nonisolated func referenceDeltaS(for substanceId: String) -> Double {
        BindingEntropyProfile.profile(for: substanceId)?.expectedDeltaSBits ?? 0
    }
}
