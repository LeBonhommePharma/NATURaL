/*
 * dispatch.cpp — Runtime backend detection.
 *
 * Probes CPU features (AVX2, AVX-512, NEON), GPU availability (Metal, CUDA, ROCm),
 * and OpenMP support at runtime. Returns the fastest available backend.
 */

#include "backend.h"

namespace ba {

BABackend probe_best_backend() {
    // Phase 1: start with scalar, progressively detect better backends.
    // Detection order: GPU > SIMD > OpenMP > Scalar

#if defined(BA_HAS_CUDA)
    // TODO Phase 4: CUDA runtime detection
    // if (cudaGetDeviceCount(&count) == cudaSuccess && count > 0)
    //     return BA_BACKEND_CUDA;
#endif

#if defined(BA_HAS_ROCM)
    // TODO Phase 4: ROCm/HIP runtime detection
    // if (hipGetDeviceCount(&count) == hipSuccess && count > 0)
    //     return BA_BACKEND_ROCM;
#endif

#if defined(__APPLE__)
    // TODO Phase 3: Metal runtime detection
    // Metal is available on all Apple platforms except watchOS (limited).
    // #if !TARGET_OS_WATCH
    //     return BA_BACKEND_METAL;
    // #endif
#endif

    // SIMD detection — only advertise backends that have compiled kernels.
    // AVX-512 is detected but maps to AVX2 until dedicated kernels exist.
#if defined(BA_HAS_NEON) && (defined(__aarch64__) || defined(_M_ARM64))
    return BA_BACKEND_NEON;
#elif defined(BA_HAS_AVX2) && (defined(__x86_64__) || defined(_M_X64))
    #if defined(__GNUC__) || defined(__clang__)
        __builtin_cpu_init();
        // Prefer AVX2 when available; do not claim AVX-512 without kernels
        // (would misreport backend while still running AVX2/scalar).
        if (__builtin_cpu_supports("avx2")) {
            return BA_BACKEND_AVX2;
        }
    #elif defined(_MSC_VER)
        #include <intrin.h>
        int info[4];
        __cpuidex(info, 7, 0);
        if (info[1] & (1 << 5)) return BA_BACKEND_AVX2;
    #endif
#endif

#if defined(BA_HAS_OPENMP)
    return BA_BACKEND_OPENMP;
#endif

    return BA_BACKEND_SCALAR;
}

} // namespace ba
