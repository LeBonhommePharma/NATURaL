/*
 * incomplete_beta.h — Regularized incomplete beta function I_x(a, b).
 *
 * Mirrors CrossDomainValidator.swift's regularizedIncompleteBeta()
 * using Lentz's continued fraction algorithm.
 */

#ifndef BA_CORE_INCOMPLETE_BETA_H
#define BA_CORE_INCOMPLETE_BETA_H

#include <cstddef>

namespace ba::core {

/**
 * Regularized incomplete beta function I_x(a, b).
 * x in [0, 1], a > 0, b > 0.
 */
double regularized_incomplete_beta(double x, double a, double b);

/**
 * Two-tailed p-value for Pearson r via t-distribution.
 * t = r * sqrt(n-2) / sqrt(1 - r^2), df = n-2.
 */
double pearson_pvalue(double r, size_t n);

} // namespace ba::core

#endif // BA_CORE_INCOMPLETE_BETA_H
