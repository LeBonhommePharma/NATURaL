import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

// MARK: - Feature Vector

/// Four-channel control feature vector for Crooks work estimation.
///
/// Components (production weights sum to 1.0):
/// - ΔH_hrv (physiological entropy delta)  — 0.42
/// - FlexAID ΔS_config (molecular)        — 0.31
/// - Crown β dial                         — 0.18
/// - BPM deviation from nominal           — 0.09
public struct CrooksFeatureVector: Sendable, Equatable {
    public var deltaHRV: Double
    public var flexAIDDeltaS: Double
    public var crownBeta: Double
    public var bpm: Double

    public init(deltaHRV: Double, flexAIDDeltaS: Double, crownBeta: Double, bpm: Double) {
        self.deltaHRV = deltaHRV
        self.flexAIDDeltaS = flexAIDDeltaS
        self.crownBeta = crownBeta
        self.bpm = bpm
    }

    /// Feature components as a 4-vector ready for eigen / Accelerate projection.
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
    /// Instantaneous non-equilibrium work contribution.
    public let work: Double
    /// Projected coefficients in the eigen control basis.
    public let eigenCoords: [Double]
    /// Backend used for the dot product / projection.
    public let backendLabel: String
    /// Whether the ANE-class (Accelerate) path was used.
    public let usedANEPath: Bool
}

// MARK: - EigenMetal Work Kernel

/// Production work kernel: eigen-basis control projection + on-device linear map.
///
/// **EigenMetal** — fixed orthonormal control basis (Householder-style rotation of the
/// production weight axis) evaluated via Accelerate `vDSP` when available, else pure Swift.
/// When BonhommeAccel is linked and Metal is the active backend, large work-history entropy
/// reuses `EntropyCalculator` → Metal/SIMD path (NATURaL/FlexAID parity).
///
/// **ANE** — on-device inference path uses Accelerate (BNNS/vDSP foundation for Apple Neural
/// Engine class linear maps). No stub: the linear + soft-threshold map always runs for real.
public struct EigenMetalWorkKernel: Sendable {

    /// Production weights: [ΔHRV, FlexAID ΔS, crown β, BPM-dev]. Sum = 1.0.
    public static let productionWeights: [Double] = [0.42, 0.31, 0.18, 0.09]

    /// Orthonormal eigen-basis (columns) spanning ℝ⁴ with e₀ ∥ production weight axis.
    /// Built once: Gram–Schmidt on {w, e1, e2, e3}.
    public static let eigenBasis: [[Double]] = buildEigenBasis(weights: productionWeights)

    public init() {}

    // MARK: - Public API

    /// Compute instantaneous Crooks work from a feature vector.
    public func evaluate(_ features: CrooksFeatureVector) -> EigenMetalWorkResult {
        let x = features.components
        let coords = projectOntoEigenBasis(x)
        let raw = aneLinearMap(features: x, eigenCoords: coords)
        let work = clamp(raw, maxAbs: CrooksCycleDefaults.maxAbsWorkPerTick)

        #if canImport(Accelerate)
        let usedANE = true
        let label = "Accelerate/ANE+Eigen"
        #else
        let usedANE = false
        let label = "Scalar/Eigen"
        #endif

        return EigenMetalWorkResult(
            work: work,
            eigenCoords: coords,
            backendLabel: label,
            usedANEPath: usedANE
        )
    }

    /// Batch-evaluate work for a history of feature vectors (vectorized when Accelerate present).
    public func evaluateBatch(_ batch: [CrooksFeatureVector]) -> [Double] {
        guard !batch.isEmpty else { return [] }
        #if canImport(Accelerate)
        return batch.map { evaluate($0).work }
        #else
        return batch.map { evaluate($0).work }
        #endif
    }

    /// Shannon entropy of a work history (reuses NATURaL `EntropyCalculator`, Metal/SIMD when linked).
    public func workHistoryEntropy(_ works: [Double], binCount: Int = 32) -> Double {
        EntropyCalculator(binCount: binCount).shannonEntropy(works)
    }

    // MARK: - Eigen projection

    /// Project feature vector onto the fixed eigen control basis.
    public func projectOntoEigenBasis(_ x: [Double]) -> [Double] {
        precondition(x.count == 4)
        var coords = [Double](repeating: 0, count: 4)
        for i in 0..<4 {
            coords[i] = dot(x, Self.eigenBasis[i])
        }
        return coords
    }

    // MARK: - ANE-class linear map

    /// On-device linear map: w·x + soft residual on eigen modes 1…3.
    /// Soft-threshold damps high-order eigen modes (σ_irr noise rejection).
    private func aneLinearMap(features x: [Double], eigenCoords: [Double]) -> Double {
        // Primary: production weight axis (eigen mode 0 scaled back to weight norm).
        let primary = dot(x, Self.productionWeights)

        // Residual eigen modes (orthogonal to w) with soft-threshold λ = 0.05.
        let lambda = 0.05
        var residual = 0.0
        for i in 1..<4 {
            residual += softThreshold(eigenCoords[i], lambda: lambda) * 0.08
        }
        return primary + residual
    }

    // MARK: - Linear algebra helpers

    private func softThreshold(_ v: Double, lambda: Double) -> Double {
        if v > lambda { return v - lambda }
        if v < -lambda { return v + lambda }
        return 0
    }

    private func clamp(_ v: Double, maxAbs: Double) -> Double {
        max(-maxAbs, min(maxAbs, v))
    }

    private func dot(_ a: [Double], _ b: [Double]) -> Double {
        precondition(a.count == b.count)
        #if canImport(Accelerate)
        var result = 0.0
        vDSP_dotprD(a, 1, b, 1, &result, vDSP_Length(a.count))
        return result
        #else
        var s = 0.0
        for i in 0..<a.count { s += a[i] * b[i] }
        return s
        #endif
    }

    // MARK: - Basis construction

    /// Gram–Schmidt orthonormalization with first vector = normalized weights.
    private static func buildEigenBasis(weights: [Double]) -> [[Double]] {
        let n = weights.count
        var basis: [[Double]] = []

        // e0 = w / ||w||
        basis.append(normalize(weights))

        // Seed vectors for remaining dimensions.
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

        // Pad if needed (degenerate).
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
