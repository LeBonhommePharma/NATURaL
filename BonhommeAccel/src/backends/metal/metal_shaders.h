/*
 * metal_shaders.h — Metal Shading Language kernel source strings.
 *
 * Embedded as constexpr C++ strings for runtime compilation via MTLDevice.
 * This avoids the need for .metal files in the build system.
 */

#ifndef BA_METAL_SHADERS_H
#define BA_METAL_SHADERS_H

namespace ba::metal {

constexpr const char* kShannonHistogramKernel = R"MSL(
#include <metal_stdlib>
using namespace metal;

kernel void shannon_histogram(
    device const double* data      [[buffer(0)]],
    device atomic_uint* bins       [[buffer(1)]],
    constant uint& count           [[buffer(2)]],
    constant uint& bin_count       [[buffer(3)]],
    constant double& min_val       [[buffer(4)]],
    constant double& bin_width     [[buffer(5)]],
    uint tid                       [[thread_position_in_grid]]
) {
    if (tid >= count) return;

    double v = data[tid];
    // Metal: isinf/isnan checks
    if (isinf(v) || isnan(v)) return;

    int idx = min((int)bin_count - 1, (int)((v - min_val) / bin_width));
    if (idx >= 0 && idx < (int)bin_count) {
        atomic_fetch_add_explicit(&bins[idx], 1u, memory_order_relaxed);
    }
}
)MSL";

constexpr const char* kCircularHistogramKernel = R"MSL(
#include <metal_stdlib>
using namespace metal;

kernel void circular_histogram(
    device const double* data      [[buffer(0)]],
    device atomic_uint* bins       [[buffer(1)]],
    constant uint& count           [[buffer(2)]],
    constant uint& bin_count       [[buffer(3)]],
    constant double& bin_width     [[buffer(4)]],
    uint tid                       [[thread_position_in_grid]]
) {
    if (tid >= count) return;

    double a = data[tid];
    if (isinf(a) || isnan(a)) return;

    // Wrap to [-180, 180)
    a = fmod(a, 360.0);
    if (a > 180.0) a -= 360.0;
    if (a < -180.0) a += 360.0;

    int idx = min((int)bin_count - 1, (int)((a + 180.0) / bin_width));
    if (idx >= 0 && idx < (int)bin_count) {
        atomic_fetch_add_explicit(&bins[idx], 1u, memory_order_relaxed);
    }
}
)MSL";

constexpr const char* kEntropyReductionKernel = R"MSL(
#include <metal_stdlib>
using namespace metal;

// Parallel reduction: each thread computes partial entropy for a subset of bins.
// Output per threadgroup into partial_sums, then reduce on host.
kernel void entropy_reduction(
    device const uint* bins            [[buffer(0)]],
    device double* partial_sums        [[buffer(1)]],
    constant uint& bin_count           [[buffer(2)]],
    constant double& total             [[buffer(3)]],
    uint tid                           [[thread_position_in_grid]],
    uint tg_size                       [[threads_per_threadgroup]],
    uint tg_id                         [[threadgroup_position_in_grid]],
    uint tid_in_tg                     [[thread_position_in_threadgroup]]
) {
    threadgroup double shared_sums[256];

    double local_sum = 0.0;

    // Each thread processes multiple bins
    for (uint i = tid; i < bin_count; i += tg_size) {
        uint c = bins[i];
        if (c > 0) {
            double p = (double)c / total;
            local_sum -= p * log2(p);
        }
    }

    shared_sums[tid_in_tg] = local_sum;
    threadgroup_barrier(mem_flags::mem_threadgroup);

    // Parallel reduction within threadgroup
    for (uint stride = tg_size / 2; stride > 0; stride >>= 1) {
        if (tid_in_tg < stride) {
            shared_sums[tid_in_tg] += shared_sums[tid_in_tg + stride];
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    if (tid_in_tg == 0) {
        partial_sums[tg_id] = shared_sums[0];
    }
}
)MSL";

constexpr const char* kPairwiseScoreKernel = R"MSL(
#include <metal_stdlib>
using namespace metal;

// Generic pairwise distance kernel for double arrays.
// Computes |data[i] - data[j]| for upper-triangle pairs.
kernel void pairwise_abs_diff(
    device const double* data          [[buffer(0)]],
    device double* scores              [[buffer(1)]],
    constant uint& n                   [[buffer(2)]],
    uint tid                           [[thread_position_in_grid]]
) {
    uint num_pairs = n * (n - 1) / 2;
    if (tid >= num_pairs) return;

    // Convert linear index to (i,j) pair
    double nf = (double)n;
    double t = (double)tid;
    uint i = (uint)(nf - 0.5 - sqrt((nf - 0.5) * (nf - 0.5) - 2.0 * t));
    uint row_start = i * n - i * (i + 1) / 2;
    uint j = tid - row_start + i + 1;

    if (i < n && j < n && j > i) {
        scores[tid] = abs(data[i] - data[j]);
    }
}
)MSL";

} // namespace ba::metal

#endif // BA_METAL_SHADERS_H
