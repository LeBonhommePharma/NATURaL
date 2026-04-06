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

    // SIMD detection
#if defined(__aarch64__) || defined(_M_ARM64)
    // ARM64 always has NEON
    return BA_BACKEND_NEON;
#elif defined(__x86_64__) || defined(_M_X64)
    // x86_64: check for AVX-512 and AVX2 via compiler builtins
    #if defined(__GNUC__) || defined(__clang__)
        __builtin_cpu_init();
        if (__builtin_cpu_supports("avx512f")) {
            return BA_BACKEND_AVX512;
        }
        if (__builtin_cpu_supports("avx2")) {
            return BA_BACKEND_AVX2;
        }
    #elif defined(_MSC_VER)
        // MSVC: use __cpuid intrinsic
        #include <intrin.h>
        int info[4];
        __cpuidex(info, 7, 0);
        if (info[1] & (1 << 16)) return BA_BACKEND_AVX512; // AVX-512F
        if (info[1] & (1 << 5))  return BA_BACKEND_AVX2;
    #endif
#endif

#if defined(_OPENMP)
    return BA_BACKEND_OPENMP;
#endif

    return BA_BACKEND_SCALAR;
}

} // namespace ba
