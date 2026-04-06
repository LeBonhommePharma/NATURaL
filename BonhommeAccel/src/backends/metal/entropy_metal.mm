/*
 * entropy_metal.mm — Metal compute dispatch for Shannon entropy.
 *
 * Creates Metal buffers, encodes histogram + entropy reduction kernels,
 * and reads back results. Uses the cached pipeline from metal_runtime.mm.
 */

#if defined(__APPLE__) && !defined(BA_SKIP_METAL)

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "metal_shaders.h"
#include <cmath>
#include <cstddef>
#include <vector>

namespace ba::metal {

// Forward declarations from metal_runtime.mm
bool metal_is_available();
id<MTLDevice> metal_device();
id<MTLCommandQueue> metal_queue();
id<MTLComputePipelineState> metal_pipeline(const std::string& kernel_name,
                                             const char* msl_source);

// ═══════════════════════════════════════════════════════════════════════════
// Helper: compute entropy from histogram on GPU
// ═══════════════════════════════════════════════════════════════════════════

static double entropy_from_bins_gpu(id<MTLBuffer> bins_buffer, uint32_t bin_count,
                                     double total) {
    auto pipeline = metal_pipeline("entropy_reduction", kEntropyReductionKernel);
    if (!pipeline) return -1.0;

    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();

        // Single threadgroup for small bin counts (typically 32)
        uint32_t tg_size = 256;
        id<MTLBuffer> partial = [dev newBufferWithLength:sizeof(double)
                                                 options:MTLResourceStorageModeShared];

        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        [enc setComputePipelineState:pipeline];
        [enc setBuffer:bins_buffer offset:0 atIndex:0];
        [enc setBuffer:partial offset:0 atIndex:1];
        [enc setBytes:&bin_count length:sizeof(bin_count) atIndex:2];
        [enc setBytes:&total length:sizeof(total) atIndex:3];

        MTLSize gridSize = MTLSizeMake(tg_size, 1, 1);
        MTLSize tgSize = MTLSizeMake(tg_size, 1, 1);
        [enc dispatchThreads:gridSize threadsPerThreadgroup:tgSize];
        [enc endEncoding];
        [cmd commit];
        [cmd waitUntilCompleted];

        double result = *static_cast<double*>([partial contents]);
        return result;
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// Single Entropy
// ═══════════════════════════════════════════════════════════════════════════

double shannon_entropy_metal(const double* values, size_t count, int bin_count) {
    if (!metal_is_available() || !values || count < 2 || bin_count < 1)
        return -1.0; // Signal fallback

    // Find min/max and count finite values (host-side, small overhead)
    double min_val = HUGE_VAL, max_val = -HUGE_VAL;
    uint32_t clean_count = 0;
    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(values[i])) {
            min_val = std::min(min_val, values[i]);
            max_val = std::max(max_val, values[i]);
            ++clean_count;
        }
    }
    if (clean_count < 2 || max_val <= min_val) return 0.0;

    double bin_width = (max_val - min_val) / static_cast<double>(bin_count);

    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();

        auto pipeline = metal_pipeline("shannon_histogram", kShannonHistogramKernel);
        if (!pipeline) return -1.0;

        // Create buffers
        id<MTLBuffer> data_buf = [dev newBufferWithBytes:values
                                                  length:count * sizeof(double)
                                                 options:MTLResourceStorageModeShared];
        id<MTLBuffer> bins_buf = [dev newBufferWithLength:static_cast<NSUInteger>(bin_count) * sizeof(uint32_t)
                                                  options:MTLResourceStorageModeShared];
        memset([bins_buf contents], 0, static_cast<size_t>(bin_count) * sizeof(uint32_t));

        uint32_t ucount = static_cast<uint32_t>(count);
        uint32_t ubin_count = static_cast<uint32_t>(bin_count);

        // Encode histogram kernel
        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        [enc setComputePipelineState:pipeline];
        [enc setBuffer:data_buf offset:0 atIndex:0];
        [enc setBuffer:bins_buf offset:0 atIndex:1];
        [enc setBytes:&ucount length:sizeof(ucount) atIndex:2];
        [enc setBytes:&ubin_count length:sizeof(ubin_count) atIndex:3];
        [enc setBytes:&min_val length:sizeof(min_val) atIndex:4];
        [enc setBytes:&bin_width length:sizeof(bin_width) atIndex:5];

        NSUInteger threadGroupSize = std::min(static_cast<NSUInteger>(pipeline.maxTotalThreadsPerThreadgroup),
                                               static_cast<NSUInteger>(count));
        MTLSize gridSize = MTLSizeMake(count, 1, 1);
        MTLSize tgSize = MTLSizeMake(threadGroupSize, 1, 1);
        [enc dispatchThreads:gridSize threadsPerThreadgroup:tgSize];
        [enc endEncoding];
        [cmd commit];
        [cmd waitUntilCompleted];

        // Compute entropy from histogram
        double total = static_cast<double>(clean_count);
        return entropy_from_bins_gpu(bins_buf, ubin_count, total);
    }
}

double circular_shannon_entropy_metal(const double* angles, size_t count, int bin_count) {
    if (!metal_is_available() || !angles || count < 2 || bin_count < 1)
        return -1.0;

    uint32_t clean_count = 0;
    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(angles[i])) ++clean_count;
    }
    if (clean_count < 2) return 0.0;

    double bin_width = 360.0 / static_cast<double>(bin_count);

    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();

        auto pipeline = metal_pipeline("circular_histogram", kCircularHistogramKernel);
        if (!pipeline) return -1.0;

        id<MTLBuffer> data_buf = [dev newBufferWithBytes:angles
                                                  length:count * sizeof(double)
                                                 options:MTLResourceStorageModeShared];
        id<MTLBuffer> bins_buf = [dev newBufferWithLength:static_cast<NSUInteger>(bin_count) * sizeof(uint32_t)
                                                  options:MTLResourceStorageModeShared];
        memset([bins_buf contents], 0, static_cast<size_t>(bin_count) * sizeof(uint32_t));

        uint32_t ucount = static_cast<uint32_t>(count);
        uint32_t ubin_count = static_cast<uint32_t>(bin_count);

        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        [enc setComputePipelineState:pipeline];
        [enc setBuffer:data_buf offset:0 atIndex:0];
        [enc setBuffer:bins_buf offset:0 atIndex:1];
        [enc setBytes:&ucount length:sizeof(ucount) atIndex:2];
        [enc setBytes:&ubin_count length:sizeof(ubin_count) atIndex:3];
        [enc setBytes:&bin_width length:sizeof(bin_width) atIndex:4];

        NSUInteger threadGroupSize = std::min(static_cast<NSUInteger>(pipeline.maxTotalThreadsPerThreadgroup),
                                               static_cast<NSUInteger>(count));
        [enc dispatchThreads:MTLSizeMake(count, 1, 1)
    threadsPerThreadgroup:MTLSizeMake(threadGroupSize, 1, 1)];
        [enc endEncoding];
        [cmd commit];
        [cmd waitUntilCompleted];

        return entropy_from_bins_gpu(bins_buf, ubin_count, static_cast<double>(clean_count));
    }
}

// ═══════════════════════════════════════════════════════════════════════════
// Batch Entropy
// ═══════════════════════════════════════════════════════════════════════════

void shannon_entropy_batch_metal(const double* flat, const size_t* offsets,
                                  const size_t* lengths, size_t batch_count,
                                  int bin_count, double* out_entropies) {
    for (size_t b = 0; b < batch_count; ++b) {
        double result = shannon_entropy_metal(flat + offsets[b], lengths[b], bin_count);
        out_entropies[b] = (result >= 0.0) ? result : 0.0;
    }
}

void circular_shannon_entropy_batch_metal(const double* flat, const size_t* offsets,
                                           const size_t* lengths, size_t batch_count,
                                           int bin_count, double* out_entropies) {
    for (size_t b = 0; b < batch_count; ++b) {
        double result = circular_shannon_entropy_metal(flat + offsets[b], lengths[b], bin_count);
        out_entropies[b] = (result >= 0.0) ? result : 0.0;
    }
}

} // namespace ba::metal

#endif // __APPLE__ && !BA_SKIP_METAL
