import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

// MARK: - Feature Vector

/// Four-channel control feature vector for Crooks-inspired work scoring.
///
/// Instantaneous “work” is a weighted feature score for session control — not
/// thermodynamic path work from a verified Crooks FT trajectory ensemble.
///
/// Components (weights sum to 1.0):
/// | Channel | Weight |
/// |---|---|
/// | ΔH_hrv (physiological entropy delta) | 0.42 |
/// | FlexAID ΔS_config (molecular) | 0.31 |
/// | Crown β dial | 0.18 |
/// | BPM deviation from nominal | 0.09 |
public struct CrooksFeatureVector: Sendable, Equatable {
    public var deltaHRV: Double
    public var flexAIDDeltaS: Double
    public var crownBeta: Double
    public var bpm: Double

    public init(deltaHRV: Double, flexAIDDeltaS: Double, crownBeta: Double, bpm: Double) {
        // Non-finite sensor values → 0 so work/σ_irr never poison the control loop.
        self.deltaHRV = deltaHRV.isFinite ? deltaHRV : 0
        self.flexAIDDeltaS = flexAIDDeltaS.isFinite ? flexAIDDeltaS : 0
        self.crownBeta = crownBeta.isFinite ? max(-1, min(1, crownBeta)) : 0
        self.bpm = bpm.isFinite ? bpm : CrooksCycleDefaults.nominalBPM
    }

    /// Feature components as a 4-vector for eigen / Accelerate projection.
    public var components: [Double] {
        [
            deltaHRV,
            flexAIDDeltaS,
            crownBeta,
            bpm - CrooksCycleDefaults.nominalBPM
        ]
    }
}

// MARK: - Work Result

/// Result of EigenMetal work evaluation.
public struct EigenMetalWorkResult: Sendable, Equatable {
    /// Instantaneous control “work” score (feature-weighted; not FT path work).
    public let work: Double
    /// Projected coefficients in the eigen control basis.
    public let eigenCoords: [Double]
    /// Backend used for the dot product / projection.
    public let backendLabel: String
    /// Whether the Accelerate (ANE-class) path was used.
    public let usedANEPath: Bool
}

// MARK: - EigenMetal Work Kernel

/// Work kernel: orthonormal eigen-basis projection + on-device linear map.
///
/// Produces the per-tick control work score consumed by `CrooksCycleController`.
/// This is an engineering map (weights + residual soft-threshold), not a
/// fluctuation-theorem estimator of non-equilibrium path work.
///
/// **EigenMetal** — fixed control basis (Gram–Schmidt with e₀ ∥ production weights)
/// evaluated via Accelerate `vDSP` when available, else pure Swift.
///
/// **ANE-class** — Accelerate linear + soft-threshold residual on higher modes
/// (noise rejection for the heuristic work score). Always executes a real map —
/// no placeholder path.
///
/// Work-history entropy reuses `EntropyCalculator` (Metal/SIMD under `BONHOMME_ACCEL`).
public struct EigenMetalWorkKernel: Sendable {

    /// [ΔHRV, FlexAID ΔS, crown β, BPM-dev]. Sum = 1.0.
    public static let productionWeights: [Double] = [0.42, 0.31, 0.18, 0.09]

    /// Orthonormal eigen-basis (rows) spanning ℝ⁴ with e₀ ∥ weight axis.
    public static let eigenBasis: [[Double]] = buildEigenBasis(weights: productionWeights)

    /// Soft-threshold λ for residual eigen modes (noise rejection).
    private static let residualLambda: Double = 0.05

    /// Scale on soft-thresholded residual modes.
    private static let residualScale: Double = 0.08

    public init() {}

    /// True when the Accelerate vDSP path is compiled in (Apple platforms).
    public static var accelerateAvailable: Bool {
        #if canImport(Accelerate)
        true
        #else
        false
        #endif
    }

    // MARK: - Public API

    public func evaluate(_ features: CrooksFeatureVector) -> EigenMetalWorkResult {
        let x = features.components
        let coords = projectOntoEigenBasis(x)
        let raw = aneLinearMap(features: x, eigenCoords: coords)
        let work = clamp(raw, maxAbs: CrooksCycleDefaults.maxAbsWorkPerTick)
        // usedANEPath is true only when vDSP actually backs `dot` (compile-time path).
        let usedANE = Self.accelerateAvailable
        let label = usedANE ? "Accelerate/ANE+Eigen" : "Scalar/Eigen"

        return EigenMetalWorkResult(
            work: work.isFinite ? work : 0,
            eigenCoords: coords.map { $0.isFinite ? $0 : 0 },
            backendLabel: label,
            usedANEPath: usedANE
        )
    }

    public func evaluateBatch(_ batch: [CrooksFeatureVector]) -> [Double] {
        guard !batch.isEmpty else { return [] }
        // Small fixed feature dim (4); map is optimal. Large-N entropy uses EntropyCalculator/Metal.
        return batch.map { evaluate($0).work }
    }

    /// Shannon entropy of a work history (`EntropyCalculator` / Metal when linked).
    public func workHistoryEntropy(_ works: [Double], binCount: Int = 32) -> Double {
        let finite = works.filter(\.isFinite)
        return EntropyCalculator(binCount: binCount).shannonEntropy(finite)
    }

    // MARK: - Eigen projection

    public func projectOntoEigenBasis(_ x: [Double]) -> [Double] {
        precondition(x.count == 4)
        var coords = [Double](repeating: 0, count: 4)
        for i in 0..<4 {
            coords[i] = dot(x, Self.eigenBasis[i])
        }
        return coords
    }

    // MARK: - ANE-class linear map

    /// w·x + soft residual on eigen modes 1…3.
    private func aneLinearMap(features x: [Double], eigenCoords: [Double]) -> Double {
        let primary = dot(x, Self.productionWeights)
        var residual = 0.0
        for i in 1..<4 {
            residual += softThreshold(eigenCoords[i], lambda: Self.residualLambda) * Self.residualScale
        }
        return primary + residual
    }

    // MARK: - Linear algebra

    private func softThreshold(_ v: Double, lambda: Double) -> Double {
        guard v.isFinite else { return 0 }
        if v > lambda { return v - lambda }
        if v < -lambda { return v + lambda }
        return 0
    }

    private func clamp(_ v: Double, maxAbs: Double) -> Double {
        guard v.isFinite else { return 0 }
        return max(-maxAbs, min(maxAbs, v))
    }

    /// Dot product via Accelerate `vDSP_dotprD` when available; scalar otherwise.
    private func dot(_ a: [Double], _ b: [Double]) -> Double {
        precondition(a.count == b.count)
        #if canImport(Accelerate)
        var result = 0.0
        vDSP_dotprD(a, 1, b, 1, &result, vDSP_Length(a.count))
        return result.isFinite ? result : 0
        #else
        var s = 0.0
        for i in 0..<a.count { s += a[i] * b[i] }
        return s.isFinite ? s : 0
        #endif
    }

    // MARK: - Basis construction

    /// Gram–Schmidt with first vector = normalized weights.
    private static func buildEigenBasis(weights: [Double]) -> [[Double]] {
        let n = weights.count
        var basis: [[Double]] = [normalize(weights)]

        let seeds: [[Double]] = [
            [1, 0, 0, 0],
            [0, 1, 0, 0],
            [0, 0, 1, 0],
            [0, 0, 0, 1]
        ]

        for seed in seeds {
            var v = seed
            for e in basis {
                let proj = zip(v, e).map(*).reduce(0, +)
                for i in 0..<n { v[i] -= proj * e[i] }
            }
            let norm = sqrt(v.map { $0 * $0 }.reduce(0, +))
            guard norm > 1e-12 else { continue }
            basis.append(normalize(v))
            if basis.count == n { break }
        }

        while basis.count < n {
            basis.append([Double](repeating: 0, count: n))
        }
        return basis
    }

    private static func normalize(_ v: [Double]) -> [Double] {
        let n = sqrt(v.map { $0 * $0 }.reduce(0, +))
        guard n > 0 else { return v }
        return v.map { $0 / n }
    }
}
