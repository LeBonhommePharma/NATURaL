/*
 * pairwise.cpp — Scalar O(n^2) pairwise interaction scoring.
 */

#include "pairwise.h"

#include <cstdint>

namespace ba::core {

void pairwise_scores(const void* data, size_t n, size_t stride,
                     BAPairwiseScoreFn score_fn, void* user_data,
                     double* out_scores) {
    if (!data || !score_fn || !out_scores || n < 2) return;

    const auto* bytes = static_cast<const uint8_t*>(data);
    size_t idx = 0;

    for (size_t i = 0; i < n; ++i) {
        for (size_t j = i + 1; j < n; ++j) {
            const void* s1 = bytes + i * stride;
            const void* s2 = bytes + j * stride;
            out_scores[idx++] = score_fn(s1, s2, user_data);
        }
    }
}

} // namespace ba::core
