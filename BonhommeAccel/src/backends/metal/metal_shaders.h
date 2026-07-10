/*
 * metal_shaders.h — Metal Shading Language kernel source strings.
 *
 * Embedded as constexpr C++ strings for runtime compilation via MTLDevice.
 * Apple GPUs do not support double in MSL — all kernels use float.
 * Host converts double↔float; histogram bins stay exact (atomic_uint).
 */

#ifndef BA_METAL_SHADERS_H
#define BA_METAL_SHADERS_H

namespace ba::metal {

constexpr const char* kShannonHistogramKernel = R"MSL(
#include <metal_stdlib>
using namespace metal;

kernel void shannon_histogram(
    device const float* data       [[buffer(0)]],
    device atomic_uint* bins       [[buffer(1)]],
    constant uint& count           [[buffer(2)]],
    constant uint& bin_count       [[buffer(3)]],
    constant float& min_val        [[buffer(4)]],
    constant float& bin_width      [[buffer(5)]],
    uint tid                       [[thread_position_in_grid]]
) {
    if (tid >= count) return;

    float v = data[tid];
    if (!isfinite(v)) return;

    int idx = (int)((v - min_val) / bin_width);
    if (idx < 0) idx = 0;
    if (idx >= (int)bin_count) idx = (int)bin_count - 1;
    atomic_fetch_add_explicit(&bins[idx], 1u, memory_order_relaxed);
}
)MSL";

constexpr const char* kCircularHistogramKernel = R"MSL(
#include <metal_stdlib>
using namespace metal;

kernel void circular_histogram(
    device const float* data       [[buffer(0)]],
    device atomic_uint* bins       [[buffer(1)]],
    constant uint& count           [[buffer(2)]],
    constant uint& bin_count       [[buffer(3)]],
    constant float& bin_width      [[buffer(4)]],
    uint tid                       [[thread_position_in_grid]]
) {
    if (tid >= count) return;

    float a = data[tid];
    if (!isfinite(a)) return;

    // Wrap to [-180, 180)
    a = fmod(a, 360.0f);
    if (a > 180.0f) a -= 360.0f;
    if (a < -180.0f) a += 360.0f;

    int idx = (int)((a + 180.0f) / bin_width);
    if (idx < 0) idx = 0;
    if (idx >= (int)bin_count) idx = (int)bin_count - 1;
    atomic_fetch_add_explicit(&bins[idx], 1u, memory_order_relaxed);
}
)MSL";

// Threadgroup reduction of x/y sums for Pearson means (float32).
constexpr const char* kPearsonMeansKernel = R"MSL(
#include <metal_stdlib>
using namespace metal;

kernel void pearson_means(
    device const float* x          [[buffer(0)]],
    device const float* y          [[buffer(1)]],
    device atomic_float* out_sx    [[buffer(2)]],
    device atomic_float* out_sy    [[buffer(3)]],
    constant uint& count           [[buffer(4)]],
    uint tid                       [[thread_position_in_grid]],
    uint tid_in_tg                 [[thread_position_in_threadgroup]],
    uint tg_size                   [[threads_per_threadgroup]]
) {
    threadgroup float sx_shared[256];
    threadgroup float sy_shared[256];

    float lsx = 0.0f, lsy = 0.0f;
    if (tid < count) {
        lsx = x[tid];
        lsy = y[tid];
    }

    sx_shared[tid_in_tg] = lsx;
    sy_shared[tid_in_tg] = lsy;
    threadgroup_barrier(mem_flags::mem_threadgroup);

    for (uint stride = tg_size / 2; stride > 0; stride >>= 1) {
        if (tid_in_tg < stride) {
            sx_shared[tid_in_tg] += sx_shared[tid_in_tg + stride];
            sy_shared[tid_in_tg] += sy_shared[tid_in_tg + stride];
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    if (tid_in_tg == 0) {
        atomic_fetch_add_explicit(out_sx, sx_shared[0], memory_order_relaxed);
        atomic_fetch_add_explicit(out_sy, sy_shared[0], memory_order_relaxed);
    }
}
)MSL";

constexpr const char* kPearsonMomentsKernel = R"MSL(
#include <metal_stdlib>
using namespace metal;

kernel void pearson_moments(
    device const float* x          [[buffer(0)]],
    device const float* y          [[buffer(1)]],
    device atomic_float* out_sxy   [[buffer(2)]],
    device atomic_float* out_sx2   [[buffer(3)]],
    device atomic_float* out_sy2   [[buffer(4)]],
    constant uint& count           [[buffer(5)]],
    constant float& mean_x         [[buffer(6)]],
    constant float& mean_y         [[buffer(7)]],
    uint tid                       [[thread_position_in_grid]],
    uint tid_in_tg                 [[thread_position_in_threadgroup]],
    uint tg_size                   [[threads_per_threadgroup]]
) {
    threadgroup float sxy_s[256];
    threadgroup float sx2_s[256];
    threadgroup float sy2_s[256];

    float lsxy = 0.0f, lsx2 = 0.0f, lsy2 = 0.0f;
    if (tid < count) {
        float dx = x[tid] - mean_x;
        float dy = y[tid] - mean_y;
        lsxy = dx * dy;
        lsx2 = dx * dx;
        lsy2 = dy * dy;
    }

    sxy_s[tid_in_tg] = lsxy;
    sx2_s[tid_in_tg] = lsx2;
    sy2_s[tid_in_tg] = lsy2;
    threadgroup_barrier(mem_flags::mem_threadgroup);

    for (uint stride = tg_size / 2; stride > 0; stride >>= 1) {
        if (tid_in_tg < stride) {
            sxy_s[tid_in_tg] += sxy_s[tid_in_tg + stride];
            sx2_s[tid_in_tg] += sx2_s[tid_in_tg + stride];
            sy2_s[tid_in_tg] += sy2_s[tid_in_tg + stride];
        }
        threadgroup_barrier(mem_flags::mem_threadgroup);
    }

    if (tid_in_tg == 0) {
        atomic_fetch_add_explicit(out_sxy, sxy_s[0], memory_order_relaxed);
        atomic_fetch_add_explicit(out_sx2, sx2_s[0], memory_order_relaxed);
        atomic_fetch_add_explicit(out_sy2, sy2_s[0], memory_order_relaxed);
    }
}
)MSL";

constexpr const char* kPairwiseScoreKernel = R"MSL(
#include <metal_stdlib>
using namespace metal;

// Upper-triangle |x_i - x_j| for float arrays.
kernel void pairwise_abs_diff(
    device const float* data           [[buffer(0)]],
    device float* scores               [[buffer(1)]],
    constant uint& n                   [[buffer(2)]],
    uint tid                           [[thread_position_in_grid]]
) {
    uint num_pairs = n * (n - 1) / 2;
    if (tid >= num_pairs) return;

    float nf = (float)n;
    float t = (float)tid;
    uint i = (uint)(nf - 0.5f - sqrt((nf - 0.5f) * (nf - 0.5f) - 2.0f * t));
    uint row_start = i * n - i * (i + 1) / 2;
    uint j = tid - row_start + i + 1;

    if (i < n && j < n && j > i) {
        scores[tid] = abs(data[i] - data[j]);
    }
}
)MSL";

} // namespace ba::metal

#endif // BA_METAL_SHADERS_H
