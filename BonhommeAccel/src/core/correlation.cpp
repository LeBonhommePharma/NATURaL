/*
 * correlation.cpp — Pearson correlation and linear regression (scalar).
 *
 * Mirrors the global pearsonCorrelation() and linearRegression() from
 * BonhommeCore/EntropyCalculator.swift.
 */

#include "correlation.h"

#include <cmath>
#include <vector>

namespace ba::core {

double pearson_correlation(const double* x, const double* y, size_t count) {
    if (!x || !y || count < 2) return 0.0;

    // Filter pairs where both values are finite
    std::vector<double> cx, cy;
    cx.reserve(count);
    cy.reserve(count);

    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(x[i]) && std::isfinite(y[i])) {
            cx.push_back(x[i]);
            cy.push_back(y[i]);
        }
    }

    double n = static_cast<double>(cx.size());
    if (n < 2.0) return 0.0;

    double mean_x = 0.0, mean_y = 0.0;
    for (size_t i = 0; i < cx.size(); ++i) {
        mean_x += cx[i];
        mean_y += cy[i];
    }
    mean_x /= n;
    mean_y /= n;

    double sum_xy = 0.0, sum_x2 = 0.0, sum_y2 = 0.0;
    for (size_t i = 0; i < cx.size(); ++i) {
        double dx = cx[i] - mean_x;
        double dy = cy[i] - mean_y;
        sum_xy += dx * dy;
        sum_x2 += dx * dx;
        sum_y2 += dy * dy;
    }

    double denom = std::sqrt(sum_x2 * sum_y2);
    if (denom <= 0.0) return 0.0;

    return sum_xy / denom;
}

RegressionResult linear_regression(const double* x, const double* y, size_t count) {
    RegressionResult result{0.0, 0.0, 0.0};
    if (!x || !y || count < 2) return result;

    double n = static_cast<double>(count);
    double mean_x = 0.0, mean_y = 0.0;

    for (size_t i = 0; i < count; ++i) {
        mean_x += x[i];
        mean_y += y[i];
    }
    mean_x /= n;
    mean_y /= n;

    double sum_xy = 0.0, sum_x2 = 0.0;
    for (size_t i = 0; i < count; ++i) {
        double dx = x[i] - mean_x;
        sum_xy += dx * (y[i] - mean_y);
        sum_x2 += dx * dx;
    }

    result.slope = (sum_x2 > 0.0) ? (sum_xy / sum_x2) : 0.0;
    result.intercept = mean_y - result.slope * mean_x;

    double total_error = 0.0;
    for (size_t i = 0; i < count; ++i) {
        double predicted = result.slope * x[i] + result.intercept;
        total_error += std::abs(y[i] - predicted);
    }
    result.mae = total_error / n;

    return result;
}

} // namespace ba::core
