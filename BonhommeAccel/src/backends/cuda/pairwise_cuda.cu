/*
 * pairwise_cuda.cu — CUDA O(n^2) pairwise scoring.
 *
 * Custom BAPairwiseScoreFn callbacks cannot run on the device; host scoring
 * is used. This entry point is retained for API symmetry and future
 * device-side scoring kernels (e.g. abs-diff for double arrays).
 */

#if defined(BA_HAS_CUDA)

#include "cuda_backend.h"
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace ba::cuda {

void pairwise_scores_cuda(
    const void* data, size_t n, size_t stride,
    BAPairwiseScoreFn score_fn, void* user_data,
    double* out_scores
) {
    if (!data || !score_fn || !out_scores || n < 2) return;

    size_t num_pairs = n * (n - 1) / 2;
    const auto* bytes = static_cast<const uint8_t*>(data);

    for (size_t idx = 0; idx < num_pairs; ++idx) {
        double nf = static_cast<double>(n);
        double t = static_cast<double>(idx);
        size_t i = static_cast<size_t>(nf - 0.5 - std::sqrt((nf - 0.5) * (nf - 0.5) - 2.0 * t));
        size_t row_start = i * n - i * (i + 1) / 2;
        size_t j = idx - row_start + i + 1;

        if (i >= n) i = n - 2;
        if (j >= n || j <= i) j = i + 1;

        const void* s1 = bytes + i * stride;
        const void* s2 = bytes + j * stride;
        out_scores[idx] = score_fn(s1, s2, user_data);
    }
}

} // namespace ba::cuda

#endif // BA_HAS_CUDA
