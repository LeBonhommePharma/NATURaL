import Foundation
#if canImport(clibBonhommeAccel)
import clibBonhommeAccel
#endif

/// Swift wrappers for accelerated correlation and regression.
public enum AccelCorrelation {

    /// Accelerated Pearson product-moment correlation coefficient.
    /// Returns nil if the C++ library is not available.
    public static func pearsonCorrelation(_ x: [Double], _ y: [Double]) -> Double? {
        #if canImport(clibBonhommeAccel)
        guard x.count >= 2, x.count == y.count else { return nil }
        var result: Double = 0
        let status = x.withUnsafeBufferPointer { xBuf in
            y.withUnsafeBufferPointer { yBuf in
                ba_pearson_correlation(xBuf.baseAddress, yBuf.baseAddress,
                                        x.count, &result)
            }
        }
        return status == BA_OK ? result : nil
        #else
        return nil
        #endif
    }

    /// Accelerated OLS linear regression: y = slope * x + intercept.
    /// Returns nil if unavailable.
    public static func linearRegression(x: [Double], y: [Double])
        -> (slope: Double, intercept: Double, mae: Double)? {
        #if canImport(clibBonhommeAccel)
        guard x.count >= 2, x.count == y.count else { return nil }
        var slope: Double = 0, intercept: Double = 0, mae: Double = 0
        let status = x.withUnsafeBufferPointer { xBuf in
            y.withUnsafeBufferPointer { yBuf in
                ba_linear_regression(xBuf.baseAddress, yBuf.baseAddress,
                                      x.count, &slope, &intercept, &mae)
            }
        }
        return status == BA_OK ? (slope, intercept, mae) : nil
        #else
        return nil
        #endif
    }

    /// Accelerated p-value for Pearson r via t-distribution.
    public static func pearsonPValue(r: Double, n: Int) -> Double? {
        #if canImport(clibBonhommeAccel)
        guard n > 2 else { return nil }
        var result: Double = 0
        let status = ba_pearson_pvalue(r, n, &result)
        return status == BA_OK ? result : nil
        #else
        return nil
        #endif
    }

    /// Accelerated regularized incomplete beta function I_x(a, b).
    public static func regularizedIncompleteBeta(x: Double, a: Double, b: Double) -> Double? {
        #if canImport(clibBonhommeAccel)
        var result: Double = 0
        let status = ba_regularized_incomplete_beta(x, a, b, &result)
        return status == BA_OK ? result : nil
        #else
        return nil
        #endif
    }
}
