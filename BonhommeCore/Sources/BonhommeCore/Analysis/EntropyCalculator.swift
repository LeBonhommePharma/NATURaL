import Foundation

/// Reusable Shannon entropy calculator for any distribution of continuous values.
///
/// Originally developed for HRV RR-interval analysis (Shannon Collapse Index),
/// this utility generalizes to sleep stage distributions, respiratory rate patterns,
/// activity variability, and any domain where distributional entropy measures
/// coherence or variability.
///
/// Methodology ported from the configurational entropy engine in FlexAIDdS,
/// adapted from molecular torsional distributions to generalized health signal distributions.
public struct EntropyCalculator: Sendable {
    /// Number of histogram bins for entropy calculation.
    public let binCount: Int

    public init(binCount: Int = 32) {
        self.binCount = binCount
    }

    /// Shannon entropy of a distribution of values, binned into a histogram.
    ///
    /// H = -Σ p_i log₂(p_i) for each bin with p_i > 0.
    ///
    /// - Parameter values: Array of continuous values (e.g., RR intervals in ms,
    ///   sleep stage durations, respiratory rates).
    /// - Returns: Entropy in bits. Higher = more uniform/variable; lower = more concentrated/coherent.
    public func shannonEntropy(_ values: [Double]) -> Double {
        guard values.count >= 2 else { return 0 }

        let minVal = values.min()!
        let maxVal = values.max()!
        let range = maxVal - minVal
        guard range > 0 else { return 0 }

        let binWidth = range / Double(binCount)
        var bins = [Int](repeating: 0, count: binCount)

        for value in values {
            let idx = min(binCount - 1, Int((value - minVal) / binWidth))
            bins[idx] += 1
        }

        let total = Double(values.count)
        var entropy = 0.0
        for count in bins where count > 0 {
            let p = Double(count) / total
            entropy -= p * log2(p)
        }
        return entropy
    }

    /// Map entropy (bits) to a 0–1 coherence score where 1 = maximally coherent.
    ///
    /// - Parameters:
    ///   - entropy: Shannon entropy in bits.
    ///   - maxEntropy: Theoretical maximum entropy for normalization.
    ///     Default 8.0 works for 32-bin histograms (log₂(32) ≈ 5, but practical max ~8 with noise).
    /// - Returns: Score in [0.0, 1.0] where 1.0 = zero entropy (perfect coherence).
    public func entropyToScore(_ entropy: Double, maxEntropy: Double = 8.0) -> Double {
        let clamped = max(0, min(maxEntropy, entropy))
        return 1.0 - (clamped / maxEntropy)
    }

    /// Shannon entropy with fixed bin edges over a known domain.
    ///
    /// Unlike the adaptive overload, this uses caller-specified domain bounds so that
    /// identical distributions always produce identical histograms regardless of sample extremes.
    /// Use for torsional angles (domainMin: -180, domainMax: 180) or any bounded domain.
    ///
    /// Values outside the domain are clamped to the nearest edge.
    ///
    /// - Parameters:
    ///   - values: Array of continuous values.
    ///   - domainMin: Lower bound of the histogram domain (inclusive).
    ///   - domainMax: Upper bound of the histogram domain (inclusive).
    /// - Returns: Entropy in bits.
    public func shannonEntropy(_ values: [Double], domainMin: Double, domainMax: Double) -> Double {
        guard values.count >= 2 else { return 0 }
        let range = domainMax - domainMin
        guard range > 0 else { return 0 }

        let binWidth = range / Double(binCount)
        var bins = [Int](repeating: 0, count: binCount)

        for value in values {
            let clamped = max(domainMin, min(domainMax, value))
            let idx = min(binCount - 1, Int((clamped - domainMin) / binWidth))
            bins[idx] += 1
        }

        let total = Double(values.count)
        var entropy = 0.0
        for count in bins where count > 0 {
            let p = Double(count) / total
            entropy -= p * log2(p)
        }
        return entropy
    }

    /// Compute both entropy and its normalized score in one call.
    ///
    /// - Parameters:
    ///   - values: Array of continuous values.
    ///   - maxEntropy: Theoretical maximum for score normalization.
    /// - Returns: Tuple of (entropy in bits, coherence score 0–1), or nil if insufficient data.
    public func analyze(_ values: [Double], maxEntropy: Double = 8.0) -> (entropy: Double, score: Double)? {
        guard values.count >= 2 else { return nil }
        let h = shannonEntropy(values)
        let s = entropyToScore(h, maxEntropy: maxEntropy)
        return (entropy: h, score: s)
    }
}

// MARK: - Shared Statistical Utilities

/// Pearson product-moment correlation coefficient.
///
/// - Parameters:
///   - x: First variable array.
///   - y: Second variable array (must have same count as x).
/// - Returns: Pearson r in [-1, 1], or 0 if insufficient data or zero variance.
public func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double {
    let n = Double(x.count)
    guard n >= 2, x.count == y.count else { return 0 }

    let meanX = x.reduce(0, +) / n
    let meanY = y.reduce(0, +) / n

    var sumXY = 0.0
    var sumX2 = 0.0
    var sumY2 = 0.0

    for i in 0..<x.count {
        let dx = x[i] - meanX
        let dy = y[i] - meanY
        sumXY += dx * dy
        sumX2 += dx * dx
        sumY2 += dy * dy
    }

    let denom = sqrt(sumX2 * sumY2)
    guard denom > 0 else { return 0 }
    return sumXY / denom
}

/// Ordinary least-squares linear regression: y = slope × x + intercept.
///
/// - Parameters:
///   - x: Independent variable array.
///   - y: Dependent variable array (must have same count as x).
/// - Returns: Tuple of (slope, intercept, mean absolute error).
public func linearRegression(x: [Double], y: [Double]) -> (slope: Double, intercept: Double, mae: Double) {
    let n = Double(x.count)
    guard n >= 2 else { return (slope: 0, intercept: 0, mae: 0) }

    let meanX = x.reduce(0, +) / n
    let meanY = y.reduce(0, +) / n

    var sumXY = 0.0
    var sumX2 = 0.0

    for i in 0..<x.count {
        sumXY += (x[i] - meanX) * (y[i] - meanY)
        sumX2 += (x[i] - meanX) * (x[i] - meanX)
    }

    let slope = sumX2 > 0 ? sumXY / sumX2 : 0
    let intercept = meanY - slope * meanX

    var totalError = 0.0
    for i in 0..<x.count {
        let predicted = slope * x[i] + intercept
        totalError += abs(y[i] - predicted)
    }
    let mae = totalError / n

    return (slope: slope, intercept: intercept, mae: mae)
}
