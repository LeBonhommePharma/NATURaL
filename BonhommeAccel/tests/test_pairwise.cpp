/*
 * test_pairwise.cpp — Catch2 tests for pairwise interaction scoring.
 */

#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_floating_point.hpp>
#include "BonhommeAccel.h"
#include "reference_values.h"

#include <cmath>
#include <cstdint>
#include <vector>

using namespace ba::test;
using Catch::Matchers::WithinAbs;

// Simple struct for testing pairwise scoring
struct TestItem {
    double value;
};

// Score function: absolute difference
static double abs_diff_score(const void* s1, const void* s2, void* /*user_data*/) {
    auto a = static_cast<const TestItem*>(s1);
    auto b = static_cast<const TestItem*>(s2);
    return std::abs(a->value - b->value);
}

TEST_CASE("Pairwise: 4 items produces 6 scores", "[pairwise]") {
    TestItem items[] = {{1.0}, {3.0}, {6.0}, {10.0}};
    // Expected pairs: (0,1)=2, (0,2)=5, (0,3)=9, (1,2)=3, (1,3)=7, (2,3)=4
    double scores[6] = {0};

    BAStatus s = ba_pairwise_scores(items, 4, sizeof(TestItem),
                                     abs_diff_score, nullptr, scores);
    REQUIRE(s == BA_OK);
    REQUIRE_THAT(scores[0], WithinAbs(2.0, CORR_TOL));  // (0,1)
    REQUIRE_THAT(scores[1], WithinAbs(5.0, CORR_TOL));  // (0,2)
    REQUIRE_THAT(scores[2], WithinAbs(9.0, CORR_TOL));  // (0,3)
    REQUIRE_THAT(scores[3], WithinAbs(3.0, CORR_TOL));  // (1,2)
    REQUIRE_THAT(scores[4], WithinAbs(7.0, CORR_TOL));  // (1,3)
    REQUIRE_THAT(scores[5], WithinAbs(4.0, CORR_TOL));  // (2,3)
}

TEST_CASE("Pairwise: 2 items produces 1 score", "[pairwise]") {
    TestItem items[] = {{5.0}, {8.0}};
    double score = 0;
    BAStatus s = ba_pairwise_scores(items, 2, sizeof(TestItem),
                                     abs_diff_score, nullptr, &score);
    REQUIRE(s == BA_OK);
    REQUIRE_THAT(score, WithinAbs(3.0, CORR_TOL));
}

TEST_CASE("Pairwise: insufficient items returns error", "[pairwise]") {
    TestItem items[] = {{1.0}};
    double score = 0;
    BAStatus s = ba_pairwise_scores(items, 1, sizeof(TestItem),
                                     abs_diff_score, nullptr, &score);
    REQUIRE(s == BA_ERR_INSUFFICIENT_DATA);
}

// ═══════════════════════════════════════════════════════════════════════════
// Descriptive Statistics
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("Stats: mean and SD of known values", "[statistics]") {
    std::vector<double> vals = {2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0};
    double mean = 0, sd = 0;
    BAStatus s = ba_descriptive_stats(vals.data(), vals.size(), &mean, &sd);
    REQUIRE(s == BA_OK);
    REQUIRE_THAT(mean, WithinAbs(5.0, CORR_TOL));
    // Sample SD = sqrt(32/7) ≈ 2.138
    REQUIRE_THAT(sd, WithinAbs(2.138, 0.01));
}

TEST_CASE("Stats: single value has SD=0", "[statistics]") {
    double val = 42.0;
    double mean = 0, sd = -1;
    ba_descriptive_stats(&val, 1, &mean, &sd);
    REQUIRE_THAT(mean, WithinAbs(42.0, CORR_TOL));
    REQUIRE(sd == 0.0);
}

TEST_CASE("Stats: NaN/Inf filtered from mean and SD", "[statistics]") {
    // Finite-only mean of {1,2,3,4,5} = 3; sample SD = sqrt(2.5)
    std::vector<double> vals = {1.0, NAN, 2.0, INFINITY, 3.0, 4.0, -INFINITY, 5.0};
    double mean = 0.0, sd = 0.0;
    BAStatus s = ba_descriptive_stats(vals.data(), vals.size(), &mean, &sd);
    REQUIRE(s == BA_OK);
    REQUIRE_THAT(mean, WithinAbs(3.0, CORR_TOL));
    REQUIRE_THAT(sd, WithinAbs(std::sqrt(2.5), CORR_TOL));
}

TEST_CASE("Z-score outliers: flags |z| > 2", "[statistics]") {
    std::vector<double> vals = {10.0, 10.0, 10.0, 10.0, 10.0, 50.0};
    std::vector<int32_t> flags(vals.size(), -1);
    BAStatus s = ba_zscore_outliers(vals.data(), vals.size(), 2.0, flags.data());
    REQUIRE(s == BA_OK);
    // The 50.0 should be an outlier
    REQUIRE(flags[5] == 1);
    // Normal values should not be outliers
    for (int i = 0; i < 5; ++i) {
        REQUIRE(flags[i] == 0);
    }
}

TEST_CASE("Z-score: non-finite values flagged as outliers", "[statistics]") {
    std::vector<double> vals = {1.0, 2.0, 3.0, 4.0, 5.0, NAN, INFINITY};
    std::vector<int32_t> flags(vals.size(), -1);
    REQUIRE(ba_zscore_outliers(vals.data(), vals.size(), 2.0, flags.data()) == BA_OK);
    REQUIRE(flags[5] == 1);
    REQUIRE(flags[6] == 1);
    // Finite cluster should not all be outliers
    int finite_outliers = 0;
    for (int i = 0; i < 5; ++i) finite_outliers += flags[i];
    REQUIRE(finite_outliers == 0);
}

TEST_CASE("Z-score: zero variance clears all flags", "[statistics]") {
    std::vector<double> vals(20, 7.0);
    std::vector<int32_t> flags(vals.size(), -1);
    REQUIRE(ba_zscore_outliers(vals.data(), vals.size(), 2.0, flags.data()) == BA_OK);
    for (auto f : flags) REQUIRE(f == 0);
}

TEST_CASE("Z-score: invalid threshold", "[statistics]") {
    double v[3] = {1, 2, 3};
    int32_t flags[3] = {};
    REQUIRE(ba_zscore_outliers(v, 3, 0.0, flags) == BA_ERR_INVALID_PARAM);
    REQUIRE(ba_zscore_outliers(v, 3, -1.0, flags) == BA_ERR_INVALID_PARAM);
}

TEST_CASE("Stats: all NaN returns zero mean and SD", "[statistics]") {
    std::vector<double> vals = {NAN, NAN, INFINITY};
    double mean = -1, sd = -1;
    REQUIRE(ba_descriptive_stats(vals.data(), vals.size(), &mean, &sd) == BA_OK);
    REQUIRE(mean == 0.0);
    REQUIRE(sd == 0.0);
}

TEST_CASE("Stats: null pointer errors", "[statistics]") {
    double v[2] = {1, 2}, mean = 0, sd = 0;
    REQUIRE(ba_descriptive_stats(nullptr, 2, &mean, &sd) == BA_ERR_NULL_PTR);
    REQUIRE(ba_descriptive_stats(v, 2, nullptr, &sd) == BA_ERR_NULL_PTR);
    REQUIRE(ba_descriptive_stats(v, 0, &mean, &sd) == BA_ERR_INSUFFICIENT_DATA);
}

TEST_CASE("Pairwise: null and stride errors", "[pairwise]") {
    double data[2] = {1, 2};
    double scores[1] = {};
    auto fn = [](const void*, const void*, void*) -> double { return 1.0; };
    REQUIRE(ba_pairwise_scores(nullptr, 2, sizeof(double), fn, nullptr, scores)
            == BA_ERR_NULL_PTR);
    REQUIRE(ba_pairwise_scores(data, 2, 0, fn, nullptr, scores) == BA_ERR_INVALID_PARAM);
    REQUIRE(ba_pairwise_scores(data, 1, sizeof(double), fn, nullptr, scores)
            == BA_ERR_INSUFFICIENT_DATA);
}
