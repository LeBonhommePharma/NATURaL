import Foundation
#if canImport(clibBonhommeAccel)
import clibBonhommeAccel
#endif

/// Runtime compute backend for BonhommeAccel.
///
/// Automatically detects the fastest available backend (Metal, CUDA, AVX2, NEON, etc.)
/// and caches the result. Thread-safe.
public enum AccelBackend: Int, Sendable {
    case scalar  = 0
    case neon    = 1
    case avx2    = 2
    case avx512  = 3
    case openmp  = 4
    case metal   = 5
    case cuda    = 6
    case rocm    = 7

    /// The currently active backend, detected at first access.
    public static let active: AccelBackend = {
        #if canImport(clibBonhommeAccel)
        let raw = ba_detect_best_backend()
        return AccelBackend(rawValue: Int(raw.rawValue)) ?? .scalar
        #else
        return .scalar
        #endif
    }()

    /// Human-readable name.
    public var name: String {
        #if canImport(clibBonhommeAccel)
        return String(cString: ba_backend_name(BABackend(rawValue: UInt32(rawValue))))
        #else
        switch self {
        case .scalar: return "Scalar"
        case .neon:   return "NEON"
        case .avx2:   return "AVX2"
        case .avx512: return "AVX-512"
        case .openmp: return "OpenMP"
        case .metal:  return "Metal"
        case .cuda:   return "CUDA"
        case .rocm:   return "ROCm"
        }
        #endif
    }

    /// Whether the C++ accelerator library is available.
    public static var isAvailable: Bool {
        #if canImport(clibBonhommeAccel)
        return true
        #else
        return false
        #endif
    }

    /// Library version string.
    public static var version: String {
        #if canImport(clibBonhommeAccel)
        return String(cString: ba_version())
        #else
        return "unavailable"
        #endif
    }
}
