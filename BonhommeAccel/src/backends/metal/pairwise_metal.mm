/*
 * pairwise_metal.mm — Metal compute dispatch for O(n^2) pairwise scoring.
 *
 * Uses the pairwise_abs_diff MSL kernel for double-array distance computation.
 * For custom scoring functions (host callbacks), falls back to CPU.
 */

#if defined(__APPLE__) && !defined(BA_SKIP_METAL)

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "metal_shaders.h"
#include "../../include/BonhommeAccel.h"
#include <cstddef>
#include <cstdint>

namespace ba::metal {

// Forward declarations from metal_runtime.mm
bool metal_is_available();
id<MTLDevice> metal_device();
id<MTLCommandQueue> metal_queue();
id<MTLComputePipelineState> metal_pipeline(const std::string& kernel_name,
                                             const char* msl_source);

void pairwise_abs_diff_metal(const double* data, size_t n, double* out_scores) {
    if (!metal_is_available() || !data || !out_scores || n < 2) return;

    size_t num_pairs = n * (n - 1) / 2;

    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();

        auto pipeline = metal_pipeline("pairwise_abs_diff", kPairwiseScoreKernel);
        if (!pipeline) return;

        id<MTLBuffer> data_buf = [dev newBufferWithBytes:data
                                                  length:n * sizeof(double)
                                                 options:MTLResourceStorageModeShared];
        id<MTLBuffer> scores_buf = [dev newBufferWithLength:num_pairs * sizeof(double)
                                                    options:MTLResourceStorageModeShared];

        uint32_t un = static_cast<uint32_t>(n);

        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        [enc setComputePipelineState:pipeline];
        [enc setBuffer:data_buf offset:0 atIndex:0];
        [enc setBuffer:scores_buf offset:0 atIndex:1];
        [enc setBytes:&un length:sizeof(un) atIndex:2];

        NSUInteger threadGroupSize = std::min(
            static_cast<NSUInteger>(pipeline.maxTotalThreadsPerThreadgroup),
            static_cast<NSUInteger>(num_pairs));
        [enc dispatchThreads:MTLSizeMake(num_pairs, 1, 1)
    threadsPerThreadgroup:MTLSizeMake(threadGroupSize, 1, 1)];
        [enc endEncoding];
        [cmd commit];
        [cmd waitUntilCompleted];

        memcpy(out_scores, [scores_buf contents], num_pairs * sizeof(double));
    }
}

} // namespace ba::metal

#endif // __APPLE__ && !BA_SKIP_METAL
