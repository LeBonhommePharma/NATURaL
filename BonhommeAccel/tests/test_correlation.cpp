/*
 * test_correlation.cpp — Catch2 tests for Pearson correlation and linear regression.
 *
 * Validates parity with BonhommeCore's global pearsonCorrelation() and
 * linearRegression() functions from EntropyCalculator.swift.
 */

#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_floating_point.hpp>
#include "BonhommeAccel.h"
#include "reference_values.h"

#include <cmath>
#include <vector>

using namespace ba::test;
using Catch::Matchers::WithinAbs;

// ═══════════════════════════════════════════════════════════════════════════
// Pearson Correlation
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("Pearson: perfect positive correlation", "[correlation]") {
    std::vector<double> x = {1.0, 2.0, 3.0, 4.0, 5.0};
    std::vector<double> y = {2.0, 4.0, 6.0, 8.0, 10.0};
    double r = 0.0;
    BAStatus s = ba_pearson_correlation(x.data(), y.data(), x.size(), &r);
    REQUIRE(s == BA_OK);
    REQUIRE_THAT(r, WithinAbs(1.0, CORR_TOL));
}

TEST_CASE("Pearson: perfect negative correlation", "[correlation]") {
    std::vector<double> x = {1.0, 2.0, 3.0, 4.0, 5.0};
    std::vector<double> y = {10.0, 8.0, 6.0, 4.0, 2.0};
    double r = 0.0;
    ba_pearson_correlation(x.data(), y.data(), x.size(), &r);
    REQUIRE_THAT(r, WithinAbs(-1.0, CORR_TOL));
}

TEST_CASE("Pearson: uncorrelated data near zero", "[correlation]") {
    // sin(x) vs cos(x) over full period -> r ≈ 0
    std::vector<double> x(1000), y(1000);
    for (size_t i = 0; i < 1000; ++i) {
        double t = 2.0 * M_PI * static_cast<double>(i) / 1000.0;
        x[i] = std::sin(t);
        y[i] = std::cos(t);
    }
    double r = 0.0;
    ba_pearson_correlation(x.data(), y.data(), x.size(), &r);
    REQUIRE(std::abs(r) < 0.05);
}

TEST_CASE("Pearson: filters NaN pairs", "[correlation]") {
    std::vector<double> x = {1.0, NAN, 3.0, 4.0, 5.0};
    std::vector<double> y = {2.0, 4.0, NAN, 8.0, 10.0};
    double r = 0.0;
    BAStatus s = ba_pearson_correlation(x.data(), y.data(), x.size(), &r);
    REQUIRE(s == BA_OK);
    REQUIRE(!std::isnan(r));
    // After filtering: (1,2), (4,8), (5,10) -> r = 1.0
    REQUIRE_THAT(r, WithinAbs(1.0, CORR_TOL));
}

TEST_CASE("Pearson: zero variance returns 0", "[correlation]") {
    std::vector<double> x = {5.0, 5.0, 5.0, 5.0};
    std::vector<double> y = {1.0, 2.0, 3.0, 4.0};
    double r = -1.0;
    ba_pearson_correlation(x.data(), y.data(), x.size(), &r);
    REQUIRE(r == 0.0);
}

TEST_CASE("Pearson: insufficient data", "[correlation]") {
    double x = 1.0, y = 2.0;
    double r = -1.0;
    BAStatus s = ba_pearson_correlation(&x, &y, 1, &r);
    REQUIRE(s == BA_ERR_INSUFFICIENT_DATA);
}

// ═══════════════════════════════════════════════════════════════════════════
// Linear Regression
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("Regression: perfect linear y = 2x + 1", "[regression]") {
    std::vector<double> x = {1.0, 2.0, 3.0, 4.0, 5.0};
    std::vector<double> y = {3.0, 5.0, 7.0, 9.0, 11.0};
    double slope = 0, intercept = 0, mae = 0;
    BAStatus s = ba_linear_regression(x.data(), y.data(), x.size(),
                                       &slope, &intercept, &mae);
    REQUIRE(s == BA_OK);
    REQUIRE_THAT(slope, WithinAbs(2.0, CORR_TOL));
    REQUIRE_THAT(intercept, WithinAbs(1.0, CORR_TOL));
    REQUIRE_THAT(mae, WithinAbs(0.0, CORR_TOL));
}

TEST_CASE("Regression: constant y has slope 0", "[regression]") {
    std::vector<double> x = {1.0, 2.0, 3.0, 4.0};
    std::vector<double> y = {5.0, 5.0, 5.0, 5.0};
    double slope = -1, intercept = -1, mae = -1;
    ba_linear_regression(x.data(), y.data(), x.size(), &slope, &intercept, &mae);
    REQUIRE_THAT(slope, WithinAbs(0.0, CORR_TOL));
    REQUIRE_THAT(intercept, WithinAbs(5.0, CORR_TOL));
    REQUIRE_THAT(mae, WithinAbs(0.0, CORR_TOL));
}

TEST_CASE("Regression: negative slope", "[regression]") {
    std::vector<double> x = {0.0, 1.0, 2.0, 3.0};
    std::vector<double> y = {6.0, 4.0, 2.0, 0.0};
    double slope = 0, intercept = 0, mae = 0;
    ba_linear_regression(x.data(), y.data(), x.size(), &slope, &intercept, &mae);
    REQUIRE_THAT(slope, WithinAbs(-2.0, CORR_TOL));
    REQUIRE_THAT(intercept, WithinAbs(6.0, CORR_TOL));
}
