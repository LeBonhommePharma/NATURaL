/*
 * entropy_simd.h — Declarations for NEON/AVX2 Shannon entropy kernels.
 */

#ifndef BA_ENTROPY_SIMD_H
#define BA_ENTROPY_SIMD_H

#include <cstddef>

namespace ba::simd {

#if defined(BA_HAS_NEON)
double shannon_entropy_neon(const double* values, size_t count, int bin_count);
double circular_shannon_entropy_neon(const double* angles, size_t count, int bin_count);
double shannon_entropy_fixed_neon(const double* values, size_t count, int bin_count,
                                   double domain_min, double domain_max);
#endif

#if defined(BA_HAS_AVX2)
double shannon_entropy_avx2(const double* values, size_t count, int bin_count);
double circular_shannon_entropy_avx2(const double* angles, size_t count, int bin_count);
double shannon_entropy_fixed_avx2(const double* values, size_t count, int bin_count,
                                   double domain_min, double domain_max);
void shannon_entropy_batch_avx2(const double* flat, const size_t* offsets,
                                 const size_t* lengths, size_t batch_count,
                                 int bin_count, double* out);
#endif

} // namespace ba::simd

#endif // BA_ENTROPY_SIMD_H
