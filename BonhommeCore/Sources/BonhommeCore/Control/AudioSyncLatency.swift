import Foundation

// MARK: - Latency model

/// Measured or estimated one-way audio path latency for a fleet device.
public struct DeviceLatencySample: Sendable, Equatable {
    public var deviceId: String
    /// One-way path latency in milliseconds (hardware + buffer + transport).
    public var latencyMs: Double
    public var measuredAt: Date

    public init(deviceId: String, latencyMs: Double, measuredAt: Date = Date()) {
        self.deviceId = deviceId
        self.latencyMs = latencyMs.isFinite ? max(0, latencyMs) : 0
        self.measuredAt = measuredAt
    }
}

/// Per-device delay compensation (milliseconds to **delay** a low-latency path so
/// it aligns with the slowest device in the fleet).
public struct LatencyCompensationPlan: Sendable, Equatable {
    /// deviceId → delay to apply (ms), always ≥ 0.
    public var delayMsByDevice: [String: Double]
    /// Slowest observed path (ms) — reference horizon for alignment.
    public var referenceLatencyMs: Double
    /// Mean residual after compensation (should be near 0 when plan is applied).
    public var residualMs: Double
    /// Effective σ_irr scaling used when shrinking aggressive delays under high irreversibility.
    public var sigmaScale: Double

    public init(
        delayMsByDevice: [String: Double] = [:],
        referenceLatencyMs: Double = 0,
        residualMs: Double = 0,
        sigmaScale: Double = 1
    ) {
        self.delayMsByDevice = delayMsByDevice
        self.referenceLatencyMs = referenceLatencyMs
        self.residualMs = residualMs
        self.sigmaScale = sigmaScale
    }
}

// MARK: - Optimizer

/// Pure-math multi-device audio delay compensation (no I/O).
///
/// Aligns each path to the slowest device: `delay_i = max(0, L_max - L_i)`.
/// Under elevated σ_irr, delays are scaled down (`1 - 0.5·σ`) so grounding
/// recovery does not stack long artificial buffers on top of control stress.
///
/// Matches the intent of the former stub `optimizeAudioSync` kernel without
/// inventing AVX-512 for a handful of latencies — O(n) is correct and
/// bulletproof for fleet sizes (≤ 16 devices).
public enum AudioSyncLatencyOptimizer: Sendable {
    /// Cap artificial delay so we never invent multi-second buffers.
    public static let maxCompensationMs: Double = 250

    /// Compute a compensation plan from measured latencies and Crooks σ_irr.
    public static func optimize(
        latencies: [DeviceLatencySample],
        sigmaIrr: Double = 0
    ) -> LatencyCompensationPlan {
        guard !latencies.isEmpty else {
            return LatencyCompensationPlan()
        }

        let sigma = sigmaIrr.isFinite ? max(0, min(1, sigmaIrr)) : 0
        // High irreversibility → reduce added delay (prefer snappy recovery).
        let sigmaScale = max(0.25, 1.0 - sigma * 0.5)

        var maxL = 0.0
        for sample in latencies {
            if sample.latencyMs > maxL { maxL = sample.latencyMs }
        }

        var delays: [String: Double] = [:]
        delays.reserveCapacity(latencies.count)
        var residualSum = 0.0

        for sample in latencies {
            let raw = max(0, maxL - sample.latencyMs)
            let delayed = min(Self.maxCompensationMs, raw * sigmaScale)
            delays[sample.deviceId] = delayed
            // After delay, effective path ≈ sample + delay; residual vs maxL.
            residualSum += abs((sample.latencyMs + delayed) - maxL)
        }

        let residual = residualSum / Double(latencies.count)
        return LatencyCompensationPlan(
            delayMsByDevice: delays,
            referenceLatencyMs: maxL,
            residualMs: residual,
            sigmaScale: sigmaScale
        )
    }

    /// Preferred host buffer duration (seconds) for a target one-way budget.
    ///
    /// Example: `preferredIOBufferDuration(forTargetLatencyMs: 10)` → ~0.005 s
    /// (half-round-trip heuristic when only output buffering is controllable).
    public static func preferredIOBufferDuration(forTargetLatencyMs targetMs: Double) -> TimeInterval {
        let ms = targetMs.isFinite ? max(2, min(50, targetMs)) : 10
        // Output buffer ≈ half of one-way path when render + DAC share the budget.
        return (ms * 0.5) / 1000.0
    }

    /// Convert frames-per-slice + sample rate → milliseconds of buffer latency.
    public static func bufferLatencyMs(frames: Int, sampleRate: Double) -> Double {
        guard frames > 0, sampleRate > 0, sampleRate.isFinite else { return 0 }
        return (Double(frames) / sampleRate) * 1000.0
    }
}
