/*
 * entropy_neon.cpp — ARM NEON-accelerated Shannon entropy.
 *
 * Uses 128-bit NEON (float64x2_t, 2-wide double) for vectorized
 * min/max finding. Histogram and entropy reduction remain scalar.
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

    // Filter non-finite
    std::vector<double> clean;
    clean.reserve(count);
    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(values[i])) clean.push_back(values[i]);
    }

    size_t n = clean.size();
    if (n < 2) return 0.0;

    // NEON min/max (2-wide double)
    size_t simd_end = (n / 2) * 2;
    float64x2_t vmin = vdupq_n_f64(std::numeric_limits<double>::max());
    float64x2_t vmax = vdupq_n_f64(std::numeric_limits<double>::lowest());

    for (size_t i = 0; i < simd_end; i += 2) {
        float64x2_t v = vld1q_f64(&clean[i]);
        vmin = vminq_f64(vmin, v);
        vmax = vmaxq_f64(vmax, v);
    }

    double min_val = std::min(vgetq_lane_f64(vmin, 0), vgetq_lane_f64(vmin, 1));
    double max_val = std::max(vgetq_lane_f64(vmax, 0), vgetq_lane_f64(vmax, 1));

    for (size_t i = simd_end; i < n; ++i) {
        min_val = std::min(min_val, clean[i]);
        max_val = std::max(max_val, clean[i]);
    }

    double range = max_val - min_val;
    if (range <= 0.0) return 0.0;

    double bin_width = range / static_cast<double>(bin_count);

    std::vector<int> bins(static_cast<size_t>(bin_count), 0);
    for (size_t i = 0; i < n; ++i) {
        int idx = std::min(bin_count - 1,
                           static_cast<int>((clean[i] - min_val) / bin_width));
        bins[static_cast<size_t>(idx)]++;
    }

    double total = static_cast<double>(n);
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

    // NEON vectorized wrapping
    float64x2_t v360 = vdupq_n_f64(360.0);
    float64x2_t v180 = vdupq_n_f64(180.0);
    float64x2_t vn180 = vdupq_n_f64(-180.0);

    size_t simd_end = (count / 2) * 2;
    for (size_t i = 0; i < simd_end; i += 2) {
        // Process scalar for simplicity with NaN checks
        for (int k = 0; k < 2; ++k) {
            double a = angles[i + static_cast<size_t>(k)];
            if (!std::isfinite(a)) continue;
            a = std::fmod(a, 360.0);
            if (a > 180.0) a -= 360.0;
            if (a < -180.0) a += 360.0;
            int idx = std::min(bin_count - 1, static_cast<int>((a + 180.0) / bin_width));
            bins[static_cast<size_t>(idx)]++;
        }
    }

    for (size_t i = simd_end; i < count; ++i) {
        double a = angles[i];
        if (!std::isfinite(a)) continue;
        a = std::fmod(a, 360.0);
        if (a > 180.0) a -= 360.0;
        if (a < -180.0) a += 360.0;
        int idx = std::min(bin_count - 1, static_cast<int>((a + 180.0) / bin_width));
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
