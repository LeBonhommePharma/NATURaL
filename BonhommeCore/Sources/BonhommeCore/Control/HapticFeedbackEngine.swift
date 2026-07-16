import Foundation

#if canImport(CoreHaptics)
import CoreHaptics
#endif

// MARK: - Patterns

/// Discrete haptic intents used by Crooks / validation / beat paths.
public enum HapticPatternIntent: String, Sendable, Equatable {
    case beatPulse
    case grounding
    case validationPass
    case validationFail
    case biometricModulated
    case phaseFlip
}

/// Parameters for a single haptic render request.
public struct HapticRenderRequest: Sendable, Equatable {
    public var intent: HapticPatternIntent
    /// 0…1 intensity.
    public var intensity: Double
    /// 0…1 sharpness.
    public var sharpness: Double
    public var heartRateBPM: Double?
    public var score: Double?

    public init(
        intent: HapticPatternIntent,
        intensity: Double = 0.7,
        sharpness: Double = 0.5,
        heartRateBPM: Double? = nil,
        score: Double? = nil
    ) {
        self.intent = intent
        self.intensity = intensity.isFinite ? max(0, min(1, intensity)) : 0.7
        self.sharpness = sharpness.isFinite ? max(0, min(1, sharpness)) : 0.5
        self.heartRateBPM = heartRateBPM
        self.score = score
    }
}

/// Outcome of a haptic attempt (always non-throwing for actuator bus safety).
public struct HapticRenderResult: Sendable, Equatable {
    public var success: Bool
    public var detail: String
    public var supported: Bool

    public init(success: Bool, detail: String, supported: Bool) {
        self.success = success
        self.detail = detail
        self.supported = supported
    }
}

// MARK: - Engine

/// Production Core Haptics engine for NATURaL.
///
/// - Uses `CHHapticEngine` when CoreHaptics is available and the device supports haptics.
/// - Graceful no-op on tvOS / macOS without engine / simulators without Taptic.
/// - Biometric modulation is **math-based** (HR + SCI score) — no missing `.mlmodelc` stubs.
/// - Does **not** own `UniversalBeatSync`; listen or receive bus commands only.
public actor HapticFeedbackEngine {
    public static let shared = HapticFeedbackEngine()

    private var lastPlay: Date = .distantPast
    /// Minimum gap between transient events (anti-buzz under rapid Crooks ticks).
    public var minimumInterval: TimeInterval = 0.05
    private var playCount: Int = 0
    private var lastDetail: String = "idle"

#if canImport(CoreHaptics)
    private var engine: CHHapticEngine?
    private var engineFailed = false
#endif

    public init() {}

    /// Whether this process can attempt Core Haptics.
    public var isSupported: Bool {
#if canImport(CoreHaptics)
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
#else
        return false
#endif
    }

    public func stats() -> (playCount: Int, lastDetail: String, supported: Bool) {
        (playCount, lastDetail, isSupported)
    }

    // MARK: High-level API

    @discardableResult
    public func playValidation(valid: Bool, intensity: Double = 1.0) async -> HapticRenderResult {
        await play(HapticRenderRequest(
            intent: valid ? .validationPass : .validationFail,
            intensity: intensity,
            sharpness: valid ? 0.75 : 0.35
        ))
    }

    @discardableResult
    public func playBiometricModulated(heartRateBPM: Double, score: Double) async -> HapticRenderResult {
        let hr = heartRateBPM.isFinite ? heartRateBPM : 70
        let sc = score.isFinite ? max(0, min(1, score)) : 0.5
        let intensity = min(1, max(0.2, hr / 180.0))
        return await play(HapticRenderRequest(
            intent: .biometricModulated,
            intensity: intensity,
            sharpness: sc > 0.75 ? 0.7 : 0.4,
            heartRateBPM: hr,
            score: sc
        ))
    }

    @discardableResult
    public func playBeatPulse(bpm: Double, grounding: Bool) async -> HapticRenderResult {
        let intensity = grounding ? 0.45 : 0.65
        let sharpness = grounding ? 0.3 : 0.55
        // Faster BPM → slightly sharper attack (clamped).
        let bpmFactor = bpm.isFinite ? min(1, max(0.4, bpm / 160)) : 0.7
        return await play(HapticRenderRequest(
            intent: grounding ? .grounding : .beatPulse,
            intensity: intensity * bpmFactor,
            sharpness: sharpness
        ))
    }

    @discardableResult
    public func play(_ request: HapticRenderRequest) async -> HapticRenderResult {
#if canImport(CoreHaptics)
        guard isSupported else {
            lastDetail = "unsupported"
            return HapticRenderResult(success: true, detail: "haptics unsupported — no-op", supported: false)
        }

        let now = Date()
        if now.timeIntervalSince(lastPlay) < minimumInterval {
            lastDetail = "debounced"
            return HapticRenderResult(success: true, detail: "debounced", supported: true)
        }

        do {
            try ensureEngine()
            guard let engine else {
                lastDetail = "no engine"
                return HapticRenderResult(success: true, detail: "no engine — no-op", supported: true)
            }

            let events = makeEvents(for: request)
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
            lastPlay = now
            playCount += 1
            lastDetail = "\(request.intent.rawValue) i=\(String(format: "%.2f", request.intensity))"
            return HapticRenderResult(success: true, detail: lastDetail, supported: true)
        } catch {
            lastDetail = "error \(error.localizedDescription)"
            // Soft-fail: bus must not throw.
            return HapticRenderResult(success: true, detail: lastDetail, supported: true)
        }
#else
        lastDetail = "corehaptics unavailable"
        return HapticRenderResult(success: true, detail: lastDetail, supported: false)
#endif
    }

    public func reset() {
        playCount = 0
        lastDetail = "idle"
        lastPlay = .distantPast
#if canImport(CoreHaptics)
        engine?.stop(completionHandler: nil)
        engine = nil
        engineFailed = false
#endif
    }

    // MARK: CoreHaptics

#if canImport(CoreHaptics)
    private func ensureEngine() throws {
        if engineFailed { return }
        if engine != nil { return }
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        let eng = try CHHapticEngine()
        eng.isAutoShutdownEnabled = true
        eng.resetHandler = { [weak self] in
            Task { await self?.handleEngineReset() }
        }
        eng.stoppedHandler = { [weak self] _ in
            Task { await self?.handleEngineStopped() }
        }
        try eng.start()
        engine = eng
    }

    private func handleEngineReset() {
        engine = nil
        engineFailed = false
    }

    private func handleEngineStopped() {
        engine = nil
    }

    private func makeEvents(for request: HapticRenderRequest) -> [CHHapticEvent] {
        let intensity = Float(request.intensity)
        let sharpness = Float(request.sharpness)

        switch request.intent {
        case .beatPulse, .biometricModulated:
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                    ],
                    relativeTime: 0
                )
            ]
        case .grounding:
            // Soft double pulse — inhale / settle feel.
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.7),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.35),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                    ],
                    relativeTime: 0.05,
                    duration: 0.12
                )
            ]
        case .validationPass:
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                    ],
                    relativeTime: 0
                ),
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.6),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                    ],
                    relativeTime: 0.08
                )
            ]
        case .validationFail:
            return [
                CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.8),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                    ],
                    relativeTime: 0,
                    duration: 0.15
                )
            ]
        case .phaseFlip:
            return [
                CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * 0.9),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                    ],
                    relativeTime: 0
                )
            ]
        }
    }
#endif
}

// MARK: - Actuator channel

/// Haptic side-effects for Crooks commands. Never calls `UniversalBeatSync.broadcast`.
public struct HapticActuatorChannel: ActuatorChannel {
    public let id = "haptic_feedback"
    private let engine: HapticFeedbackEngine

    public init(engine: HapticFeedbackEngine = .shared) {
        self.engine = engine
    }

    public func execute(_ command: ActuatorCommand) async -> ActuatorChannelResult {
        switch command {
        case .grounding(_, let bpm, _):
            let r = await engine.playBeatPulse(bpm: CrooksCycleDefaults.groundingBPM, grounding: true)
            return ActuatorChannelResult(
                channelId: id, command: command, success: r.success,
                detail: "haptic ground from \(bpm): \(r.detail)"
            )
        case .beatBroadcast(let bpm, _, let grounding):
            let r = await engine.playBeatPulse(bpm: bpm, grounding: grounding)
            return ActuatorChannelResult(
                channelId: id, command: command, success: r.success,
                detail: "haptic beat: \(r.detail)"
            )
        case .phaseFlip:
            let r = await engine.play(HapticRenderRequest(intent: .phaseFlip, intensity: 0.7, sharpness: 0.85))
            return ActuatorChannelResult(
                channelId: id, command: command, success: r.success,
                detail: "haptic phase: \(r.detail)"
            )
        case .microSurveyLog:
            return ActuatorChannelResult(channelId: id, command: command, success: true, detail: "idle")
        }
    }
}
