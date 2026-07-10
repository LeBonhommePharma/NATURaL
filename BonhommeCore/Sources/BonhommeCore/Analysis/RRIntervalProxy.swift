import Foundation

// MARK: - RR source

/// Provenance of RR intervals fed into SCI / adaptive music.
///
/// **Important:** BPM → RR (`60000 / bpm`) is a **proxy**, not clinical beat-to-beat HRV.
/// Prefer `real` series (heartbeat series / ECG-derived) whenever HealthKit provides them.
public enum RRIntervalSource: String, Sendable, Codable, Equatable {
    /// True beat-to-beat intervals from HealthKit heartbeat series or ECG.
    case real
    /// Derived from successive HR samples (BPM→ms) with light physiological jitter.
    case synthetic
}

// MARK: - Proxy helpers

/// Shared BPM↔RR helpers for live session SCI paths (iOS `WorkoutRecorder`, Watch manager).
///
/// ## Why synthetic needs jitter
/// Live HR often arrives as a near-constant `mostRecentQuantity` BPM. Mapping that 1:1 to RR
/// yields a zero-variance series → Shannon entropy 0 → SCI stuck at 1.0 → adaptive music
/// and Crooks ticks become meaningless. Light SDNN-scale jitter (~5% of mean RR) keeps the
/// proxy usable without claiming clinical fidelity.
public enum RRIntervalProxy: Sendable {

    /// SDNN ≈ 4–6% of mean RR at rest (Kleiger et al., 1987).
    public static let syntheticJitterFraction: Double = 0.05

    /// Relative SD below this fraction of mean RR is treated as meaningless for SCI/music.
    public static let meaninglessRelativeSD: Double = 0.001

    /// Convert a window of BPM samples to RR intervals (ms) with deterministic light jitter.
    ///
    /// - Note: This is **not** true HRV. Call sites should prefer real RR and set
    ///   `RRIntervalSource.synthetic` on the ingest path.
    public static func syntheticRR(fromBPMSamples bpms: [Double]) -> [Double] {
        guard !bpms.isEmpty else { return [] }
        var out: [Double] = []
        out.reserveCapacity(bpms.count)
        for (j, bpm) in bpms.enumerated() {
            let safeBPM = max(bpm, 1)
            let meanRR = 60000.0 / safeBPM
            // Deterministic alternate spread (no RNG) so tests stay stable.
            let sdnn = meanRR * syntheticJitterFraction
            let sign: Double = j % 2 == 0 ? 1.0 : -1.0
            let amplitude = Double(j % 5 + 1) / 5.0
            let jitter = sdnn * sign * amplitude
            out.append(meanRR + jitter)
        }
        return out
    }

    /// Pure 60000/bpm conversion with **no** jitter (for diagnostics / variance checks).
    public static func rawProxyRR(fromBPMSamples bpms: [Double]) -> [Double] {
        bpms.map { 60000.0 / max($0, 1) }
    }

    /// `true` when the series has negligible variance and must not drive adaptive music / SCI policy.
    public static func isMeaninglessForSCI(_ rr: [Double]) -> Bool {
        guard rr.count >= 4 else { return true }
        let mean = rr.reduce(0, +) / Double(rr.count)
        guard mean > 1e-9, mean.isFinite else { return true }
        let variance = rr.reduce(0.0) { acc, v in
            let d = v - mean
            return acc + d * d
        } / Double(rr.count - 1)
        let sd = sqrt(max(0, variance))
        return sd / mean < meaninglessRelativeSD
    }

    /// Sample SD of RR (ms).
    public static func standardDeviation(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }
        let mean = values.reduce(0, +) / Double(values.count)
        let squaredDiffs = values.map { ($0 - mean) * ($0 - mean) }
        return sqrt(squaredDiffs.reduce(0, +) / Double(values.count - 1))
    }

    /// RMSSD of RR series (ms).
    public static func rmssd(_ intervals: [Double]) -> Double {
        guard intervals.count >= 2 else { return 0 }
        var sumSquaredDiff = 0.0
        for i in 1..<intervals.count {
            let diff = intervals[i] - intervals[i - 1]
            sumSquaredDiff += diff * diff
        }
        return sqrt(sumSquaredDiff / Double(intervals.count - 1))
    }
}
