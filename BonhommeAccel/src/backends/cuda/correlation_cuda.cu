/*
 * correlation_cuda.cu — CUDA-accelerated Pearson correlation.
 *
 * Uses parallel reduction for dot products (sum_xy, sum_x2, sum_y2).
 */

#if defined(BA_HAS_CUDA)

#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <cmath>
#include <cstddef>

namespace ba::cuda {

// Warp-level reduction
__device__ double warp_reduce_sum(double val) {
    for (int offset = 16; offset > 0; offset >>= 1) {
        val += __shfl_down_sync(0xffffffff, val, offset);
    }
    return val;
}

// Block-level reduction
__device__ double block_reduce_sum(double val) {
    __shared__ double shared[32]; // One per warp

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

double pearson_correlation_cuda(const double* x, const double* y, size_t count) {
    if (count < 2) return 0.0;

    constexpr int BLOCK_SIZE = 256;
    int num_blocks = std::min(256, (int)((count + BLOCK_SIZE - 1) / BLOCK_SIZE));

    double *d_x, *d_y;
    double *d_sum_x, *d_sum_y, *d_sxy, *d_sx2, *d_sy2;

    cudaMalloc(&d_x, count * sizeof(double));
    cudaMalloc(&d_y, count * sizeof(double));
    cudaMalloc(&d_sum_x, sizeof(double));
    cudaMalloc(&d_sum_y, sizeof(double));
    cudaMalloc(&d_sxy, sizeof(double));
    cudaMalloc(&d_sx2, sizeof(double));
    cudaMalloc(&d_sy2, sizeof(double));

    cudaMemcpy(d_x, x, count * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_y, y, count * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemset(d_sum_x, 0, sizeof(double));
    cudaMemset(d_sum_y, 0, sizeof(double));
    cudaMemset(d_sxy, 0, sizeof(double));
    cudaMemset(d_sx2, 0, sizeof(double));
    cudaMemset(d_sy2, 0, sizeof(double));

    // Step 1: Compute means
    pearson_means_kernel<<<num_blocks, BLOCK_SIZE>>>(d_x, d_y, count, d_sum_x, d_sum_y);

    double sum_x, sum_y;
    cudaMemcpy(&sum_x, d_sum_x, sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(&sum_y, d_sum_y, sizeof(double), cudaMemcpyDeviceToHost);

    double mean_x = sum_x / (double)count;
    double mean_y = sum_y / (double)count;

    // Step 2: Compute correlation components
    pearson_corr_kernel<<<num_blocks, BLOCK_SIZE>>>(
        d_x, d_y, count, mean_x, mean_y, d_sxy, d_sx2, d_sy2
    );

    double sxy, sx2, sy2;
    cudaMemcpy(&sxy, d_sxy, sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(&sx2, d_sx2, sizeof(double), cudaMemcpyDeviceToHost);
    cudaMemcpy(&sy2, d_sy2, sizeof(double), cudaMemcpyDeviceToHost);

    cudaFree(d_x); cudaFree(d_y);
    cudaFree(d_sum_x); cudaFree(d_sum_y);
    cudaFree(d_sxy); cudaFree(d_sx2); cudaFree(d_sy2);

    double denom = sqrt(sx2 * sy2);
    return (denom > 0.0) ? (sxy / denom) : 0.0;
}

} // namespace ba::cuda

#endif // BA_HAS_CUDA
