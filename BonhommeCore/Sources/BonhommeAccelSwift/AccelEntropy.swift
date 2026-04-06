import Foundation
#if canImport(clibBonhommeAccel)
import clibBonhommeAccel
#endif

/// Swift wrappers for accelerated Shannon entropy computation.
///
/// Delegates to the C++ BonhommeAccel library when available.
/// Falls back gracefully when the library is not linked.
public enum AccelEntropy {

    /// Minimum array size to justify C++ delegation overhead.
    /// Below this, Swift's native implementation is faster.
    public static let delegationThreshold = 64

    // MARK: - Single Array

    /// Accelerated Shannon entropy with adaptive bin range.
    /// Returns nil if the C++ library is not available or data is insufficient.
    public static func shannonEntropy(_ values: [Double], binCount: Int = 32) -> Double? {
        #if canImport(clibBonhommeAccel)
        guard values.count >= 2 else { return nil }
        var result: Double = 0
        let status = values.withUnsafeBufferPointer { buf in
            ba_shannon_entropy(buf.baseAddress, buf.count, Int32(binCount), &result)
        }
        return status == BA_OK ? result : nil
        #else
        return nil
        #endif
    }

    /// Accelerated circular Shannon entropy for torsional angles.
    public static func circularShannonEntropy(_ angles: [Double], binCount: Int = 32) -> Double? {
        #if canImport(clibBonhommeAccel)
        guard angles.count >= 2 else { return nil }
        var result: Double = 0
        let status = angles.withUnsafeBufferPointer { buf in
            ba_circular_shannon_entropy(buf.baseAddress, buf.count, Int32(binCount), &result)
        }
        return status == BA_OK ? result : nil
        #else
        return nil
        #endif
    }

    /// Accelerated fixed-domain Shannon entropy.
    public static func shannonEntropyFixed(_ values: [Double], binCount: Int = 32,
                                            domainMin: Double, domainMax: Double) -> Double? {
        #if canImport(clibBonhommeAccel)
        guard values.count >= 2 else { return nil }
        var result: Double = 0
        let status = values.withUnsafeBufferPointer { buf in
            ba_shannon_entropy_fixed(buf.baseAddress, buf.count, Int32(binCount),
                                      domainMin, domainMax, &result)
        }
        return status == BA_OK ? result : nil
        #else
        return nil
        #endif
    }

    // MARK: - Batch

    /// Accelerated batch Shannon entropy.
    /// Computes entropy for multiple arrays packed into a flat buffer.
    ///
    /// - Parameters:
    ///   - flat: Concatenated arrays.
    ///   - offsets: Starting index of each array.
    ///   - lengths: Number of elements in each array.
    ///   - binCount: Histogram bin count.
    /// - Returns: Array of entropy values, or nil if unavailable.
    public static func shannonEntropyBatch(flat: [Double], offsets: [Int], lengths: [Int],
                                            binCount: Int = 32) -> [Double]? {
        #if canImport(clibBonhommeAccel)
        guard offsets.count == lengths.count, !offsets.isEmpty else { return nil }
        let batchCount = offsets.count
        var results = [Double](repeating: 0, count: batchCount)

        let sizeOffsets = offsets.map { size_t($0) }
        let sizeLengths = lengths.map { size_t($0) }

        let status = flat.withUnsafeBufferPointer { flatBuf in
            sizeOffsets.withUnsafeBufferPointer { offBuf in
                sizeLengths.withUnsafeBufferPointer { lenBuf in
                    ba_shannon_entropy_batch(flatBuf.baseAddress, offBuf.baseAddress,
                                              lenBuf.baseAddress, batchCount,
                                              Int32(binCount), &results)
                }
            }
        }
        return status == BA_OK ? results : nil
        #else
        return nil
        #endif
    }

    /// Accelerated batch circular Shannon entropy.
    public static func circularShannonEntropyBatch(flat: [Double], offsets: [Int], lengths: [Int],
                                                    binCount: Int = 32) -> [Double]? {
        #if canImport(clibBonhommeAccel)
        guard offsets.count == lengths.count, !offsets.isEmpty else { return nil }
        let batchCount = offsets.count
        var results = [Double](repeating: 0, count: batchCount)

        let sizeOffsets = offsets.map { size_t($0) }
        let sizeLengths = lengths.map { size_t($0) }

        let status = flat.withUnsafeBufferPointer { flatBuf in
            sizeOffsets.withUnsafeBufferPointer { offBuf in
                sizeLengths.withUnsafeBufferPointer { lenBuf in
                    ba_circular_shannon_entropy_batch(flatBuf.baseAddress, offBuf.baseAddress,
                                                      lenBuf.baseAddress, batchCount,
                                                      Int32(binCount), &results)
                }
            }
        }
        return status == BA_OK ? results : nil
        #else
        return nil
        #endif
    }
}
