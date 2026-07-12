/*
 * entropy_neon.cpp — ARM NEON-accelerated Shannon entropy.
 *
 * Uses 128-bit NEON (float64x2_t, 2-wide double) for vectorized
 * min/max finding without an intermediate clean-copy allocation.
 * Histogram and entropy reduction remain scalar (irregular bin stores).
 */

#if defined(__aarch64__)

#include <arm_neon.h>
#include <cmath>
#include <cstddef>
#include <vector>
#include <algorithm>
#include <limits>

namespace ba::simd {

double shannon_entropy_neon(const double* values, size_t count, int bin_count) {
    if (!values || count < 2 || bin_count < 1) return 0.0;

    // Single pass: count finite + min/max (NEON over all finite-aware scalar tail)
    // Avoids allocating a cleaned copy of the full input.
    double min_val = std::numeric_limits<double>::max();
    double max_val = std::numeric_limits<double>::lowest();
    size_t clean_count = 0;

    size_t simd_end = (count / 2) * 2;
    float64x2_t vmin = vdupq_n_f64(std::numeric_limits<double>::max());
    float64x2_t vmax = vdupq_n_f64(std::numeric_limits<double>::lowest());
    // Track whether any finite pair was loaded into the vector accumulators.
    bool any_simd_finite = false;

    for (size_t i = 0; i < simd_end; i += 2) {
        double a = values[i];
        double b = values[i + 1];
        const bool fa = std::isfinite(a);
        const bool fb = std::isfinite(b);
        if (fa) {
            ++clean_count;
            min_val = std::min(min_val, a);
            max_val = std::max(max_val, a);
        }
        if (fb) {
            ++clean_count;
            min_val = std::min(min_val, b);
            max_val = std::max(max_val, b);
        }
        // Vector min/max only when both finite (avoids NaN poisoning of vminq/vmaxq).
        if (fa && fb) {
            float64x2_t v = vld1q_f64(&values[i]);
            vmin = vminq_f64(vmin, v);
            vmax = vmaxq_f64(vmax, v);
            any_simd_finite = true;
        }
    }

    if (any_simd_finite) {
        min_val = std::min(min_val, std::min(vgetq_lane_f64(vmin, 0), vgetq_lane_f64(vmin, 1)));
        max_val = std::max(max_val, std::max(vgetq_lane_f64(vmax, 0), vgetq_lane_f64(vmax, 1)));
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

double circular_shannon_entropy_neon(const double* angles, size_t count, int bin_count) {
    if (!angles || count < 2 || bin_count < 1) return 0.0;

    size_t clean_count = 0;
    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(angles[i])) ++clean_count;
    }
    if (clean_count < 2) return 0.0;

    double bin_width = 360.0 / static_cast<double>(bin_count);
    std::vector<int> bins(static_cast<size_t>(bin_count), 0);

    for (size_t i = 0; i < count; ++i) {
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

// ---------------------------------------------------------------------------
// Fixed-domain Shannon entropy (NEON clamp + bin index)
//
// Semantics match core::shannon_entropy_fixed:
//   filter non-finite, clamp to [domain_min, domain_max],
//   bin with truncating cast, clean_count < 2 → 0.
// ---------------------------------------------------------------------------

double shannon_entropy_fixed_neon(const double* values, size_t count, int bin_count,
                                   double domain_min, double domain_max) {
    if (!values || count < 2 || bin_count < 1) return 0.0;

    size_t clean_count = 0;
    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(values[i])) ++clean_count;
    }
    if (clean_count < 2) return 0.0;

    double range = domain_max - domain_min;
    if (range <= 0.0) return 0.0;

    double bin_width = range / static_cast<double>(bin_count);
    std::vector<int> bins(static_cast<size_t>(bin_count), 0);

    const float64x2_t v_dmin = vdupq_n_f64(domain_min);
    const float64x2_t v_dmax = vdupq_n_f64(domain_max);
    const float64x2_t v_bw   = vdupq_n_f64(bin_width);
    const float64x2_t v_zero = vdupq_n_f64(0.0);
    const float64x2_t v_imax = vdupq_n_f64(static_cast<double>(bin_count - 1));

    size_t simd_end = (count / 2) * 2;
    for (size_t i = 0; i < simd_end; i += 2) {
        const double a = values[i];
        const double b = values[i + 1];
        const bool fa = std::isfinite(a);
        const bool fb = std::isfinite(b);

        if (fa && fb) {
            // Vector clamp to domain, then bin index (non-negative → trunc == floor).
            float64x2_t v = vld1q_f64(&values[i]);
            v = vmaxq_f64(v, v_dmin);
            v = vminq_f64(v, v_dmax);
            float64x2_t fidx = vdivq_f64(vsubq_f64(v, v_dmin), v_bw);
            // Clamp index to [0, bin_count-1] (domain_max maps to bin_count).
            fidx = vmaxq_f64(fidx, v_zero);
            fidx = vminq_f64(fidx, v_imax);

            alignas(16) double idx_arr[2];
            vst1q_f64(idx_arr, fidx);
            bins[static_cast<size_t>(static_cast<int>(idx_arr[0]))]++;
            bins[static_cast<size_t>(static_cast<int>(idx_arr[1]))]++;
        } else {
            if (fa) {
                double v = std::max(domain_min, std::min(domain_max, a));
                int idx = static_cast<int>((v - domain_min) / bin_width);
                if (idx < 0) idx = 0;
                if (idx >= bin_count) idx = bin_count - 1;
                bins[static_cast<size_t>(idx)]++;
            }
            if (fb) {
                double v = std::max(domain_min, std::min(domain_max, b));
                int idx = static_cast<int>((v - domain_min) / bin_width);
                if (idx < 0) idx = 0;
                if (idx >= bin_count) idx = bin_count - 1;
                bins[static_cast<size_t>(idx)]++;
            }
        }
    }

    for (size_t i = simd_end; i < count; ++i) {
        double v = values[i];
        if (!std::isfinite(v)) continue;
        v = std::max(domain_min, std::min(domain_max, v));
        int idx = static_cast<int>((v - domain_min) / bin_width);
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

} // namespace ba::simd

#endif // __aarch64__
