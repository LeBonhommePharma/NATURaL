import Foundation
#if canImport(clibBonhommeAccel)
import clibBonhommeAccel
#endif

/// Swift wrappers for accelerated O(n^2) pairwise scoring.
public enum AccelPairwise {

    /// Whether the C++ pairwise backend is available.
    public static var isAvailable: Bool {
        AccelBackend.isAvailable
    }

    // Note: The pairwise scoring API uses function pointers (BAPairwiseScoreFn)
    // which cannot be easily bridged from Swift closures due to the C callback
    // convention. For Phase 1, the Swift analyzers will continue to use their
    // own loops but can be accelerated via OpenMP/GPU in the C++ library
    // when called from C++ clients (e.g., FlexAIDdS).
    //
    // For Swift usage, the batch entropy and correlation APIs provide the
    // primary acceleration benefit. The pairwise API is primarily useful
    // for C++ clients or future Swift-to-C++ integration via @convention(c).
}
