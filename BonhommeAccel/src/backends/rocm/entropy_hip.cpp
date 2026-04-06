/*
 * entropy_hip.cpp — ROCm/HIP-accelerated Shannon entropy.
 *
 * Near-identical to the CUDA implementation using HIP's CUDA compatibility layer.
 * HIP provides hipified versions of all CUDA runtime functions.
 */

#if defined(BA_HAS_ROCM)

#include <hip/hip_runtime.h>
#include <cmath>
#include <cstddef>

namespace ba::rocm {

// ═══════════════════════════════════════════════════════════════════════════
// Histogram Kernels
// ═══════════════════════════════════════════════════════════════════════════

__global__ void shannon_histogram_kernel(
    const double* __restrict__ data, size_t count,
    int bin_count, double min_val, double bin_width,
    int* __restrict__ bins
) {
    extern __shared__ int shared_bins[];

    for (int i = threadIdx.x; i < bin_count; i += blockDim.x) {
        shared_bins[i] = 0;
    }
    __syncthreads();

    for (size_t idx = threadIdx.x; idx < count; idx += blockDim.x) {
        double v = data[idx];
        if (isfinite(v)) {
            int bin = min(bin_count - 1, (int)((v - min_val) / bin_width));
            atomicAdd(&shared_bins[bin], 1);
        }
    }
    __syncthreads();

    for (int i = threadIdx.x; i < bin_count; i += blockDim.x) {
        bins[i] = shared_bins[i];
    }
}

__global__ void circular_histogram_kernel(
    const double* __restrict__ data, size_t count,
    int bin_count, double bin_width,
    int* __restrict__ bins
) {
    extern __shared__ int shared_bins[];

    for (int i = threadIdx.x; i < bin_count; i += blockDim.x) {
        shared_bins[i] = 0;
    }
    __syncthreads();

    for (size_t idx = threadIdx.x; idx < count; idx += blockDim.x) {
        double a = data[idx];
        if (isfinite(a)) {
            a = fmod(a, 360.0);
            if (a > 180.0) a -= 360.0;
            if (a < -180.0) a += 360.0;
            int bin = min(bin_count - 1, (int)((a + 180.0) / bin_width));
            atomicAdd(&shared_bins[bin], 1);
        }
    }
    __syncthreads();

    for (int i = threadIdx.x; i < bin_count; i += blockDim.x) {
        bins[i] = shared_bins[i];
    }
}

__global__ void entropy_from_histogram_kernel(
    const int* __restrict__ bins, int bin_count, int total,
    double* __restrict__ out_entropy
) {
    extern __shared__ double shared_entropy[];

    double local_sum = 0.0;
    double d_total = (double)total;

    for (int i = threadIdx.x; i < bin_count; i += blockDim.x) {
        int c = bins[i];
        if (c > 0) {
            double p = (double)c / d_total;
            local_sum -= p * log2(p);
        }
    }

    shared_entropy[threadIdx.x] = local_sum;
    __syncthreads();

    for (int stride = blockDim.x / 2; stride > 0; stride >>= 1) {
        if (threadIdx.x < stride) {
            shared_entropy[threadIdx.x] += shared_entropy[threadIdx.x + stride];
        }
        __syncthreads();
    }

    if (threadIdx.x == 0) {
        *out_entropy = shared_entropy[0];
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// Batch Entropy — Host Functions
// ═══════════════════════════════════════════════════════════════════════════

void shannon_entropy_batch_hip(
    const double* flat, const size_t* offsets, const size_t* lengths,
    size_t batch_count, int bin_count, double* out_entropies
) {
    constexpr int BLOCK_SIZE = 256;

    size_t total_elements = 0;
    for (size_t b = 0; b < batch_count; ++b) total_elements += lengths[b];

    double* d_flat = nullptr;
    int* d_bins = nullptr;
    double* d_entropy = nullptr;

    hipMalloc(&d_flat, total_elements * sizeof(double));
    hipMalloc(&d_bins, bin_count * sizeof(int));
    hipMalloc(&d_entropy, sizeof(double));

    hipMemcpy(d_flat, flat, total_elements * sizeof(double), hipMemcpyHostToDevice);

    size_t shared_hist = bin_count * sizeof(int);
    size_t shared_entropy_sz = BLOCK_SIZE * sizeof(double);

    for (size_t b = 0; b < batch_count; ++b) {
        size_t n = lengths[b];
        if (n < 2) { out_entropies[b] = 0.0; continue; }

        double min_val = flat[offsets[b]], max_val = flat[offsets[b]];
        int clean_count = 0;
        for (size_t i = 0; i < n; ++i) {
            double v = flat[offsets[b] + i];
            if (std::isfinite(v)) {
                if (v < min_val) min_val = v;
                if (v > max_val) max_val = v;
                ++clean_count;
            }
        }
        if (clean_count < 2 || max_val <= min_val) { out_entropies[b] = 0.0; continue; }

        double bin_width = (max_val - min_val) / (double)bin_count;
        hipMemset(d_bins, 0, bin_count * sizeof(int));

        hipLaunchKernelGGL(shannon_histogram_kernel, 1, BLOCK_SIZE, shared_hist, 0,
            d_flat + offsets[b], n, bin_count, min_val, bin_width, d_bins);

        hipLaunchKernelGGL(entropy_from_histogram_kernel, 1, BLOCK_SIZE, shared_entropy_sz, 0,
            d_bins, bin_count, clean_count, d_entropy);

        hipMemcpy(&out_entropies[b], d_entropy, sizeof(double), hipMemcpyDeviceToHost);
    }

    hipFree(d_flat);
    hipFree(d_bins);
    hipFree(d_entropy);
}

void circular_shannon_entropy_batch_hip(
    const double* flat, const size_t* offsets, const size_t* lengths,
    size_t batch_count, int bin_count, double* out_entropies
) {
    constexpr int BLOCK_SIZE = 256;

    size_t total_elements = 0;
    for (size_t b = 0; b < batch_count; ++b) total_elements += lengths[b];

    double* d_flat = nullptr;
    int* d_bins = nullptr;
    double* d_entropy = nullptr;

    hipMalloc(&d_flat, total_elements * sizeof(double));
    hipMalloc(&d_bins, bin_count * sizeof(int));
    hipMalloc(&d_entropy, sizeof(double));

    hipMemcpy(d_flat, flat, total_elements * sizeof(double), hipMemcpyHostToDevice);

    double bin_width = 360.0 / (double)bin_count;
    size_t shared_hist = bin_count * sizeof(int);
    size_t shared_entropy_sz = BLOCK_SIZE * sizeof(double);

    for (size_t b = 0; b < batch_count; ++b) {
        size_t n = lengths[b];
        if (n < 2) { out_entropies[b] = 0.0; continue; }

        int clean_count = 0;
        for (size_t i = 0; i < n; ++i) {
            if (std::isfinite(flat[offsets[b] + i])) ++clean_count;
        }
        if (clean_count < 2) { out_entropies[b] = 0.0; continue; }

        hipMemset(d_bins, 0, bin_count * sizeof(int));

        hipLaunchKernelGGL(circular_histogram_kernel, 1, BLOCK_SIZE, shared_hist, 0,
            d_flat + offsets[b], n, bin_count, bin_width, d_bins);

        hipLaunchKernelGGL(entropy_from_histogram_kernel, 1, BLOCK_SIZE, shared_entropy_sz, 0,
            d_bins, bin_count, clean_count, d_entropy);

        hipMemcpy(&out_entropies[b], d_entropy, sizeof(double), hipMemcpyDeviceToHost);
    }

    hipFree(d_flat);
    hipFree(d_bins);
    hipFree(d_entropy);
}

} // namespace ba::rocm

#endif // BA_HAS_ROCM
