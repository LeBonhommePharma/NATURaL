import Foundation
#if canImport(clibBonhommeAccel)
import clibBonhommeAccel
#endif

/// Swift wrappers for accelerated descriptive statistics.
public enum AccelStatistics {

    /// Accelerated mean and sample standard deviation.
    public static func descriptiveStats(_ values: [Double]) -> (mean: Double, sd: Double)? {
        #if canImport(clibBonhommeAccel)
        guard !values.isEmpty else { return nil }
        var mean: Double = 0, sd: Double = 0
        let status = values.withUnsafeBufferPointer { buf in
            ba_descriptive_stats(buf.baseAddress, buf.count, &mean, &sd)
        }
        return status == BA_OK ? (mean, sd) : nil
        #else
        return nil
        #endif
    }

    /// Accelerated z-score outlier detection.
    /// Returns array of booleans: true if |z| > threshold.
    public static func zscoreOutliers(_ values: [Double], threshold: Double = 2.0) -> [Bool]? {
        #if canImport(clibBonhommeAccel)
        guard values.count >= 2 else { return nil }
        var flags = [Int32](repeating: 0, count: values.count)
        let status = values.withUnsafeBufferPointer { buf in
            ba_zscore_outliers(buf.baseAddress, buf.count, threshold, &flags)
        }
        return status == BA_OK ? flags.map { $0 != 0 } : nil
        #else
        return nil
        #endif
    }
}
