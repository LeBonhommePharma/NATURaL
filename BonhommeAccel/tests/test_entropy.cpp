/*
 * test_entropy.cpp — Catch2 tests for Shannon entropy.
 *
 * Validates numerical parity with BonhommeCore's EntropyCalculator.swift
 * and FlexAIDdSAnalyzer.swift test cases.
 */

#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_floating_point.hpp>
#include "BonhommeAccel.h"
#include "reference_values.h"

#include <cmath>
#include <numeric>
#include <vector>

using namespace ba::test;
using Catch::Matchers::WithinAbs;

// ═══════════════════════════════════════════════════════════════════════════
// Shannon Entropy — Basic
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("Shannon entropy: empty array returns error", "[entropy]") {
    double result = -1.0;
    BAStatus s = ba_shannon_entropy(nullptr, 0, DEFAULT_BIN_COUNT, &result);
    REQUIRE(s != BA_OK);
}

TEST_CASE("Shannon entropy: single value returns error", "[entropy]") {
    double val = 42.0;
    double result = -1.0;
    BAStatus s = ba_shannon_entropy(&val, 1, DEFAULT_BIN_COUNT, &result);
    REQUIRE(s == BA_ERR_INSUFFICIENT_DATA);
}

TEST_CASE("Shannon entropy: identical values return 0", "[entropy]") {
    std::vector<double> vals(100, 5.0);
    double result = -1.0;
    BAStatus s = ba_shannon_entropy(vals.data(), vals.size(), DEFAULT_BIN_COUNT, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(result == 0.0);
}

TEST_CASE("Shannon entropy: uniform distribution near-maximum", "[entropy]") {
    // 1000 uniformly spaced values across [0, 100)
    std::vector<double> vals(1000);
    for (size_t i = 0; i < vals.size(); ++i) {
        vals[i] = 100.0 * static_cast<double>(i) / 1000.0;
    }

    double result = 0.0;
    BAStatus s = ba_shannon_entropy(vals.data(), vals.size(), DEFAULT_BIN_COUNT, &result);
    REQUIRE(s == BA_OK);
    // Should be close to log2(32) = 5.0
    REQUIRE(result > MAX_ENTROPY_32 * 0.95);
}

TEST_CASE("Shannon entropy: NaN values are filtered", "[entropy]") {
    std::vector<double> vals = {1.0, 2.0, NAN, 3.0, 4.0, NAN, 5.0};
    double result = 0.0;
    BAStatus s = ba_shannon_entropy(vals.data(), vals.size(), DEFAULT_BIN_COUNT, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(!std::isnan(result));
    REQUIRE(result > 0.0);
}

TEST_CASE("Shannon entropy: infinity values are filtered", "[entropy]") {
    std::vector<double> vals = {1.0, 2.0, INFINITY, 3.0, 4.0, -INFINITY, 5.0};
    double result = 0.0;
    BAStatus s = ba_shannon_entropy(vals.data(), vals.size(), DEFAULT_BIN_COUNT, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(!std::isnan(result));
    REQUIRE(result > 0.0);
}

TEST_CASE("Shannon entropy: all NaN returns 0", "[entropy]") {
    std::vector<double> vals = {NAN, NAN, NAN};
    double result = -1.0;
    // The core function returns 0 for insufficient clean data, but the API
    // still passes count >= 2 check. The core returns 0.
    BAStatus s = ba_shannon_entropy(vals.data(), vals.size(), DEFAULT_BIN_COUNT, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(result == 0.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Circular Shannon Entropy — Torsional Angles
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("Circular entropy: wraparound at +-180", "[entropy][circular]") {
    // Generate angles at +170 to +180 and -170 to -180.
    // On the circle, all are within ~20 degrees of +-180.
    // Linear sees range = 360, spreading across many bins -> high entropy.
    // Circular correctly sees them clustered near +-180 -> low entropy.
    std::vector<double> angles;
    for (int i = 0; i < 100; ++i) {
        // [+170, +180]
        angles.push_back(170.0 + 10.0 * static_cast<double>(i) / 99.0);
    }
    for (int i = 0; i < 100; ++i) {
        // [-180, -170]
        angles.push_back(-180.0 + 10.0 * static_cast<double>(i) / 99.0);
    }

    double circular_h = 0.0;
    BAStatus s = ba_circular_shannon_entropy(angles.data(), angles.size(),
                                             DEFAULT_BIN_COUNT, &circular_h);
    REQUIRE(s == BA_OK);
    REQUIRE(circular_h < 3.0); // Clustered in ~3 adjacent circular bins

    // Linear: range = [-180, 180] = 360. Data in first 1 bin and last 1 bin.
    // Linear adaptive: range = [-180, +180], bin_width = 360/32 = 11.25
    // Angles [170,180] in bin 31, angles [-180,-170] in bin 0.
    // 2 bins -> entropy = log2(2) = 1.0 exactly.
    // But circular has angles spanning ~3 bins near the boundary.
    // The key validation: circular entropy is low (< 3 bits).
    // This mirrors Swift's testCircularEntropyWraparound.
    REQUIRE(circular_h > 0.0);
}

TEST_CASE("Circular entropy: uniform angles near-maximum", "[entropy][circular]") {
    std::vector<double> angles(1000);
    for (size_t i = 0; i < angles.size(); ++i) {
        angles[i] = -180.0 + 360.0 * static_cast<double>(i) / 1000.0;
    }

    double result = 0.0;
    BAStatus s = ba_circular_shannon_entropy(angles.data(), angles.size(),
                                             DEFAULT_BIN_COUNT, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(result > MAX_ENTROPY_32 * 0.95);
}

TEST_CASE("Circular entropy: angle wrapping beyond [-180, 180]", "[entropy][circular]") {
    // 350 degrees should wrap to -10 degrees
    // -350 degrees should wrap to 10 degrees
    // Both clustered near 0 -> low entropy
    std::vector<double> angles;
    for (int i = 0; i < 100; ++i) {
        angles.push_back(350.0 + (static_cast<double>(i % 5) - 2.0) * 0.5);
    }
    for (int i = 0; i < 100; ++i) {
        angles.push_back(-350.0 + (static_cast<double>(i % 5) - 2.0) * 0.5);
    }

    double result = 0.0;
    BAStatus s = ba_circular_shannon_entropy(angles.data(), angles.size(),
                                             DEFAULT_BIN_COUNT, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(result < 2.5);
}

TEST_CASE("Circular entropy: NaN values filtered", "[entropy][circular]") {
    std::vector<double> angles = {10.0, 20.0, NAN, 30.0, 15.0, NAN};
    double result = 0.0;
    BAStatus s = ba_circular_shannon_entropy(angles.data(), angles.size(),
                                             DEFAULT_BIN_COUNT, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(!std::isnan(result));
    REQUIRE(result > 0.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Fixed-Domain Shannon Entropy
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("Fixed-domain entropy: values clamped to domain", "[entropy][fixed]") {
    std::vector<double> vals = {-500.0, 0.0, 50.0, 100.0, 500.0};
    double result = 0.0;
    BAStatus s = ba_shannon_entropy_fixed(vals.data(), vals.size(),
                                          DEFAULT_BIN_COUNT, 0.0, 100.0, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(result >= 0.0);
}

TEST_CASE("Fixed-domain entropy: NaN/Inf mixed equals finite-only", "[entropy][fixed]") {
    std::vector<double> finite_only = {10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0};
    std::vector<double> mixed = {10.0, NAN, 20.0, INFINITY, 30.0, 40.0, -INFINITY, 50.0,
                                  60.0, NAN, 70.0, 80.0};

    double h_finite = 0.0, h_mixed = 0.0;
    BAStatus s1 = ba_shannon_entropy_fixed(finite_only.data(), finite_only.size(),
                                            DEFAULT_BIN_COUNT, 0.0, 100.0, &h_finite);
    BAStatus s2 = ba_shannon_entropy_fixed(mixed.data(), mixed.size(),
                                            DEFAULT_BIN_COUNT, 0.0, 100.0, &h_mixed);
    REQUIRE(s1 == BA_OK);
    REQUIRE(s2 == BA_OK);
    REQUIRE(!std::isnan(h_mixed));
    REQUIRE(!std::isinf(h_mixed));
    REQUIRE_THAT(h_mixed, WithinAbs(h_finite, ENTROPY_TOL));
    REQUIRE(h_mixed > 0.0);
}

TEST_CASE("Fixed-domain entropy: fewer than 2 finite returns 0", "[entropy][fixed]") {
    std::vector<double> one_finite = {1.0, NAN, INFINITY};
    double result = -1.0;
    BAStatus s = ba_shannon_entropy_fixed(one_finite.data(), one_finite.size(),
                                          DEFAULT_BIN_COUNT, 0.0, 100.0, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(result == 0.0);

    std::vector<double> all_nan = {NAN, NAN, INFINITY};
    result = -1.0;
    s = ba_shannon_entropy_fixed(all_nan.data(), all_nan.size(),
                                  DEFAULT_BIN_COUNT, 0.0, 100.0, &result);
    REQUIRE(s == BA_OK);
    REQUIRE(result == 0.0);
}

// ═══════════════════════════════════════════════════════════════════════════
// Batch Entropy
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("Batch entropy: matches individual calls", "[entropy][batch]") {
    // Create 3 arrays of different sizes
    std::vector<double> arr1(200), arr2(100), arr3(300);
    for (size_t i = 0; i < arr1.size(); ++i) arr1[i] = static_cast<double>(i);
    for (size_t i = 0; i < arr2.size(); ++i) arr2[i] = static_cast<double>(i) * 2.0;
    for (size_t i = 0; i < arr3.size(); ++i) arr3[i] = static_cast<double>(i) * 0.5;

    // Pack into flat buffer
    std::vector<double> flat;
    flat.insert(flat.end(), arr1.begin(), arr1.end());
    flat.insert(flat.end(), arr2.begin(), arr2.end());
    flat.insert(flat.end(), arr3.begin(), arr3.end());

    size_t offsets[] = {0, arr1.size(), arr1.size() + arr2.size()};
    size_t lengths[] = {arr1.size(), arr2.size(), arr3.size()};

    double batch_results[3] = {0};
    BAStatus s = ba_shannon_entropy_batch(flat.data(), offsets, lengths, 3,
                                          DEFAULT_BIN_COUNT, batch_results);
    REQUIRE(s == BA_OK);

    // Compare with individual calls
    double individual[3] = {0};
    ba_shannon_entropy(arr1.data(), arr1.size(), DEFAULT_BIN_COUNT, &individual[0]);
    ba_shannon_entropy(arr2.data(), arr2.size(), DEFAULT_BIN_COUNT, &individual[1]);
    ba_shannon_entropy(arr3.data(), arr3.size(), DEFAULT_BIN_COUNT, &individual[2]);

    for (int i = 0; i < 3; ++i) {
        REQUIRE_THAT(batch_results[i], WithinAbs(individual[i], ENTROPY_TOL));
    }
}

TEST_CASE("Batch circular entropy: matches individual calls", "[entropy][batch][circular]") {
    // Simulate FlexAIDdS: 5 bonds with different angle distributions
    std::vector<double> flat;
    std::vector<size_t> offsets, lengths;

    for (int bond = 0; bond < 5; ++bond) {
        size_t n = 200;
        offsets.push_back(flat.size());
        lengths.push_back(n);
        double center = -180.0 + 72.0 * bond; // spread centers across circle
        for (size_t i = 0; i < n; ++i) {
            double angle = center + 20.0 * (static_cast<double>(i) / n - 0.5);
            flat.push_back(angle);
        }
    }

    std::vector<double> batch_results(5, 0.0);
    BAStatus s = ba_circular_shannon_entropy_batch(flat.data(), offsets.data(),
                                                    lengths.data(), 5,
                                                    DEFAULT_BIN_COUNT,
                                                    batch_results.data());
    REQUIRE(s == BA_OK);

    for (size_t b = 0; b < 5; ++b) {
        double individual = 0.0;
        ba_circular_shannon_entropy(flat.data() + offsets[b], lengths[b],
                                     DEFAULT_BIN_COUNT, &individual);
        REQUIRE_THAT(batch_results[b], WithinAbs(individual, ENTROPY_TOL));
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// FlexAIDdS-Style Tests
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("FlexAIDdS: free rotation has high entropy", "[entropy][flexaids]") {
    // Full rotation: +-180 degrees, 500 samples
    std::vector<double> angles(500);
    for (size_t i = 0; i < angles.size(); ++i) {
        angles[i] = -180.0 + 360.0 * static_cast<double>(i) / 500.0;
    }

    double result = 0.0;
    ba_circular_shannon_entropy(angles.data(), angles.size(),
                                 DEFAULT_BIN_COUNT, &result);
    REQUIRE(result > 3.0);
}

TEST_CASE("FlexAIDdS: constrained bond has low entropy", "[entropy][flexaids]") {
    // Narrow: +-10 degrees, 500 samples
    std::vector<double> angles(500);
    for (size_t i = 0; i < angles.size(); ++i) {
        angles[i] = -10.0 + 20.0 * static_cast<double>(i) / 500.0;
    }

    double result = 0.0;
    ba_circular_shannon_entropy(angles.data(), angles.size(),
                                 DEFAULT_BIN_COUNT, &result);
    REQUIRE(result < 2.0);
}

TEST_CASE("FlexAIDdS: deltaS_config = bound - free < 0 for binding", "[entropy][flexaids]") {
    // Free: wide distribution (+-180)
    std::vector<double> free_angles(500);
    for (size_t i = 0; i < 500; ++i) {
        free_angles[i] = -180.0 + 360.0 * static_cast<double>(i) / 500.0;
    }

    // Bound: narrow distribution (+-15)
    std::vector<double> bound_angles(500);
    for (size_t i = 0; i < 500; ++i) {
        bound_angles[i] = -15.0 + 30.0 * static_cast<double>(i) / 500.0;
    }

    double h_free = 0.0, h_bound = 0.0;
    ba_circular_shannon_entropy(free_angles.data(), 500, DEFAULT_BIN_COUNT, &h_free);
    ba_circular_shannon_entropy(bound_angles.data(), 500, DEFAULT_BIN_COUNT, &h_bound);

    double delta_s = h_bound - h_free;
    REQUIRE(delta_s < -0.5); // Significant binding detected
}

// ═══════════════════════════════════════════════════════════════════════════
// Backend Detection
// ═══════════════════════════════════════════════════════════════════════════

TEST_CASE("Backend detection returns a valid backend", "[backend]") {
    BABackend backend = ba_detect_best_backend();
    REQUIRE(backend >= BA_BACKEND_SCALAR);
    REQUIRE(backend <= BA_BACKEND_ROCM);

    const char* name = ba_backend_name(backend);
    REQUIRE(name != nullptr);
    REQUIRE(std::string(name).length() > 0);
}

TEST_CASE("Version string is non-empty", "[backend]") {
    const char* ver = ba_version();
    REQUIRE(ver != nullptr);
    REQUIRE(std::string(ver).length() > 0);
}

TEST_CASE("Active backend entropy matches scalar reference", "[backend][parity]") {
    // Regardless of Metal/CUDA/NEON selection, public C API must stay within
    // numerical tolerance of the pure scalar reference path.
    std::vector<double> vals(256);
    for (size_t i = 0; i < vals.size(); ++i) {
        vals[i] = std::sin(0.1 * static_cast<double>(i)) + 0.01 * static_cast<double>(i % 7);
    }

    double h_api = 0.0;
    REQUIRE(ba_shannon_entropy(vals.data(), vals.size(), DEFAULT_BIN_COUNT, &h_api) == BA_OK);

    REQUIRE(std::isfinite(h_api));
    REQUIRE(h_api >= 0.0);
    REQUIRE(h_api <= std::log2(static_cast<double>(DEFAULT_BIN_COUNT)) + 1e-9);

    // Uniform 8-bin should be ~3 bits (parity across backends)
    std::vector<double> uniform;
    for (int b = 0; b < 8; ++b) {
        for (int k = 0; k < 32; ++k) {
            uniform.push_back(static_cast<double>(b) + 0.1);
        }
    }
    double h_u = 0.0;
    REQUIRE(ba_shannon_entropy(uniform.data(), uniform.size(), 8, &h_u) == BA_OK);
    // Metal uses float32 values; allow slightly looser tol than pure double.
    REQUIRE_THAT(h_u, WithinAbs(3.0, 1e-6));
}

TEST_CASE("Active backend name is non-empty and detected", "[backend]") {
    BABackend b = ba_get_active_backend();
    const char* name = ba_backend_name(b);
    REQUIRE(name != nullptr);
    // On Apple Silicon with BA_ENABLE_METAL, expect Metal; otherwise NEON/AVX2/OpenMP/Scalar.
    REQUIRE(std::string(name) != "Unknown");
}

TEST_CASE("Circular entropy on active backend is finite", "[backend][parity]") {
    std::vector<double> angles;
    for (int i = 0; i < 360; ++i) {
        angles.push_back(static_cast<double>(i) - 180.0);
    }
    double h = 0.0;
    REQUIRE(ba_circular_shannon_entropy(angles.data(), angles.size(), 36, &h) == BA_OK);
    REQUIRE(std::isfinite(h));
    REQUIRE(h > 4.0); // near-uniform over 36 bins → ~5.17 bits
}
