/*
 * reference_values.h — Golden values for numerical parity tests.
 *
 * These values are derived from BonhommeCore's Swift test outputs
 * (EntropyCalculatorTests, FlexAIDdSAnalyzerTests, CrossDomainValidatorTests).
 *
 * Tolerance: 1e-10 for entropy, 1e-6 for correlation/regression.
 */

#ifndef BA_TESTS_REFERENCE_VALUES_H
#define BA_TESTS_REFERENCE_VALUES_H

namespace ba::test {

// Entropy tolerance (bits)
constexpr double ENTROPY_TOL = 1e-10;

// Correlation/regression tolerance
constexpr double CORR_TOL = 1e-6;

// Incomplete beta / p-value tolerance
constexpr double PVAL_TOL = 1e-6;

// Maximum entropy for 32 bins: log2(32) = 5.0
constexpr double MAX_ENTROPY_32 = 5.0;

// Default bin count matching Swift EntropyCalculator
constexpr int DEFAULT_BIN_COUNT = 32;

} // namespace ba::test

#endif // BA_TESTS_REFERENCE_VALUES_H
