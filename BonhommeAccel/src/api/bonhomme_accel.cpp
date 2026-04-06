/*
 * bonhomme_accel.cpp — C API implementation.
 *
 * Thin shim that validates parameters, dispatches to the appropriate
 * backend via ba::get_backend(), and translates C++ results to C structs.
 *
 * Phase 1: all backends dispatch to scalar core::* functions.
 * Phases 2-4: SIMD/Metal/CUDA/ROCm backends added via switch(backend).
 */

#include "BonhommeAccel.h"
#include "../dispatch/backend.h"
#include "../core/entropy.h"
#include "../core/correlation.h"
#include "../core/statistics.h"
#include "../core/incomplete_beta.h"
#include "../core/pairwise.h"

// ═══════════════════════════════════════════════════════════════════════════
// Version
// ═══════════════════════════════════════════════════════════════════════════

const char* ba_version(void) {
    return "1.0.0";
}

// ═══════════════════════════════════════════════════════════════════════════
// Backend Management
// ═══════════════════════════════════════════════════════════════════════════

BABackend ba_detect_best_backend(void) {
    return ba::get_backend();
}

BABackend ba_get_active_backend(void) {
    return ba::get_backend();
}

const char* ba_backend_name(BABackend backend) {
    switch (backend) {
        case BA_BACKEND_SCALAR:  return "Scalar";
        case BA_BACKEND_NEON:    return "NEON";
        case BA_BACKEND_AVX2:    return "AVX2";
        case BA_BACKEND_AVX512:  return "AVX-512";
        case BA_BACKEND_OPENMP:  return "OpenMP";
        case BA_BACKEND_METAL:   return "Metal";
        case BA_BACKEND_CUDA:    return "CUDA";
        case BA_BACKEND_ROCM:    return "ROCm";
        default:                 return "Unknown";
    }
}

const char* ba_status_string(BAStatus status) {
    switch (status) {
        case BA_OK:                      return "OK";
        case BA_ERR_NULL_PTR:            return "Null pointer";
        case BA_ERR_INSUFFICIENT_DATA:   return "Insufficient data";
        case BA_ERR_SIZE_MISMATCH:       return "Size mismatch";
        case BA_ERR_INVALID_PARAM:       return "Invalid parameter";
        case BA_ERR_BACKEND_UNAVAILABLE: return "Backend unavailable";
        case BA_ERR_ALLOC_FAILED:        return "Allocation failed";
        default:                         return "Unknown error";
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shannon Entropy — Single
// ═══════════════════════════════════════════════════════════════════════════

BAStatus ba_shannon_entropy(
    const double* values, size_t count,
    int bin_count,
    double* out_entropy
) {
    if (!values || !out_entropy) return BA_ERR_NULL_PTR;
    if (count < 2) return BA_ERR_INSUFFICIENT_DATA;
    if (bin_count < 1) return BA_ERR_INVALID_PARAM;

    // Dispatch to backend (Phase 1: all go to scalar core)
    *out_entropy = ba::core::shannon_entropy(values, count, bin_count);
    return BA_OK;
}

BAStatus ba_circular_shannon_entropy(
    const double* angles, size_t count,
    int bin_count,
    double* out_entropy
) {
    if (!angles || !out_entropy) return BA_ERR_NULL_PTR;
    if (count < 2) return BA_ERR_INSUFFICIENT_DATA;
    if (bin_count < 1) return BA_ERR_INVALID_PARAM;

    *out_entropy = ba::core::circular_shannon_entropy(angles, count, bin_count);
    return BA_OK;
}

BAStatus ba_shannon_entropy_fixed(
    const double* values, size_t count,
    int bin_count,
    double domain_min, double domain_max,
    double* out_entropy
) {
    if (!values || !out_entropy) return BA_ERR_NULL_PTR;
    if (count < 2) return BA_ERR_INSUFFICIENT_DATA;
    if (bin_count < 1 || domain_max <= domain_min) return BA_ERR_INVALID_PARAM;

    *out_entropy = ba::core::shannon_entropy_fixed(values, count, bin_count,
                                                    domain_min, domain_max);
    return BA_OK;
}

// ═══════════════════════════════════════════════════════════════════════════
// Shannon Entropy — Batch
// ═══════════════════════════════════════════════════════════════════════════

BAStatus ba_shannon_entropy_batch(
    const double* values_flat,
    const size_t* offsets,
    const size_t* lengths,
    size_t batch_count,
    int bin_count,
    double* out_entropies
) {
    if (!values_flat || !offsets || !lengths || !out_entropies) return BA_ERR_NULL_PTR;
    if (batch_count == 0) return BA_ERR_INSUFFICIENT_DATA;
    if (bin_count < 1) return BA_ERR_INVALID_PARAM;

    ba::core::shannon_entropy_batch(values_flat, offsets, lengths,
                                     batch_count, bin_count, out_entropies);
    return BA_OK;
}

BAStatus ba_circular_shannon_entropy_batch(
    const double* values_flat,
    const size_t* offsets,
    const size_t* lengths,
    size_t batch_count,
    int bin_count,
    double* out_entropies
) {
    if (!values_flat || !offsets || !lengths || !out_entropies) return BA_ERR_NULL_PTR;
    if (batch_count == 0) return BA_ERR_INSUFFICIENT_DATA;
    if (bin_count < 1) return BA_ERR_INVALID_PARAM;

    ba::core::circular_shannon_entropy_batch(values_flat, offsets, lengths,
                                              batch_count, bin_count, out_entropies);
    return BA_OK;
}

// ═══════════════════════════════════════════════════════════════════════════
// Correlation & Regression
// ═══════════════════════════════════════════════════════════════════════════

BAStatus ba_pearson_correlation(
    const double* x, const double* y, size_t count,
    double* out_r
) {
    if (!x || !y || !out_r) return BA_ERR_NULL_PTR;
    if (count < 2) return BA_ERR_INSUFFICIENT_DATA;

    *out_r = ba::core::pearson_correlation(x, y, count);
    return BA_OK;
}

BAStatus ba_linear_regression(
    const double* x, const double* y, size_t count,
    double* out_slope, double* out_intercept, double* out_mae
) {
    if (!x || !y || !out_slope || !out_intercept || !out_mae) return BA_ERR_NULL_PTR;
    if (count < 2) return BA_ERR_INSUFFICIENT_DATA;

    auto result = ba::core::linear_regression(x, y, count);
    *out_slope = result.slope;
    *out_intercept = result.intercept;
    *out_mae = result.mae;
    return BA_OK;
}

// ═══════════════════════════════════════════════════════════════════════════
// Descriptive Statistics
// ═══════════════════════════════════════════════════════════════════════════

BAStatus ba_descriptive_stats(
    const double* values, size_t count,
    double* out_mean, double* out_sd
) {
    if (!values || !out_mean || !out_sd) return BA_ERR_NULL_PTR;
    if (count < 1) return BA_ERR_INSUFFICIENT_DATA;

    auto stats = ba::core::descriptive_stats(values, count);
    *out_mean = stats.mean;
    *out_sd = stats.sd;
    return BA_OK;
}

BAStatus ba_zscore_outliers(
    const double* values, size_t count,
    double threshold,
    int32_t* out_outlier_flags
) {
    if (!values || !out_outlier_flags) return BA_ERR_NULL_PTR;
    if (count < 2) return BA_ERR_INSUFFICIENT_DATA;
    if (threshold <= 0.0) return BA_ERR_INVALID_PARAM;

    ba::core::zscore_outliers(values, count, threshold, out_outlier_flags);
    return BA_OK;
}

// ═══════════════════════════════════════════════════════════════════════════
// Pairwise Scoring
// ═══════════════════════════════════════════════════════════════════════════

BAStatus ba_pairwise_scores(
    const void* data,
    size_t n,
    size_t stride,
    BAPairwiseScoreFn score_fn,
    void* user_data,
    double* out_scores
) {
    if (!data || !score_fn || !out_scores) return BA_ERR_NULL_PTR;
    if (n < 2) return BA_ERR_INSUFFICIENT_DATA;
    if (stride == 0) return BA_ERR_INVALID_PARAM;

    ba::core::pairwise_scores(data, n, stride, score_fn, user_data, out_scores);
    return BA_OK;
}

// ═══════════════════════════════════════════════════════════════════════════
// Special Functions
// ═══════════════════════════════════════════════════════════════════════════

BAStatus ba_regularized_incomplete_beta(
    double x, double a, double b,
    double* out_result
) {
    if (!out_result) return BA_ERR_NULL_PTR;
    if (a <= 0.0 || b <= 0.0) return BA_ERR_INVALID_PARAM;
    if (x < 0.0 || x > 1.0) return BA_ERR_INVALID_PARAM;

    *out_result = ba::core::regularized_incomplete_beta(x, a, b);
    return BA_OK;
}

BAStatus ba_pearson_pvalue(
    double r, size_t n,
    double* out_pval
) {
    if (!out_pval) return BA_ERR_NULL_PTR;
    if (n <= 2) return BA_ERR_INSUFFICIENT_DATA;

    *out_pval = ba::core::pearson_pvalue(r, n);
    return BA_OK;
}
