/*
 * pairwise_metal.mm — Metal float32 pairwise |x_i - x_j| upper triangle.
 */

#if defined(__APPLE__) && defined(BA_HAS_METAL)

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "metal_backend.h"
#include "metal_shaders.h"
#include <algorithm>
#include <cstddef>
#include <vector>
#include <string>

namespace ba::metal {

id<MTLDevice> metal_device();
id<MTLCommandQueue> metal_queue();
id<MTLComputePipelineState> metal_pipeline(const std::string& kernel_name,
                                             const char* msl_source);

void pairwise_abs_diff_metal(const double* data, size_t n, double* out_scores) {
    if (!metal_is_available() || !data || !out_scores || n < 2) return;

    size_t num_pairs = n * (n - 1) / 2;
    std::vector<float> fdata(n);
    for (size_t i = 0; i < n; ++i) fdata[i] = static_cast<float>(data[i]);

    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();

        auto pipeline = metal_pipeline("pairwise_abs_diff", kPairwiseScoreKernel);
        if (!pipeline) return;

        id<MTLBuffer> data_buf = [dev newBufferWithBytes:fdata.data()
                                                  length:n * sizeof(float)
                                                 options:MTLResourceStorageModeShared];
        id<MTLBuffer> scores_buf = [dev newBufferWithLength:num_pairs * sizeof(float)
                                                    options:MTLResourceStorageModeShared];

        uint32_t un = static_cast<uint32_t>(n);

        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        [enc setComputePipelineState:pipeline];
        [enc setBuffer:data_buf offset:0 atIndex:0];
        [enc setBuffer:scores_buf offset:0 atIndex:1];
        [enc setBytes:&un length:sizeof(un) atIndex:2];

        NSUInteger maxTg = pipeline.maxTotalThreadsPerThreadgroup;
        NSUInteger threadGroupSize = std::min(maxTg, std::max<NSUInteger>(1, num_pairs));
        if (threadGroupSize > 256) threadGroupSize = 256;
        [enc dispatchThreads:MTLSizeMake(num_pairs, 1, 1)
      threadsPerThreadgroup:MTLSizeMake(threadGroupSize, 1, 1)];
        [enc endEncoding];
        [cmd commit];
        [cmd waitUntilCompleted];

        if (cmd.error == nil) {
            const float* fs = static_cast<const float*>([scores_buf contents]);
            for (size_t i = 0; i < num_pairs; ++i) {
                out_scores[i] = static_cast<double>(fs[i]);
            }
        }
    }
}

} // namespace ba::metal

#endif // __APPLE__ && BA_HAS_METAL
