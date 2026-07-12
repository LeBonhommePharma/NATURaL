/*
 * entropy_omp.cpp — OpenMP-parallelized batch Shannon entropy.
 *
 * Each batch element is independent, so we parallelize across the batch
 * dimension with #pragma omp parallel for. Per-item work uses SIMD kernels
 * when compiled in (NEON/AVX2), else scalar core.
 */

#include "../../core/entropy.h"
#include <cstddef>

#if defined(BA_HAS_NEON) || defined(BA_HAS_AVX2)
#include "../simd/entropy_simd.h"
#endif

#if defined(_OPENMP)
#include <omp.h>
#endif

namespace ba::omp {

static inline double item_shannon(const double* values, size_t count, int bin_count) {
#if defined(BA_HAS_NEON)
    return ba::simd::shannon_entropy_neon(values, count, bin_count);
#elif defined(BA_HAS_AVX2)
    return ba::simd::shannon_entropy_avx2(values, count, bin_count);
#else
    return ba::core::shannon_entropy(values, count, bin_count);
#endif
}

static inline double item_circular(const double* angles, size_t count, int bin_count) {
#if defined(BA_HAS_NEON)
    return ba::simd::circular_shannon_entropy_neon(angles, count, bin_count);
#elif defined(BA_HAS_AVX2)
    return ba::simd::circular_shannon_entropy_avx2(angles, count, bin_count);
#else
    return ba::core::circular_shannon_entropy(angles, count, bin_count);
#endif
}

void shannon_entropy_batch_omp(const double* flat, const size_t* offsets,
                                const size_t* lengths, size_t batch_count,
                                int bin_count, double* out) {
#if defined(_OPENMP)
    #pragma omp parallel for schedule(dynamic)
    for (size_t b = 0; b < batch_count; ++b) {
        out[b] = item_shannon(flat + offsets[b], lengths[b], bin_count);
    }
#else
    for (size_t b = 0; b < batch_count; ++b) {
        out[b] = item_shannon(flat + offsets[b], lengths[b], bin_count);
    }
#endif
}

void circular_shannon_entropy_batch_omp(const double* flat, const size_t* offsets,
                                         const size_t* lengths, size_t batch_count,
                                         int bin_count, double* out) {
#if defined(_OPENMP)
    #pragma omp parallel for schedule(dynamic)
    for (size_t b = 0; b < batch_count; ++b) {
        out[b] = item_circular(flat + offsets[b], lengths[b], bin_count);
    }
#else
    for (size_t b = 0; b < batch_count; ++b) {
        out[b] = item_circular(flat + offsets[b], lengths[b], bin_count);
    }
#endif
}

} // namespace ba::omp
