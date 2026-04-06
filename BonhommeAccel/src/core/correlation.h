/*
 * correlation.h — Pearson correlation and linear regression.
 *
 * Unified implementation replacing 3 duplicate copies in Swift:
 *   - EntropyCalculator.swift (global pearsonCorrelation)
 *   - DrugResponseAnalyzer.swift (private pearsonCorrelation)
 *   - CrossDomainValidator.swift (private pearsonCorrelation + linearRegression)
 */

#ifndef BA_CORE_CORRELATION_H
#define BA_CORE_CORRELATION_H

#include <cstddef>

namespace ba::core {

/**
 * Pearson product-moment correlation coefficient.
 * Filters pairs where either value is non-finite.
 * Returns 0 if < 2 valid pairs or zero variance.
 */
double pearson_correlation(const double* x, const double* y, size_t count);

/**
 * Ordinary least-squares linear regression: y = slope * x + intercept.
 * Returns mean absolute error (MAE).
 */
struct RegressionResult {
    double slope;
    double intercept;
    double mae;
};

RegressionResult linear_regression(const double* x, const double* y, size_t count);

} // namespace ba::core

#endif // BA_CORE_CORRELATION_H
