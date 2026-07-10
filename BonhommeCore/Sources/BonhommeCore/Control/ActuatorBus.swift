import Foundation

// MARK: - Commands

/// Side-effect commands issued by Crooks-cycle control.
public enum ActuatorCommand: Sendable, Equatable {
    /// High σ_irr recovery: lower BPM, damp β, log, cross-domain ground.
    case grounding(sigmaIrr: Double, bpm: Double, beta: Double)
    /// Universal tempo lock (single broadcast authority → `UniversalBeatSync`).
    case beatBroadcast(bpm: Double, beta: Double, grounding: Bool)
    /// Phase flip after near-reversible cycle closure.
    case phaseFlip(from: ThermodynamicPhase, to: ThermodynamicPhase, cycleCount: Int)
    /// Micro-survey / session log hook for the HealthKit app layer.
    case microSurveyLog(sigmaIrr: Double, work: Double)
}

/// Result of executing a command on one channel.
public struct ActuatorChannelResult: Sendable, Equatable {
    public let channelId: String
    public let command: ActuatorCommand
    public let success: Bool
    public let detail: String

    public init(channelId: String, command: ActuatorCommand, success: Bool, detail: String) {
        self.channelId = channelId
        self.command = command
        self.success = success
        self.detail = detail
    }
}

// MARK: - Channel Protocol

/// Actuator channel. Implementations perform real side-effects (state, beat, logs).
public protocol ActuatorChannel: Sendable {
    var id: String { get }
    func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult
}

// MARK: - Production Channels

/// Sole owner of `UniversalBeatSync.broadcast` — all other channels only mutate local state.
///
/// Grounding does **not** broadcast here: Crooks end-of-tick `broadcastBeat` is the single
/// beat authority (avoids double-broadcast on ground path that raced recovery tempo).
public struct BeatSyncActuatorChannel: ActuatorChannel {
    public let id = "universal_beat_sync"
    private let beatSync: UniversalBeatSync

    public init(beatSync: UniversalBeatSync = .shared) {
        self.beatSync = beatSync
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding(_, let bpm, _):
            // β damp / recovery BPM applied by end-of-tick broadcastBeat only.
            return ok(command, "grounding deferred-to-tick from \(bpm)")
        case .beatBroadcast(let bpm, let beta, let grounding):
            let snap = await beatSync.broadcast(bpm: bpm, beta: beta, grounding: grounding)
            return ok(command, "broadcast bpm=\(snap.bpm) beta=\(fmt(snap.crownBeta))")
        case .phaseFlip(let from, let to, let cycle):
            // Log-only: Crooks end-of-tick `broadcastBeat` is the sole beat authority.
            // Re-broadcast here double-fired listeners on every phase flip.
            return ok(command, "phase-flip log-only \(from.rawValue)→\(to.rawValue) cycle=\(cycle)")
        case .microSurveyLog:
            return ok(command, "idle")
        }
    }

    private func ok(_ command: ActuatorCommand, _ detail: String) -> ActuatorChannelResult {
        ActuatorChannelResult(channelId: id, command: command, success: true, detail: detail)
    }
}

/// Watch Digital Crown β dial — state only; beat is owned by `BeatSyncActuatorChannel`.
public struct CrownActuatorChannel: ActuatorChannel {
    public let id = "crown_beta_dial"
    private let crown: CrownController

    public init(crown: CrownController = .shared) {
        self.crown = crown
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding(let sigma, let bpm, _):
            let beta = await crown.dampTowardNeutral(gain: CrooksCycleDefaults.groundingCorrectiveGain)
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: "damped β=\(fmt(beta)) σ_irr=\(fmt(sigma)) bpm→\(CrooksCycleDefaults.groundingBPM) from \(bpm)"
            )
        case .beatBroadcast(_, let beta, _):
            _ = await crown.setBeta(beta)
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: "scene=\(await crown.dialSnapshot().sceneLabel)"
            )
        case .phaseFlip(let from, let to, let cycle):
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: "cycle \(cycle): \(from.rawValue)→\(to.rawValue)"
            )
        case .microSurveyLog:
            return ActuatorChannelResult(channelId: id, command: command, success: true, detail: "ok")
        }
    }
}

/// Cross-domain ΔH_hrv ↔ FlexAID residual (BindingEntropyProfile / calibrated slope).
///
/// Publishes the latest residual into `ControlActuatorSnapshotStore` so UI / session
/// snapshots can surface residual without treating this channel as a pure log sink.
public struct CrossDomainActuatorChannel: ActuatorChannel {
    public let id = "delta_hrv_flexaid"
    private let mapper: DeltaHRVFlexAIDMapper

    public init(mapper: DeltaHRVFlexAIDMapper = .shared) {
        self.mapper = mapper
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding(let sigma, _, _):
            let pred = await mapper.predictAndGround(deltaHRV: 0, flexAIDDeltaS: 0)
            await ControlActuatorSnapshotStore.shared.publishCrossDomain(
                residual: pred.residual,
                shouldGround: pred.shouldGround,
                source: pred.source
            )
            await SessionEventLog.shared.append(
                "cross_domain residual=\(fmt(pred.residual)) ground=\(pred.shouldGround) source=\(pred.source)"
            )
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: "residual=\(fmt(pred.residual)) σ_irr=\(fmt(sigma)) source=\(pred.source)"
            )
        case .beatBroadcast, .phaseFlip, .microSurveyLog:
            return ActuatorChannelResult(channelId: id, command: command, success: true, detail: "idle")
        }
    }
}

/// Ring buffer of session control events (app layer may mirror to HealthKit / CareKit).
public actor SessionEventLog {
    public static let shared = SessionEventLog()
    public private(set) var events: [String] = []

    private static let capacity = 500
    /// Trim only after this many over-capacity appends to avoid O(n) shift every line.
    private static let trimSlack = 64

    public func append(_ line: String) {
        events.append(line)
        if events.count > Self.capacity + Self.trimSlack {
            events.removeFirst(events.count - Self.capacity)
        }
    }

    public func all() -> [String] { events }

    public func clear() { events.removeAll(keepingCapacity: true) }
}

/// Session event log channel.
public struct SessionLogActuatorChannel: ActuatorChannel {
    public let id = "session_log"
    private let log: SessionEventLog

    /// Shared formatter — avoid allocating `ISO8601DateFormatter` on every grounding tick.
    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    public init(log: SessionEventLog = .shared) {
        self.log = log
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        let line: String
        switch command {
        case .grounding(let sigma, let bpm, let beta):
            line = "grounding σ_irr=\(sigma) bpm=\(bpm) β=\(beta) t=\(Self.iso8601.string(from: Date()))"
        case .beatBroadcast(let bpm, let beta, let g):
            line = "beat bpm=\(bpm) β=\(beta) grounding=\(g)"
        case .phaseFlip(let from, let to, let n):
            line = "phase_flip \(from.rawValue)→\(to.rawValue) cycle=\(n)"
        case .microSurveyLog(let sigma, let work):
            line = "micro_survey σ_irr=\(sigma) work=\(work)"
        }
        await log.append(line)
        return ActuatorChannelResult(channelId: id, command: command, success: true, detail: line)
    }
}

/// Breathing-guide tempo derived from session BPM.
///
/// Conversion: `breaths/min ≈ bpm / bpmPerBreath`.
/// At grounding (92 BPM): 92 / 15.2 ≈ 6.05 breaths/min — clinical recovery cadence.
///
/// Publishes `breathsPerMinute` into `ControlActuatorSnapshotStore` for session UI;
/// also appends a session-log line so the rate is inspectable offline.
public struct BreathingGuideActuatorChannel: ActuatorChannel {
    public let id = "breathing_guide"

    /// BPM divided by this yields seated breath rate (~6/min at grounding tempo).
    public static let bpmPerBreath: Double = 15.2

    public init() {}

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding:
            let rate = CrooksCycleDefaults.groundingBPM / Self.bpmPerBreath
            await ControlActuatorSnapshotStore.shared.publishBreathRate(rate)
            await SessionEventLog.shared.append(String(format: "breath %.1f/min grounding", rate))
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: String(format: "breathe %.1f/min grounding", rate)
            )
        case .beatBroadcast(let bpm, _, let grounding):
            let rate = bpm / Self.bpmPerBreath
            await ControlActuatorSnapshotStore.shared.publishBreathRate(rate)
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: String(format: "breathe %.1f/min g=%@", rate, String(grounding))
            )
        default:
            return ActuatorChannelResult(channelId: id, command: command, success: true, detail: "idle")
        }
    }
}

// MARK: - Shared actuator snapshot (breath / cross-domain)

/// Lightweight published state from channels that are not pure telemetry-only.
/// Consumed by `PharmaControlSessionManager.snapshot()`.
public actor ControlActuatorSnapshotStore {
    public static let shared = ControlActuatorSnapshotStore()

    public private(set) var breathsPerMinute: Double = 0
    public private(set) var crossDomainResidual: Double = 0
    public private(set) var crossDomainShouldGround: Bool = false
    public private(set) var crossDomainSource: String = "none"

    public func publishBreathRate(_ rate: Double) {
        breathsPerMinute = rate.isFinite ? max(0, rate) : 0
    }

    public func publishCrossDomain(residual: Double, shouldGround: Bool, source: String) {
        crossDomainResidual = residual.isFinite ? residual : 0
        crossDomainShouldGround = shouldGround
        crossDomainSource = source
    }

    public func reset() {
        breathsPerMinute = 0
        crossDomainResidual = 0
        crossDomainShouldGround = false
        crossDomainSource = "none"
    }
}

// MARK: - Actuator Bus

/// Multiplexes Crooks commands to all registered channels.
///
/// Default wiring: beat · crown · AirPods · cross-domain · log · breathing.
/// `BeatSyncActuatorChannel` is the only path that calls `UniversalBeatSync.broadcast`.
public actor ActuatorBus {
    public static let shared = ActuatorBus.makeProduction()

    private var channels: [any ActuatorChannel]
    private var lastResults: [ActuatorChannelResult] = []

    public init(channels: [any ActuatorChannel]) {
        self.channels = channels
    }

    public static func makeProduction() -> ActuatorBus {
        ActuatorBus(channels: [
            BeatSyncActuatorChannel(),
            CrownActuatorChannel(),
            AirPodsCrownActuatorChannel(),
            CrossDomainActuatorChannel(),
            SessionLogActuatorChannel(),
            BreathingGuideActuatorChannel()
        ])
    }

    public func register(_ channel: any ActuatorChannel) {
        channels.append(channel)
    }

    public func channelIds() -> [String] {
        channels.map(\.id)
    }

    public func lastExecutionResults() -> [ActuatorChannelResult] {
        lastResults
    }

    @discardableResult
    public func executeGrounding(sigmaIrr: Double, bpm: Double, beta: Double) async -> [ActuatorChannelResult] {
        await dispatch(.grounding(sigmaIrr: sigmaIrr, bpm: bpm, beta: beta))
    }

    @discardableResult
    public func broadcastBeat(bpm: Double, beta: Double, grounding: Bool = false) async -> [ActuatorChannelResult] {
        await dispatch(.beatBroadcast(bpm: bpm, beta: beta, grounding: grounding))
    }

    @discardableResult
    public func executePhaseFlip(
        from: ThermodynamicPhase,
        to: ThermodynamicPhase,
        cycleCount: Int
    ) async -> [ActuatorChannelResult] {
        await dispatch(.phaseFlip(from: from, to: to, cycleCount: cycleCount))
    }

    @discardableResult
    public func logMicroSurvey(sigmaIrr: Double, work: Double) async -> [ActuatorChannelResult] {
        await dispatch(.microSurveyLog(sigmaIrr: sigmaIrr, work: work))
    }

    @discardableResult
    public func dispatch(_ command: ActuatorCommand) async -> [ActuatorChannelResult] {
        // Beat channel first (tempo authority), remaining channels in parallel.
        let beatChannels = channels.filter { $0.id == "universal_beat_sync" }
        let otherChannels = channels.filter { $0.id != "universal_beat_sync" }

        var results: [ActuatorChannelResult] = []
        results.reserveCapacity(channels.count)

        for channel in beatChannels {
            results.append(await channel.execute(command))
        }

        if !otherChannels.isEmpty {
            let parallel = await withTaskGroup(of: ActuatorChannelResult.self) { group in
                for channel in otherChannels {
                    group.addTask { await channel.execute(command) }
                }
                var collected: [ActuatorChannelResult] = []
                collected.reserveCapacity(otherChannels.count)
                for await result in group {
                    collected.append(result)
                }
                return collected
            }
            results.append(contentsOf: parallel)
        }

        lastResults = results
        return results
    }
}

// MARK: - Formatting

private func fmt(_ v: Double) -> String {
    String(format: "%.3f", v)
}
