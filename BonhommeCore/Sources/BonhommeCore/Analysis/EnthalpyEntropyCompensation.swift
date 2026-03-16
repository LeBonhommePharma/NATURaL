import Foundation

/// A single ΔH / -TΔS data point from ITC-profiled substance-target binding.
public struct CompensationDataPoint: Sendable {
    public let substanceId: String
    public let targetId: String
    public let deltaHKcal: Double
    public let minusTDeltaSKcal: Double
    public let deltaGKcal: Double

    public init(substanceId: String, targetId: String, deltaHKcal: Double, minusTDeltaSKcal: Double, deltaGKcal: Double) {
        self.substanceId = substanceId
        self.targetId = targetId
        self.deltaHKcal = deltaHKcal
        self.minusTDeltaSKcal = minusTDeltaSKcal
        self.deltaGKcal = deltaGKcal
    }
}

/// Classification of enthalpy-entropy compensation.
public enum CompensationType: String, Sendable {
    /// Full compensation: α ≈ -1, R² > 0.7. ΔG stays approximately constant
    /// as ΔH and -TΔS trade off against each other.
    case full
    /// Partial compensation: α < -0.3, R² > 0.4.
    case partial
    /// No significant compensation detected.
    case none
}

/// Result of enthalpy-entropy compensation analysis across ITC-profiled substances.
///
/// Enthalpy-entropy compensation is a well-known phenomenon in drug-receptor
/// thermodynamics: optimizing enthalpic contacts (H-bonds, electrostatics) often
/// comes at an entropic cost (conformational restriction), and vice versa.
///
/// The regression -TΔS = α × ΔH + β quantifies this trade-off.
/// If α ≈ -1, the compensation is complete (ΔG constant across the series).
public struct CompensationResult: Sendable {
    /// Data points used in the regression.
    public let dataPoints: [CompensationDataPoint]

    /// Slope (α) of -TΔS = α × ΔH + β.
    /// α ≈ -1 indicates full compensation.
    public let slope: Double

    /// Intercept (β) of the regression.
    public let intercept: Double

    /// R-squared (coefficient of determination).
    public let rSquared: Double

    /// Pearson correlation coefficient.
    public let pearsonR: Double

    /// Number of ITC-profiled substances.
    public var n: Int { dataPoints.count }

    /// Classification of compensation type.
    public var compensationType: CompensationType {
        if abs(slope + 1.0) < 0.2 && rSquared > 0.7 { return .full }
        if slope < -0.3 && rSquared > 0.4 { return .partial }
        return .none
    }

    /// Substances that deviate significantly from the compensation line (|residual| > 2×RMSE).
    /// These have unusual enthalpy/entropy balance and are pharmacovigilance flags.
    public let outliers: [CompensationDataPoint]

    /// Bilingual summary.
    public var summary: LocalizedString {
        let slopeText = String(format: "%.2f", slope)
        let r2Text = String(format: "%.3f", rSquared)
        let typeText: String
        let typeFr: String
        switch compensationType {
        case .full: typeText = "full"; typeFr = "complète"
        case .partial: typeText = "partial"; typeFr = "partielle"
        case .none: typeText = "not significant"; typeFr = "non significative"
        }
        return LocalizedString(
            en: "Enthalpy-entropy compensation (n=\(n)): -TΔS = \(slopeText)×ΔH + \(String(format: "%.1f", intercept)). R² = \(r2Text). Compensation: \(typeText). \(outliers.count) outlier(s).",
            fr: "Compensation enthalpie-entropie (n=\(n)) : -TΔS = \(slopeText)×ΔH + \(String(format: "%.1f", intercept)). R² = \(r2Text). Compensation : \(typeFr). \(outliers.count) valeur(s) aberrante(s)."
        )
    }

    public init(
        dataPoints: [CompensationDataPoint],
        slope: Double,
        intercept: Double,
        rSquared: Double,
        pearsonR: Double,
        outliers: [CompensationDataPoint]
    ) {
        self.dataPoints = dataPoints
        self.slope = slope
        self.intercept = intercept
        self.rSquared = rSquared
        self.pearsonR = pearsonR
        self.outliers = outliers
    }
}

// MARK: - Analyzer

/// Detects enthalpy-entropy compensation across ITC-profiled substance-target pairs.
///
/// Uses linear regression of -TΔS vs ΔH from ThermodynamicBindingProfile entries
/// that have full ITC decomposition. Identifies compensation type and flags outliers.
public struct EnthalpyEntropyCompensation: Sendable {

    public init() {}

    /// Analyze enthalpy-entropy compensation across all ITC-profiled substances.
    ///
    /// - Returns: CompensationResult, or nil if fewer than 4 ITC-profiled substances.
    public static func analyze() -> CompensationResult? {
        let dataPoints = extractDataPoints(from: ThermodynamicBindingProfile.knownProfiles)
        return buildResult(from: dataPoints)
    }

    /// Analyze compensation for a specific subset of substances.
    public static func analyze(substanceIds: [String]) -> CompensationResult? {
        let lowered = Set(substanceIds.map { $0.lowercased() })
        let filtered = ThermodynamicBindingProfile.knownProfiles.filter {
            lowered.contains($0.substanceId)
        }
        let dataPoints = extractDataPoints(from: filtered)
        return buildResult(from: dataPoints)
    }

    /// Flag substances that deviate from the compensation line.
    public static func flagInterestingOutliers() -> [CompensationDataPoint] {
        analyze()?.outliers ?? []
    }

    // MARK: - Private

    private static func extractDataPoints(from profiles: [ThermodynamicBindingProfile]) -> [CompensationDataPoint] {
        profiles.compactMap { profile -> CompensationDataPoint? in
            guard profile.isPrimaryTarget,
                  let thermo = profile.thermodynamics else { return nil }
            return CompensationDataPoint(
                substanceId: profile.substanceId,
                targetId: profile.targetId,
                deltaHKcal: thermo.deltaHKcal,
                minusTDeltaSKcal: thermo.minusTDeltaSKcal,
                deltaGKcal: thermo.deltaGKcal
            )
        }
    }

    private static func buildResult(from dataPoints: [CompensationDataPoint]) -> CompensationResult? {
        guard dataPoints.count >= 4 else { return nil }

        let x = dataPoints.map(\.deltaHKcal)
        let y = dataPoints.map(\.minusTDeltaSKcal)

        let r = pearsonCorrelation(x, y)
        let reg = linearRegression(x: x, y: y)

        // Identify outliers: |residual| > 2 × RMSE
        var sumSqResid = 0.0
        for i in 0..<dataPoints.count {
            let predicted = reg.slope * x[i] + reg.intercept
            let residual = y[i] - predicted
            sumSqResid += residual * residual
        }
        let rmse = sqrt(sumSqResid / Double(dataPoints.count))
        let threshold = 2.0 * rmse

        var outliers: [CompensationDataPoint] = []
        for i in 0..<dataPoints.count {
            let predicted = reg.slope * x[i] + reg.intercept
            if abs(y[i] - predicted) > threshold {
                outliers.append(dataPoints[i])
            }
        }

        return CompensationResult(
            dataPoints: dataPoints,
            slope: reg.slope,
            intercept: reg.intercept,
            rSquared: r * r,
            pearsonR: r,
            outliers: outliers
        )
    }

    private static func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
        let n = Double(x.count)
        guard n >= 2, x.count == y.count else { return 0 }
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n
        var sumXY = 0.0, sumX2 = 0.0, sumY2 = 0.0
        for i in 0..<x.count {
            let dx = x[i] - meanX
            let dy = y[i] - meanY
            sumXY += dx * dy
            sumX2 += dx * dx
            sumY2 += dy * dy
        }
        let denom = sqrt(sumX2 * sumY2)
        return denom > 0 ? sumXY / denom : 0
    }

    private static func linearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double) {
        let n = Double(x.count)
        guard n >= 2 else { return (0, 0) }
        let meanX = x.reduce(0, +) / n
        let meanY = y.reduce(0, +) / n
        var sumXY = 0.0, sumX2 = 0.0
        for i in 0..<x.count {
            sumXY += (x[i] - meanX) * (y[i] - meanY)
            sumX2 += (x[i] - meanX) * (x[i] - meanX)
        }
        let slope = sumX2 > 0 ? sumXY / sumX2 : 0
        return (slope: slope, intercept: meanY - slope * meanX)
    }
}
