/*
 * correlation_simd.h — Declarations for NEON/AVX2 Pearson correlation kernels.
 */

#ifndef BA_CORRELATION_SIMD_H
#define BA_CORRELATION_SIMD_H

#include <cstddef>

namespace ba::simd {

#if defined(BA_HAS_AVX2)
double pearson_correlation_avx2(const double* x, const double* y, size_t count);
#endif

#if defined(BA_HAS_NEON)
double pearson_correlation_neon(const double* x, const double* y, size_t count);
#endif

} // namespace ba::simd

#endif // BA_CORRELATION_SIMD_H
