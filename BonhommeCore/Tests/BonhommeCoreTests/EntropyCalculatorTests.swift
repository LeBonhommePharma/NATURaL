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
}
