/*
 * statistics.h — Descriptive statistics and outlier detection.
 *
 * Mirrors PopulationPKAnalyzer.swift's descriptiveStats() and z-score logic.
 */

#ifndef BA_CORE_STATISTICS_H
#define BA_CORE_STATISTICS_H

#include <cstddef>
#include <cstdint>

namespace ba::core {

struct DescriptiveStats {
    double mean;
    double sd; // sample SD (Bessel-corrected, n-1)
};

/**
 * Compute mean and sample standard deviation.
 * Returns {0, 0} if count < 1. SD is 0 if count < 2.
 */
DescriptiveStats descriptive_stats(const double* values, size_t count);

/**
 * Compute z-scores and flag outliers where |z| > threshold.
 * out_flags[i] = 1 if outlier, 0 otherwise.
 */
void zscore_outliers(const double* values, size_t count,
                     double threshold, int32_t* out_flags);

} // namespace ba::core

#endif // BA_CORE_STATISTICS_H
