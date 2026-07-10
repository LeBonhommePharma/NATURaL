/*
 * metal_backend.h — Public C++ API for the Apple Metal compute backend.
 *
 * Implemented in metal_runtime.mm / entropy_metal.mm /
 * correlation_metal.mm / pairwise_metal.mm.
 * Available only when BA_HAS_METAL is defined (Apple + BA_ENABLE_METAL).
 *
 * Note: MSL kernels use float32 (Apple GPUs lack double). Histogram bins
 * remain exact integers; entropy is reduced on the host in double.
 */

#ifndef BA_METAL_BACKEND_H
#define BA_METAL_BACKEND_H

#include <cstddef>

namespace ba::metal {

/** True if a Metal device + command queue are available. */
bool metal_is_available();

double shannon_entropy_metal(const double* values, size_t count, int bin_count);
double circular_shannon_entropy_metal(const double* angles, size_t count, int bin_count);

void shannon_entropy_batch_metal(const double* flat, const size_t* offsets,
                                  const size_t* lengths, size_t batch_count,
                                  int bin_count, double* out_entropies);

void circular_shannon_entropy_batch_metal(const double* flat, const size_t* offsets,
                                           const size_t* lengths, size_t batch_count,
                                           int bin_count, double* out_entropies);

/**
 * Pearson r via float32 GPU reduction.
 * Returns a value in [-1, 1], or NaN on GPU failure (caller falls back).
 */
double pearson_correlation_metal(const double* x, const double* y, size_t count);

/** Upper-triangle |x_i - x_j| for double arrays (converted to float on GPU). */
void pairwise_abs_diff_metal(const double* data, size_t n, double* out_scores);

} // namespace ba::metal

#endif // BA_METAL_BACKEND_H
