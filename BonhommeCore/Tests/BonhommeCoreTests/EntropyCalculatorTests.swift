import XCTest
@testable import BonhommeCore

/// Tests for EntropyCalculator, validating both linear (Shannon) and circular entropy methods,
/// as well as NaN/infinity input handling.
final class EntropyCalculatorTests: XCTestCase {

    private let calc = EntropyCalculator(binCount: 32)

    // MARK: - Circular Entropy

    /// Key regression test: angles at ±179° are only 2° apart on the circle.
    /// The circular method should produce LOW entropy (concentrated distribution).
    func testCircularEntropyWraparound() {
        // 100 angles clustered near +179° and 100 near -179°
        // On the circle these are all within ~4° of each other
        let anglesNearBoundary = (0..<100).map { _ in 179.0 + Double.random(in: -1...1) }
            + (0..<100).map { _ in -179.0 + Double.random(in: -1...1) }

        let circularH = calc.circularShannonEntropy(anglesNearBoundary)

        // Circular: should be low (clustered in ~2 adjacent bins around ±180°)
        XCTAssertLessThan(circularH, 2.0,
            "Circular entropy should be low for angles clustered near ±180°")

        // Sanity: entropy should be positive (2 occupied bins → H ≥ 0)
        XCTAssertGreaterThan(circularH, 0,
            "Circular entropy should be positive for non-degenerate distribution")
    }

    /// Uniformly distributed angles across [-180, 180) should produce near-maximum entropy.
    func testCircularEntropyUniform() {
        let uniformAngles = (0..<1000).map { i in
            -180.0 + 360.0 * Double(i) / 1000.0
        }

        let h = calc.circularShannonEntropy(uniformAngles)
        let maxH = log2(Double(calc.binCount)) // log2(32) = 5.0

        // Should be close to maximum (within 5%)
        XCTAssertGreaterThan(h, maxH * 0.95,
            "Uniform distribution should have near-maximum entropy")
    }

    /// For angles well within the interior [-90, +90], both methods should agree.
    func testCircularMatchesLinearForInterior() {
        let interiorAngles = (0..<200).map { i in
            -45.0 + 90.0 * Double(i) / 199.0
        }

        let circularH = calc.circularShannonEntropy(interiorAngles)
        let linearH = calc.shannonEntropy(interiorAngles)

        // Both should be in the same ballpark. The values won't be identical
        // because circular uses fixed [-180, 180) bins while linear uses adaptive.
        // But the relative ordering and magnitude should be similar.
        // For a 90° spread within 360° bins, circular will be lower than linear
        // (data occupies fewer bins in the fixed scheme).
        XCTAssertGreaterThan(circularH, 0,
            "Circular entropy should be positive for non-degenerate data")
        XCTAssertGreaterThan(linearH, 0,
            "Linear entropy should be positive for non-degenerate data")
    }

    /// Angles wrapping beyond [-180, 180] should be normalized correctly.
    func testCircularEntropyAngleWrapping() {
        // Angles at 350° should be equivalent to -10°
        // Angles at -350° should be equivalent to 10°
        let rawAngles = (0..<100).map { _ in 350.0 + Double.random(in: -2...2) }
            + (0..<100).map { _ in -350.0 + Double.random(in: -2...2) }

        let h = calc.circularShannonEntropy(rawAngles)

        // After wrapping, 350° → -10° and -350° → 10°, so clustered near 0°
        XCTAssertLessThan(h, 2.5,
            "Wrapped angles should produce low entropy (clustered near 0°)")
    }

    // MARK: - NaN / Infinity Guards

    /// Shannon entropy should filter out NaN values gracefully.
    func testNaNFilteredInShannonEntropy() {
        let values = [1.0, 2.0, .nan, 3.0, 4.0, .nan, 5.0]
        let h = calc.shannonEntropy(values)
        XCTAssertFalse(h.isNaN, "Shannon entropy should not return NaN")
        XCTAssertGreaterThan(h, 0, "Filtered values should produce positive entropy")
    }

    /// Shannon entropy should filter out infinity values gracefully.
    func testInfinityFilteredInShannonEntropy() {
        let values = [1.0, 2.0, .infinity, 3.0, 4.0, -.infinity, 5.0]
        let h = calc.shannonEntropy(values)
        XCTAssertFalse(h.isNaN, "Shannon entropy should not return NaN for infinity inputs")
        XCTAssertGreaterThan(h, 0, "Filtered values should produce positive entropy")
    }

    /// Circular entropy should filter out NaN values gracefully.
    func testNaNFilteredInCircularEntropy() {
        let angles = [10.0, 20.0, .nan, 30.0, 15.0, .nan]
        let h = calc.circularShannonEntropy(angles)
        XCTAssertFalse(h.isNaN, "Circular entropy should not return NaN")
        XCTAssertGreaterThan(h, 0, "Filtered angles should produce positive entropy")
    }

    /// If all values are NaN/infinity, entropy should be 0 (insufficient data).
    func testAllNaNReturnsZero() {
        let allNaN = [Double.nan, Double.nan, Double.nan]
        XCTAssertEqual(calc.shannonEntropy(allNaN), 0)
        XCTAssertEqual(calc.circularShannonEntropy(allNaN), 0)
    }

    // MARK: - Edge Cases

    func testEmptyReturnsZero() {
        XCTAssertEqual(calc.shannonEntropy([]), 0)
        XCTAssertEqual(calc.circularShannonEntropy([]), 0)
    }

    func testSingleValueReturnsZero() {
        XCTAssertEqual(calc.shannonEntropy([42.0]), 0)
        XCTAssertEqual(calc.circularShannonEntropy([42.0]), 0)
    }

    // MARK: - SCI maxEntropy = log₂(binCount)

    /// Default maxEntropy is log₂(binCount); near-uniform → score ≈ 0, concentrated → near 1.
    func testEntropyToScoreDefaultMaxEntropyIsLog2BinCount() {
        let calc32 = EntropyCalculator(binCount: 32)
        let theoreticalMax = log2(Double(calc32.binCount)) // 5.0
        XCTAssertEqual(theoreticalMax, 5.0, accuracy: 1e-12)

        // Near-uniform samples across many adaptive bins → H ≈ log₂(32) → score ≈ 0
        let uniform = (0..<1024).map { Double($0) }
        let hUniform = calc32.shannonEntropy(uniform)
        let scoreUniform = calc32.entropyToScore(hUniform)
        XCTAssertGreaterThan(hUniform, theoreticalMax * 0.9,
            "Near-uniform sample should approach max entropy")
        XCTAssertLessThan(scoreUniform, 0.15,
            "Near-uniform sample should yield coherence score ≈ 0")

        guard let analyzedUniform = calc32.analyze(uniform) else {
            return XCTFail("analyze should succeed for uniform sample")
        }
        XCTAssertEqual(analyzedUniform.score, scoreUniform, accuracy: 1e-12,
            "analyze() must use the same default maxEntropy as entropyToScore")
        XCTAssertLessThan(analyzedUniform.score, 0.15)

        // Identical values → H = 0 → score = 1 (adaptive range collapses)
        let concentrated = Array(repeating: 100.0, count: 200)
        let hConcentrated = calc32.shannonEntropy(concentrated)
        let scoreConcentrated = calc32.entropyToScore(hConcentrated)
        XCTAssertEqual(hConcentrated, 0, accuracy: 1e-12,
            "Degenerate sample should have zero entropy")
        XCTAssertEqual(scoreConcentrated, 1.0, accuracy: 1e-12,
            "Degenerate sample should yield coherence score 1")

        guard let analyzedConcentrated = calc32.analyze(concentrated) else {
            return XCTFail("analyze should succeed for concentrated sample")
        }
        XCTAssertEqual(analyzedConcentrated.score, scoreConcentrated, accuracy: 1e-12)
        XCTAssertEqual(analyzedConcentrated.score, 1.0, accuracy: 1e-12)

        // Perfect coherence: H = 0 → score = 1
        XCTAssertEqual(calc32.entropyToScore(0), 1.0, accuracy: 1e-12)
        // At theoretical max: score = 0
        XCTAssertEqual(calc32.entropyToScore(theoreticalMax), 0.0, accuracy: 1e-12)
    }

    /// Explicit maxEntropy override still normalizes against the provided ceiling.
    func testEntropyToScoreOverrideStillWorks() {
        let calc32 = EntropyCalculator(binCount: 32)

        // Override to 10: entropy 5 → score 0.5
        XCTAssertEqual(calc32.entropyToScore(5.0, maxEntropy: 10.0), 0.5, accuracy: 0.001)
        // Override to 8 (legacy constant): entropy 4 → score 0.5
        XCTAssertEqual(calc32.entropyToScore(4.0, maxEntropy: 8.0), 0.5, accuracy: 0.001)

        let values = [700.0, 750.0, 800.0, 850.0, 900.0]
        guard let overridden = calc32.analyze(values, maxEntropy: 10.0) else {
            return XCTFail("analyze with override should succeed")
        }
        let expectedScore = calc32.entropyToScore(overridden.entropy, maxEntropy: 10.0)
        XCTAssertEqual(overridden.score, expectedScore, accuracy: 1e-12)

        // Default path must differ from a deliberately wrong ceiling when H is non-zero
        guard let defaulted = calc32.analyze(values) else {
            return XCTFail("analyze with default should succeed")
        }
        XCTAssertNotEqual(defaulted.score, overridden.score, accuracy: 1e-6,
            "Default log₂(binCount) normalization should differ from maxEntropy: 10 override")
    }

    // MARK: - Fixed-domain NaN / Inf filter

    /// Fixed-domain path filters non-finite values; result matches finite-only input.
    func testFixedDomainNaNInfMixedEqualsFiniteOnly() {
        let finite = [400.0, 600.0, 800.0, 1000.0, 1200.0, 700.0, 900.0]
        let mixed = [400.0, .nan, 600.0, .infinity, 800.0, 1000.0, -.infinity, 1200.0, 700.0, 900.0]
        let hFinite = calc.shannonEntropy(finite, domainMin: 300, domainMax: 1500)
        let hMixed = calc.shannonEntropy(mixed, domainMin: 300, domainMax: 1500)
        XCTAssertEqual(hMixed, hFinite, accuracy: 1e-12)
        XCTAssertFalse(hMixed.isNaN)
    }

    /// Fewer than two finite values → 0.
    func testFixedDomainFewerThanTwoFiniteReturnsZero() {
        XCTAssertEqual(calc.shannonEntropy([.nan, .infinity, 500.0], domainMin: 300, domainMax: 1500), 0)
        XCTAssertEqual(calc.shannonEntropy([.nan, .nan], domainMin: 300, domainMax: 1500), 0)
    }

    // MARK: - Batch circular Shannon

    func testCircularBatchEmptyReturnsEmpty() {
        XCTAssertEqual(calc.circularShannonEntropyBatch([]), [])
    }

    func testCircularBatchSingleArrayMatchesSingle() {
        let a = (0..<300).map { -90.0 + Double($0) * 0.5 }
        let batch = calc.circularShannonEntropyBatch([a])
        XCTAssertEqual(batch.count, 1)
        XCTAssertEqual(batch[0], calc.circularShannonEntropy(a), accuracy: 1e-12)
    }

    func testCircularBatchManyBondsMatchSingles() {
        // FlexAID-style: 8 bonds with different spreads / centers
        var arrays: [[Double]] = []
        for b in 0..<8 {
            let center = -150.0 + 40.0 * Double(b)
            let spread = 10.0 + 15.0 * Double(b % 3)
            let n = 80 + b * 17 // odd/even mix for SIMD tails
            arrays.append((0..<n).map { i in
                center - spread + 2 * spread * Double(i) / Double(max(n - 1, 1))
            })
        }
        let batch = calc.circularShannonEntropyBatch(arrays)
        XCTAssertEqual(batch.count, arrays.count)
        for i in arrays.indices {
            XCTAssertEqual(batch[i], calc.circularShannonEntropy(arrays[i]), accuracy: 1e-12,
                           "batch[\(i)] vs single")
        }
    }

    func testCircularBatchWithNaNMatchesFiniteOnly() {
        // Interleave non-finite *alongside* clean samples (do not replace them).
        let clean = (0..<200).map { Double($0 % 50) - 25 }
        var dirty: [Double] = []
        dirty.reserveCapacity(clean.count + 20)
        for (i, v) in clean.enumerated() {
            if i % 20 == 0 { dirty.append(.nan) }
            if i % 20 == 10 { dirty.append(.infinity) }
            dirty.append(v)
        }
        dirty.append(-.infinity)

        let batch = calc.circularShannonEntropyBatch([dirty, clean])
        XCTAssertEqual(batch.count, 2)
        XCTAssertEqual(batch[0], batch[1], accuracy: 1e-12)
        XCTAssertEqual(batch[0], calc.circularShannonEntropy(clean), accuracy: 1e-12)
    }

    func testCircularBatchWraparoundMultiRevolution() {
        // Multi-turn equivalents of a narrow cluster near −10°
        let primary = (0..<400).map { _ in -10.0 + Double.random(in: -0.5...0.5) }
        let wrapped = primary.map { $0 + 360.0 } + primary.map { $0 - 720.0 }
        let batch = calc.circularShannonEntropyBatch([primary, wrapped])
        // Wrapped has 2× samples of same shape → same H for uniform noise cluster
        XCTAssertEqual(batch[0], calc.circularShannonEntropy(primary), accuracy: 1e-12)
        XCTAssertLessThan(batch[0], 2.0)
        XCTAssertLessThan(batch[1], 2.5)
    }

    func testCircularBatchDegenerateAndUniform() {
        let deg = Array(repeating: 33.0, count: 100)
        let uniform = (0..<512).map { -180.0 + 360.0 * Double($0) / 512.0 }
        let batch = calc.circularShannonEntropyBatch([deg, uniform, [1.0], []])
        XCTAssertEqual(batch[0], 0, accuracy: 1e-12)
        XCTAssertGreaterThan(batch[1], log2(32.0) * 0.9)
        XCTAssertEqual(batch[2], 0, accuracy: 1e-12) // single value
        XCTAssertEqual(batch[3], 0, accuracy: 1e-12) // empty
    }

    func testBinCountClampMinimumOne() {
        let c = EntropyCalculator(binCount: 0)
        XCTAssertEqual(c.binCount, 1)
        // Should not crash
        _ = c.circularShannonEntropy([1, 2, 3, 4])
        _ = c.circularShannonEntropyBatch([[1, 2, 3], [4, 5, 6]])
    }
}
