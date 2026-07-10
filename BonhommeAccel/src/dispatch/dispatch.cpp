/*
 * dispatch.cpp — Runtime backend detection.
 *
 * Probes GPU (CUDA, ROCm, Metal), then CPU SIMD (NEON, AVX2), then OpenMP.
 * Only backends with compiled kernels and a live device are advertised.
 */

#include "backend.h"

#if defined(BA_HAS_CUDA)
#include "../backends/cuda/cuda_backend.h"
#endif
#if defined(BA_HAS_ROCM)
#include "../backends/rocm/rocm_backend.h"
#endif
#if defined(BA_HAS_METAL)
#include "../backends/metal/metal_backend.h"
#endif

namespace ba {

BABackend probe_best_backend() {
    // Detection order: GPU (when kernels + device exist) > SIMD > OpenMP > Scalar

#if defined(BA_HAS_CUDA)
    if (ba::cuda::cuda_is_available()) {
        return BA_BACKEND_CUDA;
    }
#endif

#if defined(BA_HAS_ROCM)
    if (ba::rocm::hip_is_available()) {
        return BA_BACKEND_ROCM;
    }
#endif

#if defined(BA_HAS_METAL)
    if (ba::metal::metal_is_available()) {
        return BA_BACKEND_METAL;
    }
#endif

    // SIMD — only advertise backends that have compiled kernels.
    // AVX-512 is not claimed without dedicated kernels.
#if defined(BA_HAS_NEON) && (defined(__aarch64__) || defined(_M_ARM64))
    return BA_BACKEND_NEON;
#elif defined(BA_HAS_AVX2) && (defined(__x86_64__) || defined(_M_X64))
    #if defined(__GNUC__) || defined(__clang__)
        __builtin_cpu_init();
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
