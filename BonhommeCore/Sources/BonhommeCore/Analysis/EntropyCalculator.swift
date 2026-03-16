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
    /// Uses data-adaptive bin range [min, max]. Appropriate for linear domains
    /// (RR intervals, respiratory rates). For circular domains (torsional angles),
    /// use ``circularShannonEntropy(_:)`` instead.
    ///
    /// - Parameter values: Array of continuous values (e.g., RR intervals in ms,
    ///   sleep stage durations, respiratory rates).
    /// - Returns: Entropy in bits. Higher = more uniform/variable; lower = more concentrated/coherent.
    public func shannonEntropy(_ values: [Double]) -> Double {
        let clean = values.filter { $0.isFinite }
        guard clean.count >= 2 else { return 0 }

        let minVal = clean.min()!
        let maxVal = clean.max()!
        let range = maxVal - minVal
        guard range > 0 else { return 0 }

        let binWidth = range / Double(binCount)
        var bins = [Int](repeating: 0, count: binCount)

        for value in clean {
            let idx = min(binCount - 1, Int((value - minVal) / binWidth))
            bins[idx] += 1
        }

        let total = Double(clean.count)
        var entropy = 0.0
        for count in bins where count > 0 {
            let p = Double(count) / total
            entropy -= p * log2(p)
        }
        return entropy
    }

    /// Shannon entropy for circular distributions (e.g., torsional angles in degrees).
    ///
    /// Unlike ``shannonEntropy(_:)``, this method uses **fixed bins** spanning [-180°, +180°)
    /// so that angles near the boundary (e.g., -179° and +179°) are correctly recognized
    /// as adjacent. This prevents the linear method from artificially inflating entropy
    /// for distributions that wrap around ±180°.
    ///
    /// H = -Σ p_i log₂(p_i) — same formula, domain-appropriate binning.
    ///
    /// - Parameter angles: Torsional angles in degrees. Values outside [-180, 180]
    ///   are wrapped via modular arithmetic.
    /// - Returns: Entropy in bits. Range [0, log₂(binCount)].
    public func circularShannonEntropy(_ angles: [Double]) -> Double {
        let clean = angles.filter { $0.isFinite }
        guard clean.count >= 2 else { return 0 }

        let binWidth = 360.0 / Double(binCount)
        var bins = [Int](repeating: 0, count: binCount)

        for angle in clean {
            // Wrap to [-180, 180)
            var a = angle.truncatingRemainder(dividingBy: 360.0)
            if a > 180.0 { a -= 360.0 }
            if a < -180.0 { a += 360.0 }
            // Map [-180, 180) → bin index [0, binCount)
            let idx = min(binCount - 1, Int((a + 180.0) / binWidth))
            bins[idx] += 1
        }

        let total = Double(clean.count)
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
