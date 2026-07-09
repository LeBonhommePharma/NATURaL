import Foundation

// MARK: - Beat Sync State

/// Snapshot of the universal beat clock used across actuators and UI.
public struct BeatSyncSnapshot: Sendable, Equatable {
    /// Target BPM for all channels.
    public var bpm: Double
    /// Phase in [0, 1) of the current beat cycle.
    public var phase: Double
    /// Wall-clock time of last tick.
    public var lastTick: Date
    /// Accumulated beat count in the current session.
    public var beatCount: Int
    /// Crown β associated with the last broadcast.
    public var crownBeta: Double
    /// Whether this is a grounding (recovery) tempo.
    public var isGrounding: Bool

    public init(
        bpm: Double = CrooksCycleDefaults.nominalBPM,
        phase: Double = 0,
        lastTick: Date = Date(),
        beatCount: Int = 0,
        crownBeta: Double = 0,
        isGrounding: Bool = false
    ) {
        self.bpm = bpm
        self.phase = phase
        self.lastTick = lastTick
        self.beatCount = beatCount
        self.crownBeta = crownBeta
        self.isGrounding = isGrounding
    }

    /// Seconds per beat at current BPM.
    public var secondsPerBeat: Double {
        guard bpm > 0 else { return 0.5 }
        return 60.0 / bpm
    }
}

// MARK: - Universal Beat Sync

/// Production universal beat synchronizer.
///
/// Single source of truth for tempo across Music, Watch haptics, TV display,
/// and AirPods-class playback. No stubs — phase is continuously integrable from BPM.
public actor UniversalBeatSync {
    public static let shared = UniversalBeatSync()

    private var snapshot = BeatSyncSnapshot()
    private var listeners: [@Sendable (BeatSyncSnapshot) async -> Void] = []

    public init() {}

    /// Current beat snapshot.
    public func current() -> BeatSyncSnapshot {
        advancePhase(to: Date())
        return snapshot
    }

    /// Register an async listener for beat broadcasts (music, haptics, TV).
    public func addListener(_ listener: @escaping @Sendable (BeatSyncSnapshot) async -> Void) {
        listeners.append(listener)
    }

    /// Force all channels to a BPM / β pair and broadcast.
    @discardableResult
    public func broadcast(bpm: Double, beta: Double, grounding: Bool = false) async -> BeatSyncSnapshot {
        let now = Date()
        advancePhase(to: now)
        let clampedBPM = max(40, min(220, bpm))
        snapshot.bpm = clampedBPM
        snapshot.crownBeta = max(-1, min(1, beta))
        snapshot.isGrounding = grounding
        snapshot.lastTick = now

        let out = snapshot
        for listener in listeners {
            await listener(out)
        }
        return out
    }

    /// Advance phase by wall-clock time; increments beatCount on wrap.
    @discardableResult
    public func tick(now: Date = Date()) -> BeatSyncSnapshot {
        advancePhase(to: now)
        return snapshot
    }

    /// Instant phase at a given date without mutating (for UI sampling).
    public func phase(at date: Date) -> Double {
        let elapsed = date.timeIntervalSince(snapshot.lastTick)
        let spb = snapshot.secondsPerBeat
        guard spb > 0 else { return snapshot.phase }
        let advanced = snapshot.phase + elapsed / spb
        return advanced - floor(advanced)
    }

    // MARK: - Private

    private func advancePhase(to now: Date) {
        let elapsed = now.timeIntervalSince(snapshot.lastTick)
        guard elapsed > 0 else { return }
        let spb = snapshot.secondsPerBeat
        guard spb > 0 else { return }

        let delta = elapsed / spb
        let total = snapshot.phase + delta
        let whole = Int(floor(total))
        if whole > 0 {
            snapshot.beatCount += whole
        }
        snapshot.phase = total - Double(whole)
        snapshot.lastTick = now
    }
}
