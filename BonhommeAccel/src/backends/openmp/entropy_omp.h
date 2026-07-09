/*
 * entropy_omp.h — Declarations for OpenMP batch Shannon entropy.
 */

#ifndef BA_ENTROPY_OMP_H
#define BA_ENTROPY_OMP_H

#include <cstddef>

namespace ba::omp {

void shannon_entropy_batch_omp(const double* flat, const size_t* offsets,
                                const size_t* lengths, size_t batch_count,
                                int bin_count, double* out);

void circular_shannon_entropy_batch_omp(const double* flat, const size_t* offsets,
                                         const size_t* lengths, size_t batch_count,
                                         int bin_count, double* out);

} // namespace ba::omp

#endif // BA_ENTROPY_OMP_H
