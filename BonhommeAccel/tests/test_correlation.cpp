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

TEST_CASE("Pearson: large N perfect line (CPU or GPU path)", "[correlation][parity]") {
    constexpr size_t N = 20000;
    std::vector<double> x(N), y(N);
    for (size_t i = 0; i < N; ++i) {
        x[i] = static_cast<double>(i);
        y[i] = 3.0 * x[i] - 7.0;
    }
    double r = 0.0;
    REQUIRE(ba_pearson_correlation(x.data(), y.data(), N, &r) == BA_OK);
    // Metal float32 may sit slightly outside [-1,1] by ~1e-7; clamp-check magnitude.
    REQUIRE(std::abs(r) > 0.999999);
    REQUIRE(std::abs(r) < 1.00001);
}

TEST_CASE("Pearson: mid-size with NaN pairs matches clean", "[correlation][simd]") {
    constexpr size_t N = 1024;
    std::vector<double> x(N), y(N), cx, cy;
    for (size_t i = 0; i < N; ++i) {
        x[i] = std::sin(0.01 * static_cast<double>(i));
        y[i] = std::cos(0.01 * static_cast<double>(i));
        if (i % 17 == 0) {
            x[i] = NAN;
        } else if (i % 19 == 0) {
            y[i] = NAN;
        } else {
            cx.push_back(x[i]);
            cy.push_back(y[i]);
        }
    }
    double r_dirty = 0, r_clean = 0;
    REQUIRE(ba_pearson_correlation(x.data(), y.data(), N, &r_dirty) == BA_OK);
    REQUIRE(ba_pearson_correlation(cx.data(), cy.data(), cx.size(), &r_clean) == BA_OK);
    REQUIRE_THAT(r_dirty, WithinAbs(r_clean, CORR_TOL));
}

TEST_CASE("Pearson: null and size errors", "[correlation]") {
    double x[2] = {1, 2}, y[2] = {3, 4}, r = 0;
    REQUIRE(ba_pearson_correlation(nullptr, y, 2, &r) == BA_ERR_NULL_PTR);
    REQUIRE(ba_pearson_correlation(x, nullptr, 2, &r) == BA_ERR_NULL_PTR);
    REQUIRE(ba_pearson_correlation(x, y, 2, nullptr) == BA_ERR_NULL_PTR);
    REQUIRE(ba_pearson_correlation(x, y, 0, &r) == BA_ERR_INSUFFICIENT_DATA);
}

TEST_CASE("Regression: filters NaN pairs", "[regression]") {
    std::vector<double> x = {1.0, NAN, 3.0, 4.0, 5.0};
    std::vector<double> y = {3.0, 5.0, NAN, 9.0, 11.0};
    // Valid pairs: (1,3), (4,9), (5,11) → slope 2, intercept 1
    double slope = 0, intercept = 0, mae = 0;
    REQUIRE(ba_linear_regression(x.data(), y.data(), x.size(),
                                  &slope, &intercept, &mae) == BA_OK);
    REQUIRE_THAT(slope, WithinAbs(2.0, 1e-9));
    REQUIRE_THAT(intercept, WithinAbs(1.0, 1e-9));
    REQUIRE_THAT(mae, WithinAbs(0.0, 1e-9));
}

TEST_CASE("Regression: null pointer errors", "[regression]") {
    double x[2] = {1, 2}, y[2] = {3, 4};
    double s = 0, i = 0, m = 0;
    REQUIRE(ba_linear_regression(nullptr, y, 2, &s, &i, &m) == BA_ERR_NULL_PTR);
    REQUIRE(ba_linear_regression(x, y, 2, nullptr, &i, &m) == BA_ERR_NULL_PTR);
}
