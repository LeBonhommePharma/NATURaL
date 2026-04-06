/*
 * statistics.cpp — Descriptive statistics and z-score outlier detection (scalar).
 */

#include "statistics.h"
#include <cmath>

namespace ba::core {

DescriptiveStats descriptive_stats(const double* values, size_t count) {
    DescriptiveStats result{0.0, 0.0};
    if (!values || count < 1) return result;

    double sum = 0.0;
    for (size_t i = 0; i < count; ++i) {
        sum += values[i];
    }
    result.mean = sum / static_cast<double>(count);

    if (count < 2) return result;

    double var_sum = 0.0;
    for (size_t i = 0; i < count; ++i) {
        double d = values[i] - result.mean;
        var_sum += d * d;
    }
    result.sd = std::sqrt(var_sum / static_cast<double>(count - 1));

    return result;
}

void zscore_outliers(const double* values, size_t count,
                     double threshold, int32_t* out_flags) {
    if (!values || !out_flags || count < 2) {
        if (out_flags) {
            for (size_t i = 0; i < count; ++i) out_flags[i] = 0;
        }
        return;
    }

    auto stats = descriptive_stats(values, count);

    if (stats.sd <= 0.0) {
        for (size_t i = 0; i < count; ++i) out_flags[i] = 0;
        return;
    }

    for (size_t i = 0; i < count; ++i) {
        double z = (values[i] - stats.mean) / stats.sd;
        out_flags[i] = (std::abs(z) > threshold) ? 1 : 0;
    }
}

} // namespace ba::core
