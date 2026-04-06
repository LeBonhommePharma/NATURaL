/*
 * entropy_omp.cpp — OpenMP-parallelized batch Shannon entropy.
 *
 * Each batch element is independent, so we parallelize across the batch
 * dimension with #pragma omp parallel for.
 */

#include "../../core/entropy.h"
#include <cstddef>

#if defined(_OPENMP)
#include <omp.h>
#endif

namespace ba::omp {

void shannon_entropy_batch_omp(const double* flat, const size_t* offsets,
                                const size_t* lengths, size_t batch_count,
                                int bin_count, double* out) {
#if defined(_OPENMP)
    #pragma omp parallel for schedule(dynamic)
    for (size_t b = 0; b < batch_count; ++b) {
        out[b] = ba::core::shannon_entropy(flat + offsets[b], lengths[b], bin_count);
    }
#else
    ba::core::shannon_entropy_batch(flat, offsets, lengths, batch_count, bin_count, out);
#endif
}

void circular_shannon_entropy_batch_omp(const double* flat, const size_t* offsets,
                                         const size_t* lengths, size_t batch_count,
                                         int bin_count, double* out) {
#if defined(_OPENMP)
    #pragma omp parallel for schedule(dynamic)
    for (size_t b = 0; b < batch_count; ++b) {
        out[b] = ba::core::circular_shannon_entropy(flat + offsets[b], lengths[b], bin_count);
    }
#else
    ba::core::circular_shannon_entropy_batch(flat, offsets, lengths, batch_count, bin_count, out);
#endif
}

} // namespace ba::omp
