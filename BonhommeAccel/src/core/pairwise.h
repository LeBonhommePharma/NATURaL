/*
 * pairwise.h — O(n^2) pairwise interaction scoring.
 *
 * Mirrors PolypharmacologyAnalyzer.swift's findSynergyPairs() and riskScore().
 * Scalar backend iterates upper triangle; GPU backends parallelize.
 */

#ifndef BA_CORE_PAIRWISE_H
#define BA_CORE_PAIRWISE_H

#include "BonhommeAccel.h"
#include <cstddef>

namespace ba::core {

/**
 * Compute all-pairs upper-triangular scores.
 * out_scores has n*(n-1)/2 elements in row-major upper-triangle order.
 */
void pairwise_scores(const void* data, size_t n, size_t stride,
                     BAPairwiseScoreFn score_fn, void* user_data,
                     double* out_scores);

} // namespace ba::core

#endif // BA_CORE_PAIRWISE_H
