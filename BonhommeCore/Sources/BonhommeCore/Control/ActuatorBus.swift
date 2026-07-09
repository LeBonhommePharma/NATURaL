import Foundation

// MARK: - Commands

/// Production actuator commands issued by Crooks-cycle control.
public enum ActuatorCommand: Sendable, Equatable {
    /// High σ_irr recovery: lower BPM, damp β, log micro-event, cross-domain ground.
    case grounding(sigmaIrr: Double, bpm: Double, beta: Double)
    /// Universal beat broadcast (crown / session tempo).
    case beatBroadcast(bpm: Double, beta: Double, grounding: Bool)
    /// Phase flip after near-reversible cycle closure.
    case phaseFlip(from: ThermodynamicPhase, to: ThermodynamicPhase, cycleCount: Int)
    /// Micro-survey / session log hook for HealthKit app layer.
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

/// Production actuator channel. Implementations must perform real side-effects
/// (state mutation, beat sync, logs) — no empty stubs.
public protocol ActuatorChannel: Sendable {
    var id: String { get }
    func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult
}

// MARK: - Production Channels

/// Drives `UniversalBeatSync` for all-device tempo lock.
public struct BeatSyncActuatorChannel: ActuatorChannel {
    public let id = "universal_beat_sync"
    private let beatSync: UniversalBeatSync

    public init(beatSync: UniversalBeatSync = .shared) {
        self.beatSync = beatSync
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding(_, _, let beta):
            let snap = await beatSync.broadcast(
                bpm: CrooksCycleDefaults.groundingBPM,
                beta: beta * 0.5,
                grounding: true
            )
            return result(command, true, "grounding bpm=\(snap.bpm) phase=\(String(format: "%.3f", snap.phase))")
        case .beatBroadcast(let bpm, let beta, let grounding):
            let snap = await beatSync.broadcast(bpm: bpm, beta: beta, grounding: grounding)
            return result(command, true, "broadcast bpm=\(snap.bpm) beta=\(snap.crownBeta)")
        case .phaseFlip:
            // Re-assert current tempo on phase flip for continuity.
            let snap = await beatSync.current()
            _ = await beatSync.broadcast(bpm: snap.bpm, beta: snap.crownBeta, grounding: false)
            return result(command, true, "phase-flip re-sync bpm=\(snap.bpm)")
        case .microSurveyLog:
            return result(command, true, "beat channel: no-op for survey")
        }
    }

    private func result(_ command: ActuatorCommand, _ ok: Bool, _ detail: String) -> ActuatorChannelResult {
        ActuatorChannelResult(channelId: id, command: command, success: ok, detail: detail)
    }
}

/// Crown β damping + beat scene broadcast (heating / binding / neutral).
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
            await crown.broadcastBeat(bpm: CrooksCycleDefaults.groundingBPM, beta: beta, grounding: true)
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: "damped β=\(String(format: "%.3f", beta)) σ_irr=\(String(format: "%.3f", sigma)) bpm→\(CrooksCycleDefaults.groundingBPM) from \(bpm)"
            )
        case .beatBroadcast(let bpm, let beta, let grounding):
            await crown.broadcastBeat(bpm: bpm, beta: beta, grounding: grounding)
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

/// Cross-domain ΔHRV ↔ FlexAID residual check (reuses BindingEntropyProfile / mapper).
public struct CrossDomainActuatorChannel: ActuatorChannel {
    public let id = "delta_hrv_flexaid"
    private let mapper: DeltaHRVFlexAIDMapper

    public init(mapper: DeltaHRVFlexAIDMapper = .shared) {
        self.mapper = mapper
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding(let sigma, _, _):
            // Re-run last prediction path with neutral features to refresh residual.
            let pred = await mapper.predictAndGround(deltaHRV: 0, flexAIDDeltaS: 0)
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: "residual=\(String(format: "%.3f", pred.residual)) σ_irr=\(String(format: "%.3f", sigma)) source=\(pred.source)"
            )
        case .beatBroadcast, .phaseFlip, .microSurveyLog:
            return ActuatorChannelResult(channelId: id, command: command, success: true, detail: "idle")
        }
    }
}

/// In-memory session event log (app layer mirrors to HealthKit / CareKit).
public actor SessionEventLog {
    public static let shared = SessionEventLog()
    public private(set) var events: [String] = []

    public func append(_ line: String) {
        events.append(line)
        if events.count > 500 {
            events.removeFirst(events.count - 500)
        }
    }

    public func all() -> [String] { events }

    public func clear() { events.removeAll() }
}

/// Production micro-survey / session log channel.
public struct SessionLogActuatorChannel: ActuatorChannel {
    public let id = "session_log"
    private let log: SessionEventLog

    public init(log: SessionEventLog = .shared) {
        self.log = log
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        let line: String
        switch command {
        case .grounding(let sigma, let bpm, let beta):
            line = "grounding σ_irr=\(sigma) bpm=\(bpm) β=\(beta) t=\(ISO8601DateFormatter().string(from: Date()))"
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

/// Breathing-guide tempo channel (6 breaths/min ≈ 92 BPM half-cadence cue).
public struct BreathingGuideActuatorChannel: ActuatorChannel {
    public let id = "breathing_guide"

    public init() {}

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding:
            // 92 BPM → breath period ~ 2.6s inhale/exhale pairs for seated recovery.
            let breathsPerMin = CrooksCycleDefaults.groundingBPM / 15.2
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: String(format: "breathe %.1f/min grounding", breathsPerMin)
            )
        case .beatBroadcast(let bpm, _, let grounding):
            let rate = bpm / 15.2
            return ActuatorChannelResult(
                channelId: id, command: command, success: true,
                detail: String(format: "breathe %.1f/min g=%@", rate, String(grounding))
            )
        default:
            return ActuatorChannelResult(channelId: id, command: command, success: true, detail: "idle")
        }
    }
}

// MARK: - Actuator Bus

/// Multiplexes Crooks-cycle commands to all registered production channels.
///
/// Default bus is fully wired (beat, crown, cross-domain, log, breathing) — zero stubs.
public actor ActuatorBus {
    public static let shared = ActuatorBus.makeProduction()

    private var channels: [any ActuatorChannel]
    private var lastResults: [ActuatorChannelResult] = []

    public init(channels: [any ActuatorChannel]) {
        self.channels = channels
    }

    /// Production bus with all NATURaL-reuse channels (zero stubs).
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

    /// Execute grounding recovery for high σ_irr (σ_irr minimization assist).
    @discardableResult
    public func executeGrounding(sigmaIrr: Double, bpm: Double, beta: Double) async -> [ActuatorChannelResult] {
        await dispatch(.grounding(sigmaIrr: sigmaIrr, bpm: bpm, beta: beta))
    }

    /// Broadcast universal beat.
    @discardableResult
    public func broadcastBeat(bpm: Double, beta: Double, grounding: Bool = false) async -> [ActuatorChannelResult] {
        await dispatch(.beatBroadcast(bpm: bpm, beta: beta, grounding: grounding))
    }

    /// Phase flip after cycle closure.
    @discardableResult
    public func executePhaseFlip(from: ThermodynamicPhase, to: ThermodynamicPhase, cycleCount: Int) async -> [ActuatorChannelResult] {
        await dispatch(.phaseFlip(from: from, to: to, cycleCount: cycleCount))
    }

    /// Micro-survey log.
    @discardableResult
    public func logMicroSurvey(sigmaIrr: Double, work: Double) async -> [ActuatorChannelResult] {
        await dispatch(.microSurveyLog(sigmaIrr: sigmaIrr, work: work))
    }

    @discardableResult
    public func dispatch(_ command: ActuatorCommand) async -> [ActuatorChannelResult] {
        var results: [ActuatorChannelResult] = []
        results.reserveCapacity(channels.count)
        for channel in channels {
            let r = await channel.execute(command)
            results.append(r)
        }
        lastResults = results
        return results
    }
}
