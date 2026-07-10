/*
 * rocm_backend.h — Public C++ API for the AMD ROCm/HIP backend.
 *
 * Implemented in entropy_hip.cpp. Available only when BA_HAS_ROCM is defined.
 */

#ifndef BA_ROCM_BACKEND_H
#define BA_ROCM_BACKEND_H

#include <cstddef>

namespace ba::rocm {

/** True if at least one HIP device is present and usable. */
bool hip_is_available();

double shannon_entropy_hip(const double* values, size_t count, int bin_count);
double circular_shannon_entropy_hip(const double* angles, size_t count, int bin_count);

void shannon_entropy_batch_hip(const double* flat, const size_t* offsets,
                                const size_t* lengths, size_t batch_count,
                                int bin_count, double* out_entropies);

void circular_shannon_entropy_batch_hip(const double* flat, const size_t* offsets,
                                         const size_t* lengths, size_t batch_count,
                                         int bin_count, double* out_entropies);

double pearson_correlation_hip(const double* x, const double* y, size_t count);

} // namespace ba::rocm

#endif // BA_ROCM_BACKEND_H
