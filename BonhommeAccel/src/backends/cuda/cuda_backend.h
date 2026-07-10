/*
 * cuda_backend.h — Public C++ API for the NVIDIA CUDA backend.
 *
 * Implemented in entropy_cuda.cu / correlation_cuda.cu / pairwise_cuda.cu.
 * Available only when BA_HAS_CUDA is defined.
 */

#ifndef BA_CUDA_BACKEND_H
#define BA_CUDA_BACKEND_H

#include <cstddef>
#include "../../include/BonhommeAccel.h"

namespace ba::cuda {

/** True if at least one CUDA device is present and usable. */
bool cuda_is_available();

double shannon_entropy_cuda(const double* values, size_t count, int bin_count);
double circular_shannon_entropy_cuda(const double* angles, size_t count, int bin_count);

void shannon_entropy_batch_cuda(const double* flat, const size_t* offsets,
                                 const size_t* lengths, size_t batch_count,
                                 int bin_count, double* out_entropies);

void circular_shannon_entropy_batch_cuda(const double* flat, const size_t* offsets,
                                          const size_t* lengths, size_t batch_count,
                                          int bin_count, double* out_entropies);

/** Pearson r; filters non-finite pairs on host before device reduction. */
double pearson_correlation_cuda(const double* x, const double* y, size_t count);

/**
 * Pairwise scores with host callback (custom BAPairwiseScoreFn cannot run
 * on device). Retained for API symmetry; equivalent to scalar traversal.
 */
void pairwise_scores_cuda(const void* data, size_t n, size_t stride,
                          BAPairwiseScoreFn score_fn, void* user_data,
                          double* out_scores);

} // namespace ba::cuda

#endif // BA_CUDA_BACKEND_H
