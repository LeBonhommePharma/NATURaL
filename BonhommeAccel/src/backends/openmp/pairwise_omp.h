/*
 * pairwise_omp.h — OpenMP-parallelized pairwise scoring.
 */

#ifndef BA_PAIRWISE_OMP_H
#define BA_PAIRWISE_OMP_H

#include "../../include/BonhommeAccel.h"
#include <cstddef>

namespace ba::omp {

void pairwise_scores_omp(const void* data, size_t n, size_t stride,
                         BAPairwiseScoreFn score_fn, void* user_data,
                         double* out_scores);

} // namespace ba::omp

#endif // BA_PAIRWISE_OMP_H
