/*
 * entropy.h — Shannon entropy computation (scalar backend).
 *
 * Implements the identical algorithm as BonhommeCore's EntropyCalculator.swift:
 *   H = -Sum p_i * log2(p_i) over histogram-binned distributions.
 *
 * Three variants:
 *   - Adaptive (data-driven bin range)
 *   - Circular (fixed [-180, 180) for torsional angles)
 *   - Fixed domain (caller-specified bounds)
 *
 * Plus batch versions for GPU/SIMD amortization.
 */

#ifndef BA_CORE_ENTROPY_H
#define BA_CORE_ENTROPY_H

#include <cstddef>
#include <span>

namespace ba::core {

/**
 * Shannon entropy with adaptive bin range [min, max].
 * Filters non-finite values. Returns 0 if < 2 finite values.
 */
double shannon_entropy(const double* values, size_t count, int bin_count);

/**
 * Circular Shannon entropy for angles in degrees.
 * Fixed bins [-180, 180). Wraps values outside this range.
 * Filters non-finite values.
 */
double circular_shannon_entropy(const double* angles, size_t count, int bin_count);

/**
 * Shannon entropy with fixed domain [domain_min, domain_max].
 * Clamps values to domain. Does NOT filter NaN/Inf.
 */
double shannon_entropy_fixed(const double* values, size_t count, int bin_count,
                              double domain_min, double domain_max);

/**
 * Batch adaptive Shannon entropy.
 * Each sub-array is at values_flat[offsets[i]] with lengths[i] elements.
 */
void shannon_entropy_batch(const double* values_flat,
                            const size_t* offsets, const size_t* lengths,
                            size_t batch_count, int bin_count,
                            double* out_entropies);

/**
 * Batch circular Shannon entropy.
 */
void circular_shannon_entropy_batch(const double* values_flat,
                                     const size_t* offsets, const size_t* lengths,
                                     size_t batch_count, int bin_count,
                                     double* out_entropies);

} // namespace ba::core

#endif // BA_CORE_ENTROPY_H
