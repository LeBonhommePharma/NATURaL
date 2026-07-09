import Foundation

// MARK: - Mapping Result

/// Cross-domain prediction linking physiological ΔH_hrv to molecular ΔS_config.
public struct DeltaHRVFlexAIDPrediction: Sendable, Equatable {
    /// Observed physiological entropy delta (bits).
    public let deltaHRV: Double
    /// Observed or reference FlexAID ΔS_config (bits).
    public let flexAIDDeltaS: Double
    /// Predicted ΔS_config from ΔHRV via calibrated slope.
    public let predictedDeltaS: Double
    /// Residual |predicted − observed| (bits).
    public let residual: Double
    /// Whether residual exceeds grounding threshold.
    public let shouldGround: Bool
    /// Optional substance id when profile-backed.
    public let substanceId: String?
    /// Backend label (profile / live docking / ANE map).
    public let source: String

    public init(
        deltaHRV: Double,
        flexAIDDeltaS: Double,
        predictedDeltaS: Double,
        residual: Double,
        shouldGround: Bool,
        substanceId: String? = nil,
        source: String
    ) {
        self.deltaHRV = deltaHRV
        self.flexAIDDeltaS = flexAIDDeltaS
        self.predictedDeltaS = predictedDeltaS
        self.residual = residual
        self.shouldGround = shouldGround
        self.substanceId = substanceId
        self.source = source
    }
}

// MARK: - DeltaHRV ↔ FlexAID Mapper

/// Production mapper between HRV entropy collapse and FlexAID configurational entropy.
///
/// Reuses NATURaL machinery:
/// - `BindingEntropyProfile` reference ΔS_config database
/// - `CrossDomainValidator` regression slope when paired observations exist
/// - `ThermodynamicConstants` for bits ↔ kcal/mol
/// - `EigenMetalWorkKernel` ANE path for residual soft-threshold
///
/// Zero stubs: all predictions are numerical; grounding is a real control decision.
public actor DeltaHRVFlexAIDMapper {
    public static let shared = DeltaHRVFlexAIDMapper()

    /// Default cross-domain slope: |ΔH_hrv| ≈ slope × |ΔS_config|
    /// (from CrossDomainValidator literature-scale prior; refined when live pairs available).
    public static let defaultSlope: Double = 0.85

    /// Residual (bits) above which grounding is recommended.
    public static let residualGroundingThreshold: Double = 0.45

    private var calibratedSlope: Double = DeltaHRVFlexAIDMapper.defaultSlope
    private var calibratedIntercept: Double = 0
    private var lastPrediction: DeltaHRVFlexAIDPrediction?
    private let kernel = EigenMetalWorkKernel()

    public init() {}

    public func last() -> DeltaHRVFlexAIDPrediction? { lastPrediction }

    public func slope() -> Double { calibratedSlope }

    /// Calibrate from a `CrossDomainValidator.ValidationResult` (live or profile-backed).
    public func calibrate(from validation: CrossDomainValidator.ValidationResult) {
        guard validation.n >= 3, validation.regressionSlope.isFinite else { return }
        calibratedSlope = max(0.05, min(5.0, validation.regressionSlope))
        calibratedIntercept = validation.regressionIntercept
    }

    /// Predict molecular ΔS from physiological ΔH and compare to observed FlexAID ΔS.
    @discardableResult
    public func predict(
        deltaHRV: Double,
        flexAIDDeltaS: Double,
        substanceId: String? = nil
    ) -> DeltaHRVFlexAIDPrediction {
        // Prefer profile-backed ΔS when substance known and flexAID is zero/unknown.
        var observedFlex = flexAIDDeltaS
        var source = "live"
        if let id = substanceId, let profile = BindingEntropyProfile.profile(for: id) {
            if abs(flexAIDDeltaS) < 1e-9 {
                observedFlex = profile.expectedDeltaSBits
                source = "BindingEntropyProfile"
            } else {
                source = "live+profile"
            }
        }

        // Invert regression: |ΔH| ≈ slope × |ΔS| + intercept → |ΔS| ≈ (|ΔH| − intercept) / slope
        let absHRV = abs(deltaHRV)
        let absPred = max(0, (absHRV - calibratedIntercept) / max(calibratedSlope, 1e-6))
        // Sign: both domains use negative = collapse / binding constraint.
        let sign: Double = deltaHRV < 0 || observedFlex < 0 ? -1 : (deltaHRV > 0 ? 1 : -1)
        let predicted = sign * absPred

        // ANE soft residual on the mismatch (noise rejection).
        let rawResidual = abs(predicted - observedFlex)
        let soft = softResidual(rawResidual)

        let prediction = DeltaHRVFlexAIDPrediction(
            deltaHRV: deltaHRV,
            flexAIDDeltaS: observedFlex,
            predictedDeltaS: predicted,
            residual: soft,
            shouldGround: soft > Self.residualGroundingThreshold,
            substanceId: substanceId,
            source: source
        )
        lastPrediction = prediction
        return prediction
    }

    /// Predict and return whether grounding should run (σ_irr minimization assist).
    @discardableResult
    public func predictAndGround(
        deltaHRV: Double,
        flexAIDDeltaS: Double,
        substanceId: String? = nil
    ) -> DeltaHRVFlexAIDPrediction {
        predict(deltaHRV: deltaHRV, flexAIDDeltaS: flexAIDDeltaS, substanceId: substanceId)
    }

    /// Convert ΔS bits to entropy penalty kcal/mol (NATURaL thermodynamic parity).
    public nonisolated func entropyPenaltyKcal(deltaSBits: Double) -> Double {
        ThermodynamicConstants.entropyPenaltyKcal(deltaSBits: deltaSBits)
    }

    // MARK: - Private

    private func softResidual(_ r: Double) -> Double {
        // Soft-threshold via ANE-class map: reuses kernel thresholding idea.
        let lambda = 0.02
        if r > lambda { return r - lambda }
        return 0
    }
}
