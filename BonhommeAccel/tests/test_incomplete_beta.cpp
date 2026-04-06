/*
 * test_incomplete_beta.cpp — Catch2 tests for regularized incomplete beta
 * and Pearson p-value computation.
 *
 * Validates parity with CrossDomainValidator.swift's computePValue().
 */

#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_floating_point.hpp>
#include "BonhommeAccel.h"
#include "reference_values.h"

#include <cmath>

using namespace ba::test;
using Catch::Matchers::WithinAbs;

// ═══════════════════════════════════════════════════════════════════════════
// Regularized Incomplete Beta
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("IBeta: boundary x=0 returns 0", "[ibeta]") {
    double result = -1;
    BAStatus s = ba_regularized_incomplete_beta(0.0, 2.0, 3.0, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(result == 0.0);
}

TEST_CASE("IBeta: boundary x=1 returns 1", "[ibeta]") {
    double result = -1;
    BAStatus s = ba_regularized_incomplete_beta(1.0, 2.0, 3.0, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(result == 1.0);
}

TEST_CASE("IBeta: known value I_0.5(1, 1) = 0.5", "[ibeta]") {
    double result = 0;
    ba_regularized_incomplete_beta(0.5, 1.0, 1.0, &result);
    REQUIRE_THAT(result, WithinAbs(0.5, PVAL_TOL));
}

TEST_CASE("IBeta: known value I_0.5(2, 2) ≈ 0.5", "[ibeta]") {
    // I_0.5(a, a) = 0.5 for any a (symmetry)
    double result = 0;
    ba_regularized_incomplete_beta(0.5, 2.0, 2.0, &result);
    REQUIRE_THAT(result, WithinAbs(0.5, PVAL_TOL));
}

TEST_CASE("IBeta: invalid a <= 0 returns error", "[ibeta]") {
    double result = 0;
    BAStatus s = ba_regularized_incomplete_beta(0.5, 0.0, 1.0, &result);
    REQUIRE(s == BA_ERR_INVALID_PARAM);
}

// ═══════════════════════════════════════════════════════════════════════════
// Pearson P-Value
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("P-value: r=0 gives p=1", "[pvalue]") {
    double pval = -1;
    BAStatus s = ba_pearson_pvalue(0.0, 10, &pval);
    REQUIRE(s == BA_OK);
    REQUIRE_THAT(pval, WithinAbs(1.0, PVAL_TOL));
}

TEST_CASE("P-value: strong correlation with small n", "[pvalue]") {
    // r=0.95, n=5 -> should be significant (p < 0.05) but marginal
    double pval = 0;
    ba_pearson_pvalue(0.95, 5, &pval);
    REQUIRE(pval < 0.05);
}

TEST_CASE("P-value: strong correlation with large n is very significant", "[pvalue]") {
    // r=0.5, n=100 -> p should be very small
    double pval = 1.0;
    ba_pearson_pvalue(0.5, 100, &pval);
    REQUIRE(pval < 0.001);
}

TEST_CASE("P-value: weak correlation with small n is not significant", "[pvalue]") {
    // r=0.3, n=5 -> p > 0.05 (not enough data)
    double pval = 0;
    ba_pearson_pvalue(0.3, 5, &pval);
    REQUIRE(pval > 0.05);
}

TEST_CASE("P-value: n <= 2 returns error", "[pvalue]") {
    double pval = 0;
    BAStatus s = ba_pearson_pvalue(0.5, 2, &pval);
    REQUIRE(s == BA_ERR_INSUFFICIENT_DATA);
}

TEST_CASE("P-value: |r| = 1 gives p = 0", "[pvalue]") {
    double pval = -1;
    ba_pearson_pvalue(1.0, 10, &pval);
    REQUIRE(pval == 0.0);

    ba_pearson_pvalue(-1.0, 10, &pval);
    REQUIRE(pval == 0.0);
}
