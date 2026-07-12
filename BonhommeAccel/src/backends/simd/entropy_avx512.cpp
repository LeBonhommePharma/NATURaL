/*
 * entropy_avx512.cpp — AVX-512-accelerated Shannon entropy.
 *
 * Uses 512-bit SIMD (8-wide double) for vectorized min/max and circular wrap.
 * Histogram binning remains scalar (irregular memory access pattern).
 * Mathematical parity with scalar/AVX2: NaN filter, circular wrap to [-180, 180).
 */

#if defined(__AVX512F__)

#include <immintrin.h>
#include <cmath>
#include <cstddef>
#include <vector>
#include <algorithm>
#include <limits>

namespace ba::simd {

static inline double hmin_pd(__m512d v) {
    __m256d lo = _mm512_castpd512_pd256(v);
    __m256d hi = _mm512_extractf64x4_pd(v, 1);
    __m256d m256 = _mm256_min_pd(lo, hi);
    __m128d lo128 = _mm256_castpd256_pd128(m256);
    __m128d hi128 = _mm256_extractf128_pd(m256, 1);
    __m128d m = _mm_min_pd(lo128, hi128);
    __m128d m2 = _mm_min_pd(m, _mm_permute_pd(m, 1));
    return _mm_cvtsd_f64(m2);
}

static inline double hmax_pd(__m512d v) {
    __m256d lo = _mm512_castpd512_pd256(v);
    __m256d hi = _mm512_extractf64x4_pd(v, 1);
    __m256d m256 = _mm256_max_pd(lo, hi);
    __m128d lo128 = _mm256_castpd256_pd128(m256);
    __m128d hi128 = _mm256_extractf128_pd(m256, 1);
    __m128d m = _mm_max_pd(lo128, hi128);
    __m128d m2 = _mm_max_pd(m, _mm_permute_pd(m, 1));
    return _mm_cvtsd_f64(m2);
}

double shannon_entropy_avx512(const double* values, size_t count, int bin_count) {
    if (!values || count < 2 || bin_count < 1) return 0.0;

    // Single pass min/max without allocating a cleaned copy.
    double min_val = std::numeric_limits<double>::max();
    double max_val = std::numeric_limits<double>::lowest();
    size_t clean_count = 0;

    size_t simd_end = (count / 8) * 8;
    __m512d vmin = _mm512_set1_pd(std::numeric_limits<double>::max());
    __m512d vmax = _mm512_set1_pd(std::numeric_limits<double>::lowest());
    bool any_simd_finite = false;

    for (size_t i = 0; i < simd_end; i += 8) {
        bool all_finite = true;
        for (int k = 0; k < 8; ++k) {
            double v = values[i + static_cast<size_t>(k)];
            if (!std::isfinite(v)) {
                all_finite = false;
            } else {
                ++clean_count;
                min_val = std::min(min_val, v);
                max_val = std::max(max_val, v);
            }
        }
        // Vector min/max only for all-finite lanes (NaN poisons _mm512_min_pd).
        if (all_finite) {
            __m512d v = _mm512_loadu_pd(&values[i]);
            vmin = _mm512_min_pd(vmin, v);
            vmax = _mm512_max_pd(vmax, v);
            any_simd_finite = true;
        }
    }

    if (any_simd_finite) {
        min_val = std::min(min_val, hmin_pd(vmin));
        max_val = std::max(max_val, hmax_pd(vmax));
    }

    for (size_t i = simd_end; i < count; ++i) {
        double v = values[i];
        if (!std::isfinite(v)) continue;
        ++clean_count;
        min_val = std::min(min_val, v);
        max_val = std::max(max_val, v);
    }

    if (clean_count < 2) return 0.0;

    double range = max_val - min_val;
    if (range <= 0.0) return 0.0;

    double bin_width = range / static_cast<double>(bin_count);

    std::vector<int> bins(static_cast<size_t>(bin_count), 0);
    for (size_t i = 0; i < count; ++i) {
        double v = values[i];
        if (!std::isfinite(v)) continue;
        int idx = static_cast<int>((v - min_val) / bin_width);
        if (idx < 0) idx = 0;
        if (idx >= bin_count) idx = bin_count - 1;
        bins[static_cast<size_t>(idx)]++;
    }

    double total = static_cast<double>(clean_count);
    double entropy = 0.0;
    for (int i = 0; i < bin_count; ++i) {
        if (bins[static_cast<size_t>(i)] > 0) {
            double p = static_cast<double>(bins[static_cast<size_t>(i)]) / total;
            entropy -= p * std::log2(p);
        }
    }

    return entropy;
}

double circular_shannon_entropy_avx512(const double* angles, size_t count, int bin_count) {
    if (!angles || count < 2 || bin_count < 1) return 0.0;

    size_t clean_count = 0;
    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(angles[i])) ++clean_count;
    }
    if (clean_count < 2) return 0.0;

    double bin_width = 360.0 / static_cast<double>(bin_count);
    std::vector<int> bins(static_cast<size_t>(bin_count), 0);

    // Vectorized wrapping with AVX-512 (8-wide)
    __m512d v360 = _mm512_set1_pd(360.0);
    __m512d v180 = _mm512_set1_pd(180.0);
    __m512d vn180 = _mm512_set1_pd(-180.0);
    __m512d vbin_width = _mm512_set1_pd(bin_width);
    __m512d vzero = _mm512_setzero_pd();
    __m512d vmax_idx = _mm512_set1_pd(static_cast<double>(bin_count - 1));

    size_t simd_end = (count / 8) * 8;
    for (size_t i = 0; i < simd_end; i += 8) {
        // Check for non-finite and fall back to scalar if needed
        bool has_nonfinite = false;
        for (int k = 0; k < 8; ++k) {
            if (!std::isfinite(angles[i + static_cast<size_t>(k)])) {
                has_nonfinite = true;
                break;
            }
        }
        if (has_nonfinite) {
            for (int k = 0; k < 8; ++k) {
                double a = angles[i + static_cast<size_t>(k)];
                if (!std::isfinite(a)) continue;
                a = std::fmod(a, 360.0);
                if (a > 180.0) a -= 360.0;
                if (a < -180.0) a += 360.0;
                int idx = static_cast<int>((a + 180.0) / bin_width);
                if (idx < 0) idx = 0;
                if (idx >= bin_count) idx = bin_count - 1;
                bins[static_cast<size_t>(idx)]++;
            }
            continue;
        }

        __m512d a = _mm512_loadu_pd(&angles[i]);

        // fmod: a - floor(a/360) * 360
        __m512d ratio = _mm512_div_pd(a, v360);
        __m512d floored = _mm512_floor_pd(ratio);
        a = _mm512_fnmadd_pd(floored, v360, a);

        // Wrap to [-180, 180)
        __mmask8 gt180 = _mm512_cmp_pd_mask(a, v180, _CMP_GT_OQ);
        a = _mm512_mask_sub_pd(a, gt180, a, v360);
        __mmask8 ltn180 = _mm512_cmp_pd_mask(a, vn180, _CMP_LT_OQ);
        a = _mm512_mask_add_pd(a, ltn180, a, v360);

        // Bin index
        __m512d shifted = _mm512_add_pd(a, v180);
        __m512d fidx = _mm512_div_pd(shifted, vbin_width);
        fidx = _mm512_floor_pd(fidx);
        fidx = _mm512_max_pd(fidx, vzero);
        fidx = _mm512_min_pd(fidx, vmax_idx);

        alignas(64) double idx_arr[8];
        _mm512_store_pd(idx_arr, fidx);
        for (int k = 0; k < 8; ++k) {
            bins[static_cast<size_t>(static_cast<int>(idx_arr[k]))]++;
        }
    }

    for (size_t i = simd_end; i < count; ++i) {
        double a = angles[i];
        if (!std::isfinite(a)) continue;
        a = std::fmod(a, 360.0);
        if (a > 180.0) a -= 360.0;
        if (a < -180.0) a += 360.0;
        int idx = static_cast<int>((a + 180.0) / bin_width);
        if (idx < 0) idx = 0;
        if (idx >= bin_count) idx = bin_count - 1;
        bins[static_cast<size_t>(idx)]++;
    }

    double total = static_cast<double>(clean_count);
    double entropy = 0.0;
    for (int i = 0; i < bin_count; ++i) {
        if (bins[static_cast<size_t>(i)] > 0) {
            double p = static_cast<double>(bins[static_cast<size_t>(i)]) / total;
            entropy -= p * std::log2(p);
        }
    }

    return entropy;
}

void shannon_entropy_batch_avx512(const double* flat, const size_t* offsets,
                                   const size_t* lengths, size_t batch_count,
                                   int bin_count, double* out) {
    for (size_t b = 0; b < batch_count; ++b) {
        out[b] = shannon_entropy_avx512(flat + offsets[b], lengths[b], bin_count);
    }
}

} // namespace ba::simd

#endif // __AVX512F__
