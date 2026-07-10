/*
 * pairwise_omp.cpp — OpenMP-parallelized O(n^2) pairwise scoring.
 *
 * Parallelizes the outer loop of the upper-triangle traversal.
 */

#include "pairwise_omp.h"
#include <cstddef>
#include <cstdint>

#if defined(_OPENMP)
#include <omp.h>
#endif

namespace ba::omp {

void pairwise_scores_omp(const void* data, size_t n, size_t stride,
                          BAPairwiseScoreFn score_fn, void* user_data,
                          double* out_scores) {
    if (!data || !score_fn || !out_scores || n < 2) return;

    const auto* bytes = static_cast<const uint8_t*>(data);

#if defined(_OPENMP)
    // Upper-triangle row i starts at: sum_{k=0}^{i-1} (n-1-k) = i*n - i*(i+1)/2
    #pragma omp parallel for schedule(dynamic)
    for (size_t i = 0; i < n; ++i) {
        size_t base_idx = i * n - i * (i + 1) / 2;
        for (size_t j = i + 1; j < n; ++j) {
            size_t idx = base_idx + (j - i - 1);
            const void* s1 = bytes + i * stride;
            const void* s2 = bytes + j * stride;
            out_scores[idx] = score_fn(s1, s2, user_data);
        }
    }
#else
    size_t idx = 0;
    for (size_t i = 0; i < n; ++i) {
        for (size_t j = i + 1; j < n; ++j) {
            const void* s1 = bytes + i * stride;
            const void* s2 = bytes + j * stride;
            out_scores[idx++] = score_fn(s1, s2, user_data);
        }
    }
#endif
}

} // namespace ba::omp
