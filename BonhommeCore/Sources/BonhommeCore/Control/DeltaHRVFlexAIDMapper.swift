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
    /// Soft residual |predicted − observed| (bits).
    public let residual: Double
    /// Whether residual exceeds grounding threshold.
    public let shouldGround: Bool
    /// Optional substance id when profile-backed.
    public let substanceId: String?
    /// Source label: live · BindingEntropyProfile · live+profile.
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

/// Maps HRV entropy collapse onto FlexAID configurational entropy.
///
/// Reuses:
/// - `BindingEntropyProfile` reference ΔS_config database
/// - `CrossDomainValidator` regression slope when paired observations exist
/// - `ThermodynamicConstants` for bits ↔ kcal/mol
///
/// Sign convention: negative = collapse / binding constraint (both domains).
public actor DeltaHRVFlexAIDMapper {
    public static let shared = DeltaHRVFlexAIDMapper()

    /// Default |ΔH_hrv| ≈ slope × |ΔS_config| (literature-scale prior).
    public static let defaultSlope: Double = 0.85

    /// Residual (bits) above which grounding is recommended.
    public static let residualGroundingThreshold: Double = 0.45

    /// Soft-threshold floor on residual (noise rejection).
    private static let residualLambda: Double = 0.02

    private var calibratedSlope: Double = DeltaHRVFlexAIDMapper.defaultSlope
    private var calibratedIntercept: Double = 0
    private var lastPrediction: DeltaHRVFlexAIDPrediction?

    public init() {}

    public func last() -> DeltaHRVFlexAIDPrediction? { lastPrediction }

    public func slope() -> Double { calibratedSlope }

    /// Calibrate from a `CrossDomainValidator.ValidationResult`.
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
        let safeHRV = deltaHRV.isFinite ? deltaHRV : 0
        let safeFlexIn = flexAIDDeltaS.isFinite ? flexAIDDeltaS : 0

        var observedFlex = safeFlexIn
        var source = "live"
        var hasMolecularAnchor = abs(safeFlexIn) > 1e-9
        if let id = substanceId, let profile = BindingEntropyProfile.profile(for: id) {
            if abs(safeFlexIn) < 1e-9 {
                observedFlex = profile.expectedDeltaSBits
                source = "BindingEntropyProfile"
            } else {
                source = "live+profile"
            }
            hasMolecularAnchor = true
        }

        // Invert regression: |ΔH| ≈ slope × |ΔS| + intercept
        // → |ΔS| ≈ (|ΔH| − intercept) / slope
        let absHRV = abs(safeHRV)
        let absPred = max(0, (absHRV - calibratedIntercept) / max(calibratedSlope, 1e-6))
        let sign: Double = (safeHRV < 0 || observedFlex < 0) ? -1 : (safeHRV > 0 ? 1 : -1)
        let predicted = sign * absPred

        let soft = softResidual(abs(predicted - observedFlex))

        // Residual grounding only when molecular ΔS is live or profile-backed.
        // Without an anchor, residual ≈ |predicted| and modest SCI swings false-ground.
        let residualGround =
            hasMolecularAnchor
            && soft.isFinite
            && soft > Self.residualGroundingThreshold

        let prediction = DeltaHRVFlexAIDPrediction(
            deltaHRV: safeHRV,
            flexAIDDeltaS: observedFlex,
            predictedDeltaS: predicted.isFinite ? predicted : 0,
            residual: soft.isFinite ? soft : 0,
            shouldGround: residualGround,
            substanceId: substanceId,
            source: source
        )
        lastPrediction = prediction
        return prediction
    }

    /// Alias for grounding assist paths (identical to `predict`).
    @discardableResult
    public func predictAndGround(
        deltaHRV: Double,
        flexAIDDeltaS: Double,
        substanceId: String? = nil
    ) -> DeltaHRVFlexAIDPrediction {
        predict(deltaHRV: deltaHRV, flexAIDDeltaS: flexAIDDeltaS, substanceId: substanceId)
    }

    /// ΔS bits → entropy penalty kcal/mol (thermodynamic parity with FlexAID).
    public nonisolated func entropyPenaltyKcal(deltaSBits: Double) -> Double {
        ThermodynamicConstants.entropyPenaltyKcal(deltaSBits: deltaSBits)
    }

    // MARK: - Private

    private func softResidual(_ r: Double) -> Double {
        if r > Self.residualLambda { return r - Self.residualLambda }
        return 0
    }
}
