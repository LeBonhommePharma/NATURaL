/*
 * BonhommeAccel.h — C API for the BonhommeAccel GPU/SIMD compute library.
 *
 * Production-grade Shannon entropy, correlation, statistics, and pairwise
 * interaction scoring with multi-backend dispatch:
 *   Metal (Apple GPU) | CUDA (NVIDIA) | ROCm/HIP (AMD) |
 *   AVX2/AVX-512 (x86 SIMD) | NEON (ARM SIMD) | OpenMP (CPU threads) | Scalar
 *
 * Thread-safe, stateless API. All functions take caller-owned buffers.
 * Runtime backend detection via ba_detect_best_backend() (GPU → SIMD → OpenMP → Scalar).
 * Metal MSL kernels use float32 (Apple GPU constraint); CUDA/ROCm use double.
 * GPU failures fall back to SIMD/scalar automatically.
 *
 * Ported from BonhommeCore's Swift EntropyCalculator for mathematical parity
 * with FlexAIDdS molecular docking entropy and NATURaL HRV entropy.
 *
 * Copyright (c) 2024-2026 NATURaL / Bonhomme Project. All rights reserved.
 */

#ifndef BONHOMME_ACCEL_H
#define BONHOMME_ACCEL_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ═══════════════════════════════════════════════════════════════════════════
 * Backend Management
 * ═══════════════════════════════════════════════════════════════════════════ */

typedef enum BABackend {
    BA_BACKEND_SCALAR  = 0,   /* Plain C++ — always available                   */
    BA_BACKEND_NEON    = 1,   /* ARM NEON SIMD (Apple Silicon, ARM64)           */
    BA_BACKEND_AVX2    = 2,   /* x86 AVX2 (256-bit SIMD)                       */
    BA_BACKEND_AVX512  = 3,   /* x86 AVX-512 (512-bit SIMD)                    */
    BA_BACKEND_OPENMP  = 4,   /* OpenMP CPU threading                          */
    BA_BACKEND_METAL   = 5,   /* Apple Metal GPU compute                       */
    BA_BACKEND_CUDA    = 6,   /* NVIDIA CUDA                                   */
    BA_BACKEND_ROCM    = 7,   /* AMD ROCm/HIP                                  */
} BABackend;

/**
 * Detect and return the fastest available compute backend.
 * Result is cached atomically after first call.
 * Thread-safe.
 */
BABackend ba_detect_best_backend(void);

/**
 * Get the currently active backend (after detection).
 */
BABackend ba_get_active_backend(void);

/**
 * Human-readable name for a backend (e.g., "AVX2", "Metal", "CUDA").
 * Returns a static string — do not free.
 */
const char* ba_backend_name(BABackend backend);

/**
 * Library version string (semver). Returns a static string.
 */
const char* ba_version(void);

/* ═══════════════════════════════════════════════════════════════════════════
 * Error Handling
 * ═══════════════════════════════════════════════════════════════════════════ */

typedef enum BAStatus {
    BA_OK                     =  0,
    BA_ERR_NULL_PTR           = -1,
    BA_ERR_INSUFFICIENT_DATA  = -2,
    BA_ERR_SIZE_MISMATCH      = -3,
    BA_ERR_INVALID_PARAM      = -4,
    BA_ERR_BACKEND_UNAVAILABLE = -5,
    BA_ERR_ALLOC_FAILED       = -6,
} BAStatus;

/**
 * Human-readable description for a status code.
 */
const char* ba_status_string(BAStatus status);

/* ═══════════════════════════════════════════════════════════════════════════
 * Shannon Entropy — Single Array
 * ═══════════════════════════════════════════════════════════════════════════ */

/**
 * Shannon entropy with data-adaptive bin range [min(values), max(values)].
 *
 * H = -Sum p_i * log2(p_i) for each bin with p_i > 0.
 *
 * Filters non-finite values (NaN, Inf). Returns BA_ERR_INSUFFICIENT_DATA
 * if fewer than 2 finite values remain.
 *
 * @param values    Input array of continuous values.
 * @param count     Number of elements in values.
 * @param bin_count Number of histogram bins (typically 32).
 * @param out_entropy Pointer to store result (bits). Must not be NULL.
 * @return BA_OK on success.
 */
BAStatus ba_shannon_entropy(
    const double* values, size_t count,
    int bin_count,
    double* out_entropy
);

/**
 * Shannon entropy for circular distributions (torsional angles).
 *
 * Fixed bins spanning [-180, +180). Values outside this range are wrapped
 * via modular arithmetic. This correctly handles the +-180 boundary where
 * -179 and +179 are adjacent.
 *
 * @param angles    Input array of angles in degrees.
 * @param count     Number of elements.
 * @param bin_count Number of histogram bins (typically 32).
 * @param out_entropy Pointer to store result (bits).
 * @return BA_OK on success.
 */
BAStatus ba_circular_shannon_entropy(
    const double* angles, size_t count,
    int bin_count,
    double* out_entropy
);

/**
 * Shannon entropy with caller-specified fixed domain [domain_min, domain_max].
 *
 * Values outside the domain are clamped to the nearest edge.
 * Filters non-finite values (NaN, Inf), matching the adaptive/circular paths.
 *
 * @param values     Input array.
 * @param count      Number of elements.
 * @param bin_count  Number of histogram bins.
 * @param domain_min Lower bound (inclusive).
 * @param domain_max Upper bound (inclusive).
 * @param out_entropy Result pointer.
 * @return BA_OK on success.
 */
BAStatus ba_shannon_entropy_fixed(
    const double* values, size_t count,
    int bin_count,
    double domain_min, double domain_max,
    double* out_entropy
);

/* ═══════════════════════════════════════════════════════════════════════════
 * Shannon Entropy — Batch (the key performance API)
 *
 * Computes entropy for N independent arrays in one call.
 * Data is packed into a flat buffer with per-array offsets and lengths.
 * This amortizes dispatch overhead and enables GPU parallelism.
 * ═══════════════════════════════════════════════════════════════════════════ */

/**
 * Batch linear Shannon entropy.
 *
 * @param values_flat  Flat buffer containing all arrays concatenated.
 * @param offsets      Starting index of each array within values_flat.
 * @param lengths      Number of elements in each array.
 * @param batch_count  Number of arrays (length of offsets and lengths).
 * @param bin_count    Histogram bin count (shared across all arrays).
 * @param out_entropies Output array of batch_count entropy values.
 * @return BA_OK on success.
 */
BAStatus ba_shannon_entropy_batch(
    const double* values_flat,
    const size_t* offsets,
    const size_t* lengths,
    size_t batch_count,
    int bin_count,
    double* out_entropies
);

/**
 * Batch circular Shannon entropy.
 * Same layout as ba_shannon_entropy_batch but uses circular [-180,180) bins.
 */
BAStatus ba_circular_shannon_entropy_batch(
    const double* values_flat,
    const size_t* offsets,
    const size_t* lengths,
    size_t batch_count,
    int bin_count,
    double* out_entropies
);

/* ═══════════════════════════════════════════════════════════════════════════
 * Correlation & Regression
 * ═══════════════════════════════════════════════════════════════════════════ */

/**
 * Pearson product-moment correlation coefficient.
 *
 * Filters pairs where either value is non-finite.
 * Returns 0 if fewer than 2 valid pairs or zero variance.
 *
 * @param x, y   Input arrays (must have same count).
 * @param count   Number of elements.
 * @param out_r   Pointer to store Pearson r in [-1, 1].
 * @return BA_OK on success, BA_ERR_SIZE_MISMATCH if arrays differ.
 */
BAStatus ba_pearson_correlation(
    const double* x, const double* y, size_t count,
    double* out_r
);

/**
 * Ordinary least-squares linear regression: y = slope * x + intercept.
 *
 * Also computes mean absolute error (MAE).
 *
 * @param x, y        Input arrays (same count).
 * @param count        Number of elements.
 * @param out_slope    Regression slope.
 * @param out_intercept Regression intercept.
 * @param out_mae      Mean absolute error.
 * @return BA_OK on success.
 */
BAStatus ba_linear_regression(
    const double* x, const double* y, size_t count,
    double* out_slope, double* out_intercept, double* out_mae
);

/* ═══════════════════════════════════════════════════════════════════════════
 * Descriptive Statistics
 * ═══════════════════════════════════════════════════════════════════════════ */

/**
 * Compute mean and sample standard deviation (Bessel-corrected, n-1).
 *
 * @param values   Input array.
 * @param count    Number of elements (must be >= 1 for mean, >= 2 for SD).
 * @param out_mean Pointer to store mean.
 * @param out_sd   Pointer to store SD (0 if count < 2).
 * @return BA_OK on success.
 */
BAStatus ba_descriptive_stats(
    const double* values, size_t count,
    double* out_mean, double* out_sd
);

/**
 * Compute z-scores and flag outliers where |z| > threshold.
 *
 * @param values         Input array.
 * @param count          Number of elements (must be >= 2).
 * @param threshold      Z-score threshold for outlier flagging (e.g., 2.0).
 * @param out_outlier_flags Output array of count int32_t: 1 if outlier, 0 otherwise.
 * @return BA_OK on success.
 */
BAStatus ba_zscore_outliers(
    const double* values, size_t count,
    double threshold,
    int32_t* out_outlier_flags
);

/* ═══════════════════════════════════════════════════════════════════════════
 * Pairwise Interaction Scoring (O(n^2) -> GPU parallel)
 * ═══════════════════════════════════════════════════════════════════════════ */

/**
 * Callback type for computing a pairwise interaction score.
 * Receives pointers to two elements within the data array.
 */
typedef double (*BAPairwiseScoreFn)(const void* s1, const void* s2, void* user_data);

/**
 * Compute all-pairs upper-triangular score matrix.
 *
 * For n items, produces n*(n-1)/2 scores stored in row-major
 * upper-triangle order: (0,1), (0,2), ..., (0,n-1), (1,2), ..., (n-2,n-1).
 *
 * On GPU backends, the scoring function is called on the host for each pair
 * (GPU parallelizes the dispatch). For CPU backends, OpenMP parallelizes
 * the outer loop.
 *
 * @param data          Array of n items, each `stride` bytes apart.
 * @param n             Number of items.
 * @param stride        Byte stride between consecutive items.
 * @param score_fn      Callback to compute score for a pair.
 * @param user_data     Opaque pointer passed to score_fn.
 * @param out_scores    Output buffer for n*(n-1)/2 doubles.
 * @return BA_OK on success.
 */
BAStatus ba_pairwise_scores(
    const void* data,
    size_t n,
    size_t stride,
    BAPairwiseScoreFn score_fn,
    void* user_data,
    double* out_scores
);

/* ═══════════════════════════════════════════════════════════════════════════
 * Special Functions
 * ═══════════════════════════════════════════════════════════════════════════ */

/**
 * Regularized incomplete beta function I_x(a, b).
 *
 * Uses Lentz's continued fraction algorithm (Numerical Recipes).
 * Used to convert t-statistics to p-values without external dependencies.
 *
 * @param x   Argument in [0, 1].
 * @param a   First shape parameter (> 0).
 * @param b   Second shape parameter (> 0).
 * @param out_result Pointer to store I_x(a, b).
 * @return BA_OK on success, BA_ERR_INVALID_PARAM if x/a/b out of range.
 */
BAStatus ba_regularized_incomplete_beta(
    double x, double a, double b,
    double* out_result
);

/**
 * Two-tailed p-value for Pearson correlation coefficient.
 *
 * Uses the t-distribution: t = r * sqrt(n-2) / sqrt(1 - r^2), df = n-2.
 * Computed via the regularized incomplete beta function.
 *
 * @param r        Pearson correlation coefficient.
 * @param n        Sample size (must be > 2).
 * @param out_pval Pointer to store p-value.
 * @return BA_OK on success.
 */
BAStatus ba_pearson_pvalue(
    double r, size_t n,
    double* out_pval
);

#ifdef __cplusplus
}
#endif

#endif /* BONHOMME_ACCEL_H */
