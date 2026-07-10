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
        crossDomainSource: String = "none"
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

    /// SCI → ΔH_hrv scale: rising coherence → negative ΔH (collapse).
    private static let sciToDeltaHRVScale: Double = 4.0

    private let controller: CrooksCycleController
    private let crown: CrownController
    private let airPodsCrown: AirPodsCrownBetaController
    private let beatSync: UniversalBeatSync
    private let mapper: DeltaHRVFlexAIDMapper

    private var isRunning = false
    private var tickCount = 0
    private var lastResult: CrooksCycleUpdateResult?
    private var lastSCI: Double?
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

    /// Start a control session. Pass plan-aware BPM defaults from `WorkoutPlan.style`.
    public func start(
        baselineEntropy: Double? = nil,
        nominalBPM: Double = CrooksCycleDefaults.nominalBPM,
        groundingBPM: Double = CrooksCycleDefaults.groundingBPM
    ) async {
        isRunning = true
        tickCount = 0
        lastResult = nil
        lastSCI = nil
        sessionNominalBPM = (nominalBPM.isFinite && nominalBPM > 0) ? nominalBPM : CrooksCycleDefaults.nominalBPM
        sessionGroundingBPM = (groundingBPM.isFinite && groundingBPM > 0) ? groundingBPM : CrooksCycleDefaults.groundingBPM
        _ = baselineEntropy // reserved for future baseline-relative ΔH
        await controller.reset()
        await ControlActuatorSnapshotStore.shared.reset()
        await SessionEventLog.shared.append(
            "pharma_session_start nominalBPM=\(sessionNominalBPM) groundingBPM=\(sessionGroundingBPM)"
        )
    }

    public func stop() async {
        isRunning = false
        // Drop beat listeners so the next session can rebind without stacking.
        await beatSync.removeAllListeners()
        await SessionEventLog.shared.append("pharma_session_stop ticks=\(tickCount)")
    }

    /// Digital Crown gesture (Watch). Mirrors β to AirPods dial.
    @discardableResult
    public func applyCrownDelta(_ delta: Double) async -> Double {
        let beta = await crown.applyCrownDelta(delta)
        _ = await airPodsCrown.mirrorWatchCrown(beta: beta)
        return beta
    }

    @discardableResult
    public func setCrownBeta(_ beta: Double) async -> Double {
        let b = await crown.setBeta(beta)
        _ = await airPodsCrown.mirrorWatchCrown(beta: b)
        return b
    }

    /// AirPods volume rocker as crown-equivalent.
    @discardableResult
    public func applyAirPodsVolumeDelta(_ delta: Double) async -> Double {
        await airPodsCrown.applyVolumeDelta(delta)
    }

    /// AirPods stem Force Sensor press → soft β damp.
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

        let beta = input.crownBeta.isFinite
            ? input.crownBeta
            : await crown.currentBeta()

        let result = await controller.update(
            deltaHRV: input.deltaHRV,
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

    /// Derive ΔH_hrv from SCI change and optional FlexAID ΔS.
    ///
    /// SCI is 0–1 coherence (1 = low entropy). Proxy:
    /// ```
    ///   deltaHRV ≈ −(sci − lastSCI) × 4
    /// ```
    /// Rising coherence → negative ΔH (collapse), matching `DrugResponseAnalyzer`.
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
        let prev = lastSCI ?? sci
        let deltaHRV = -(sci - prev) * Self.sciToDeltaHRVScale
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
            deltaHRV: deltaHRV.isFinite ? deltaHRV : 0,
            flexAIDDeltaS: safeFlex,
            crownBeta: beta,
            bpm: safeBPM,
            substanceId: substanceId,
            sciScore: sci
        ))
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
            crossDomainSource: residualSource
        )
    }

    /// FlexAID ΔS from `BindingEntropyProfile` when docking data is offline.
    public nonisolated func referenceDeltaS(for substanceId: String) -> Double {
        BindingEntropyProfile.profile(for: substanceId)?.expectedDeltaSBits ?? 0
    }
}
