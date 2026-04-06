/*
 * incomplete_beta.cpp — Regularized incomplete beta function (scalar).
 *
 * Direct port of CrossDomainValidator.swift's Lentz's continued fraction
 * implementation. Numerical Recipes algorithm.
 */

#include "incomplete_beta.h"
#include <cmath>
#include <cstddef>
#include <algorithm>

namespace ba::core {

// Log of the beta function: ln B(a, b) = ln Gamma(a) + ln Gamma(b) - ln Gamma(a+b)
static double ln_beta(double a, double b) {
    return std::lgamma(a) + std::lgamma(b) - std::lgamma(a + b);
}

double regularized_incomplete_beta(double x, double a, double b) {
    if (x <= 0.0) return 0.0;
    if (x >= 1.0) return 1.0;

    // Symmetry relation for better convergence
    if (x > (a + 1.0) / (a + b + 2.0)) {
        return 1.0 - regularized_incomplete_beta(1.0 - x, b, a);
    }

    // Log of the beta function prefactor: x^a (1-x)^b / (a B(a,b))
    double ln_prefactor = a * std::log(x) + b * std::log(1.0 - x)
                          - std::log(a) - ln_beta(a, b);
    double prefactor = std::exp(ln_prefactor);

    // Lentz's continued fraction
    constexpr int max_iterations = 200;
    constexpr double epsilon = 1.0e-10;
    constexpr double tiny = 1.0e-30;

    double c = 1.0;
    double d = 1.0 / std::max(tiny, 1.0 - (a + b) * x / (a + 1.0));
    double h = d;

    for (int m = 1; m <= max_iterations; ++m) {
        double dm = static_cast<double>(m);

        // Even step: a_{2m}
        double numerator = dm * (b - dm) * x /
                           ((a + 2.0 * dm - 1.0) * (a + 2.0 * dm));
        d = 1.0 / std::max(tiny, 1.0 + numerator * d);
        c = std::max(tiny, 1.0 + numerator / c);
        h *= d * c;

        // Odd step: a_{2m+1}
        numerator = -(a + dm) * (a + b + dm) * x /
                    ((a + 2.0 * dm) * (a + 2.0 * dm + 1.0));
        d = 1.0 / std::max(tiny, 1.0 + numerator * d);
        c = std::max(tiny, 1.0 + numerator / c);
        double delta = d * c;
        h *= delta;

        if (std::abs(delta - 1.0) < epsilon) {
            break;
        }
    }

    return prefactor * h;
}

double pearson_pvalue(double r, size_t n) {
    if (n <= 2) return 1.0;

    double abs_r = std::abs(r);
    if (abs_r >= 1.0) return 0.0;

    double df = static_cast<double>(n - 2);
    double t = abs_r * std::sqrt(df) / std::sqrt(1.0 - abs_r * abs_r);

    // Two-tailed p-value
    double x = df / (df + t * t);
    return regularized_incomplete_beta(x, df / 2.0, 0.5);
}

} // namespace ba::core
