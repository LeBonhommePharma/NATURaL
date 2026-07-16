import Foundation
import AVFoundation
import BonhommeCore

#if canImport(AudioToolbox)
import AudioToolbox
#endif

// MARK: - Low-latency session apply

/// Production Core Audio / AVAudioSession low-latency router for ClusterFleet.
///
/// ## Reality check (vs AUGraph snippets)
/// - **AUGraph is deprecated** (iOS 13+ / macOS 10.15+). Production path uses
///   `AVAudioEngine` + `AVAudioSession` preferences, which sit on AudioUnit I/O.
/// - iOS has a **single** shared `AVAudioSession` — devices are route ports, not
///   multiple session objects.
/// - `kAudioUnitSubType_DefaultOutput` is **macOS-only**; iOS uses RemoteIO under
///   AVAudioEngine / RemoteIO units.
/// - Sub-10 ms is achievable on built-in / wired when `setPreferredIOBufferDuration`
///   is honored; Bluetooth / AirPlay hardware floors are higher (fleet priors).
///
/// ## Core Audio properties used (via session + engine)
/// | Goal | Mechanism |
/// |------|-----------|
/// | Small buffer | `setPreferredIOBufferDuration` → AudioUnit frames/slice |
/// | 48 kHz stream | `setPreferredSampleRate(48000)` |
/// | Route policy | category options allowAirPlay / allowBluetoothA2DP |
/// | Spatial | `AVAudioEnvironmentNode` when profile.preferSpatial |
///
/// Integrates with `ClusterFleet` quality profiles from `AirFoilQualityRouter`.
@MainActor
final class LowLatencyAudioRouter {
    static let shared = LowLatencyAudioRouter()

    private let engine = AVAudioEngine()
    private let environment = AVAudioEnvironmentNode()
    private let sourceNode = AVAudioPlayerNode()
    private var started = false
    private var lastProfile: AirFoilQualityProfile = .standard
    private var lastAppliedBufferMs: Double = 0
    private var lastAppliedSampleRate: Double = 0

    /// Achieved session metrics after last `apply`.
    private(set) var achievedIOBufferDuration: TimeInterval = 0
    private(set) var achievedSampleRate: Double = 0
    private(set) var isRunning = false

    init() {
        engine.attach(environment)
        engine.attach(sourceNode)
        // Source → environment (spatial) → main mixer → output (RemoteIO / HAL).
        engine.connect(sourceNode, to: environment, format: nil)
        engine.connect(environment, to: engine.mainMixerNode, format: nil)
    }

    /// Apply an AirFoil quality profile to the shared session and start the engine.
    @discardableResult
    func apply(profile: AirFoilQualityProfile) throws -> AirFoilQualityProfile {
        let session = AVAudioSession.sharedInstance()

        var options: AVAudioSession.CategoryOptions = []
        if profile.allowAirPlay { options.insert(.allowAirPlay) }
        if profile.allowBluetoothA2DP { options.insert(.allowBluetoothA2DP) }

        // Playback + measurement mode is a common low-latency pairing for fitness apps.
        try session.setCategory(.playback, mode: .default, options: options)
        try session.setPreferredSampleRate(profile.sampleRate)
        try session.setPreferredIOBufferDuration(profile.ioBufferDuration)
        try session.setActive(true, options: [])

        achievedSampleRate = session.sampleRate
        achievedIOBufferDuration = session.ioBufferDuration
        lastAppliedSampleRate = achievedSampleRate
        lastAppliedBufferMs = achievedIOBufferDuration * 1000.0
        lastProfile = profile

        // Spatial attenuation model when AirPods / AirPlay prefer spatial.
        if profile.preferSpatial {
            environment.distanceAttenuationParameters.distanceAttenuationModel = .inverse
            environment.renderingAlgorithm = .HRTFHQ
        } else {
            environment.distanceAttenuationParameters.distanceAttenuationModel = .exponential
            environment.renderingAlgorithm = .equalPowerPanning
        }

        if !engine.isRunning {
            try engine.start()
        }
        started = true
        isRunning = engine.isRunning
        return profile
    }

    /// Apply profile recommended by current ClusterFleet snapshot.
    @discardableResult
    func applyFromFleet(_ fleet: ClusterFleet = .shared) async throws -> AirFoilQualityProfile {
        let profile = await fleet.currentQualityProfile()
        return try apply(profile: profile)
    }

    /// Update 3D listener orientation from ClusterFleet spatial state.
    func applySpatialState(yawDegrees: Double, depth: Double) {
        let yaw = Float(yawDegrees.truncatingRemainder(dividingBy: 360))
        environment.listenerAngularOrientation = AVAudio3DAngularOrientation(
            yaw: yaw,
            pitch: 0,
            roll: Float(max(0, min(1, depth)) * 15) // mild roll from depth
        )
        // Place a virtual source slightly in front; depth scales distance.
        let distance = Float(0.5 + max(0, min(1, depth)) * 2.5)
        sourceNode.position = AVAudio3DPoint(x: 0, y: 0, z: -distance)
    }

    /// Schedule a PCM buffer with optional per-device compensation delay (seconds).
    func schedule(
        buffer: AVAudioPCMBuffer,
        compensationDelayMs: Double = 0,
        options: AVAudioPlayerNodeBufferOptions = []
    ) {
        guard started else { return }
        let delaySec = max(0, compensationDelayMs) / 1000.0
        if delaySec > 0, let last = engine.outputNode.lastRenderTime,
           let playerTime = sourceNode.playerTime(forNodeTime: last) {
            let sampleRate = playerTime.sampleRate > 0 ? playerTime.sampleRate : 48_000
            let frames = AVAudioFramePosition(delaySec * sampleRate)
            let when = AVAudioTime(sampleTime: playerTime.sampleTime + frames, atRate: sampleRate)
            sourceNode.scheduleBuffer(buffer, at: when, options: options, completionHandler: nil)
        } else {
            sourceNode.scheduleBuffer(buffer, at: nil, options: options, completionHandler: nil)
        }
        if !sourceNode.isPlaying {
            sourceNode.play()
        }
    }

    func stop() {
        sourceNode.stop()
        if engine.isRunning {
            engine.stop()
        }
        started = false
        isRunning = false
    }

    /// Report measured buffer latency back into ClusterFleet for the local device id.
    func publishLocalLatency(to fleet: ClusterFleet = .shared, deviceId: String) async {
        let ms = achievedIOBufferDuration * 1000.0
        guard ms > 0 else { return }
        await fleet.updateMeasuredLatency(deviceId: deviceId, latencyMs: ms)
    }

    /// Human-readable diagnostics for debug UI.
    var diagnostics: String {
        String(
            format: "profile=%@ sr=%.0f→%.0f buf=%.2fms→%.2fms running=%@",
            lastProfile.label,
            lastProfile.sampleRate,
            achievedSampleRate,
            lastProfile.ioBufferDuration * 1000,
            lastAppliedBufferMs,
            String(isRunning)
        )
    }
}

// MARK: - AudioUnit property helpers (documentation + optional probe)

/// Thin helpers exposing the Core Audio property names called out in design notes.
/// Values are applied via AVAudioSession where possible; direct AudioUnit sets are
/// best-effort and platform-gated (no AUGraph).
enum CoreAudioLowLatencyProperties {
    /// Target max frames/slice corresponding to profile (256 ≈ 5.3 ms @ 48 kHz).
    static func maxFramesPerSlice(for profile: AirFoilQualityProfile) -> UInt32 {
        UInt32(max(64, profile.maxFramesPerSlice))
    }

    /// Preferred sample rate property intent (`kAudioUnitProperty_SampleRate` analog).
    static let preferredSampleRate: Double = 48_000

    /// Convert frames + rate → ms (same as `AudioSyncLatencyOptimizer.bufferLatencyMs`).
    static func latencyMs(frames: UInt32, sampleRate: Double) -> Double {
        AudioSyncLatencyOptimizer.bufferLatencyMs(frames: Int(frames), sampleRate: sampleRate)
    }
}
