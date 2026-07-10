/*
 * correlation_hip.cpp — ROCm/HIP Pearson correlation (parity with CUDA).
 */

#if defined(BA_HAS_ROCM)

#include "rocm_backend.h"
#include <hip/hip_runtime.h>
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <vector>

namespace ba::rocm {

__device__ double warp_reduce_sum(double val) {
    for (int offset = 16; offset > 0; offset >>= 1) {
        val += __shfl_down(val, offset);
    }
    return val;
}

__device__ double block_reduce_sum(double val) {
    __shared__ double shared[32];

    int lane = threadIdx.x % 32;
    int wid = threadIdx.x / 32;

    val = warp_reduce_sum(val);

    if (lane == 0) shared[wid] = val;
    __syncthreads();

    val = (threadIdx.x < blockDim.x / 32) ? shared[lane] : 0.0;
    if (wid == 0) val = warp_reduce_sum(val);

    return val;
}

__global__ void pearson_means_kernel(
    const double* __restrict__ x, const double* __restrict__ y,
    size_t count, double* __restrict__ out_sum_x, double* __restrict__ out_sum_y
) {
    double local_sx = 0.0, local_sy = 0.0;
    for (size_t i = threadIdx.x + blockIdx.x * blockDim.x; i < count;
         i += blockDim.x * gridDim.x) {
        local_sx += x[i];
        local_sy += y[i];
    }

    local_sx = block_reduce_sum(local_sx);
    local_sy = block_reduce_sum(local_sy);

    if (threadIdx.x == 0) {
        atomicAdd(out_sum_x, local_sx);
        atomicAdd(out_sum_y, local_sy);
    }
}

__global__ void pearson_corr_kernel(
    const double* __restrict__ x, const double* __restrict__ y,
    size_t count, double mean_x, double mean_y,
    double* __restrict__ out_sxy, double* __restrict__ out_sx2, double* __restrict__ out_sy2
) {
    double local_sxy = 0.0, local_sx2 = 0.0, local_sy2 = 0.0;

    for (size_t i = threadIdx.x + blockIdx.x * blockDim.x; i < count;
         i += blockDim.x * gridDim.x) {
        double dx = x[i] - mean_x;
        double dy = y[i] - mean_y;
        local_sxy += dx * dy;
        local_sx2 += dx * dx;
        local_sy2 += dy * dy;
    }

    local_sxy = block_reduce_sum(local_sxy);
    local_sx2 = block_reduce_sum(local_sx2);
    local_sy2 = block_reduce_sum(local_sy2);

    if (threadIdx.x == 0) {
        atomicAdd(out_sxy, local_sxy);
        atomicAdd(out_sx2, local_sx2);
        atomicAdd(out_sy2, local_sy2);
    }
}

double pearson_correlation_hip(const double* x, const double* y, size_t count) {
    if (!hip_is_available() || !x || !y || count < 2) return 0.0;

    std::vector<double> cx, cy;
    cx.reserve(count);
    cy.reserve(count);
    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(x[i]) && std::isfinite(y[i])) {
            cx.push_back(x[i]);
            cy.push_back(y[i]);
        }
    }
    size_t n = cx.size();
    if (n < 2) return 0.0;

    constexpr int BLOCK_SIZE = 256;
    int num_blocks = std::min(256, (int)((n + BLOCK_SIZE - 1) / BLOCK_SIZE));

    double *d_x = nullptr, *d_y = nullptr;
    double *d_sum_x = nullptr, *d_sum_y = nullptr;
    double *d_sxy = nullptr, *d_sx2 = nullptr, *d_sy2 = nullptr;

    if (hipMalloc(&d_x, n * sizeof(double)) != hipSuccess ||
        hipMalloc(&d_y, n * sizeof(double)) != hipSuccess ||
        hipMalloc(&d_sum_x, sizeof(double)) != hipSuccess ||
        hipMalloc(&d_sum_y, sizeof(double)) != hipSuccess ||
        hipMalloc(&d_sxy, sizeof(double)) != hipSuccess ||
        hipMalloc(&d_sx2, sizeof(double)) != hipSuccess ||
        hipMalloc(&d_sy2, sizeof(double)) != hipSuccess) {
        if (d_x) hipFree(d_x);
        if (d_y) hipFree(d_y);
        if (d_sum_x) hipFree(d_sum_x);
        if (d_sum_y) hipFree(d_sum_y);
        if (d_sxy) hipFree(d_sxy);
        if (d_sx2) hipFree(d_sx2);
        if (d_sy2) hipFree(d_sy2);
        return 0.0;
    }

    hipMemcpy(d_x, cx.data(), n * sizeof(double), hipMemcpyHostToDevice);
    hipMemcpy(d_y, cy.data(), n * sizeof(double), hipMemcpyHostToDevice);
    hipMemset(d_sum_x, 0, sizeof(double));
    hipMemset(d_sum_y, 0, sizeof(double));
    hipMemset(d_sxy, 0, sizeof(double));
    hipMemset(d_sx2, 0, sizeof(double));
    hipMemset(d_sy2, 0, sizeof(double));

    hipLaunchKernelGGL(pearson_means_kernel, dim3(num_blocks), dim3(BLOCK_SIZE),
                       0, 0, d_x, d_y, n, d_sum_x, d_sum_y);

    double sum_x = 0.0, sum_y = 0.0;
    hipMemcpy(&sum_x, d_sum_x, sizeof(double), hipMemcpyDeviceToHost);
    hipMemcpy(&sum_y, d_sum_y, sizeof(double), hipMemcpyDeviceToHost);

    double mean_x = sum_x / static_cast<double>(n);
    double mean_y = sum_y / static_cast<double>(n);

    hipLaunchKernelGGL(pearson_corr_kernel, dim3(num_blocks), dim3(BLOCK_SIZE),
                       0, 0, d_x, d_y, n, mean_x, mean_y, d_sxy, d_sx2, d_sy2);

    double sxy = 0.0, sx2 = 0.0, sy2 = 0.0;
    hipMemcpy(&sxy, d_sxy, sizeof(double), hipMemcpyDeviceToHost);
    hipMemcpy(&sx2, d_sx2, sizeof(double), hipMemcpyDeviceToHost);
    hipMemcpy(&sy2, d_sy2, sizeof(double), hipMemcpyDeviceToHost);

    hipFree(d_x); hipFree(d_y);
    hipFree(d_sum_x); hipFree(d_sum_y);
    hipFree(d_sxy); hipFree(d_sx2); hipFree(d_sy2);

    double denom = std::sqrt(sx2 * sy2);
    return (denom > 0.0) ? (sxy / denom) : 0.0;
}

} // namespace ba::rocm

#endif // BA_HAS_ROCM
