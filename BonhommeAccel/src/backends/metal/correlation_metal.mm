/*
 * correlation_metal.mm — Metal float32 Pearson correlation.
 *
 * Filters non-finite pairs on the host (parity with scalar/CUDA), uploads
 * float buffers, reduces means + second moments on GPU. Returns NaN on
 * failure so the C API can fall back to NEON/scalar double precision.
 */

#if defined(__APPLE__) && defined(BA_HAS_METAL)

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "metal_backend.h"
#include "metal_shaders.h"
#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstring>
#include <limits>
#include <string>
#include <vector>

namespace ba::metal {

id<MTLDevice> metal_device();
id<MTLCommandQueue> metal_queue();
id<MTLComputePipelineState> metal_pipeline(const std::string& kernel_name,
                                             const char* msl_source);

double pearson_correlation_metal(const double* x, const double* y, size_t count) {
    if (!metal_is_available() || !x || !y || count < 2)
        return std::numeric_limits<double>::quiet_NaN();

    std::vector<float> cx, cy;
    cx.reserve(count);
    cy.reserve(count);
    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(x[i]) && std::isfinite(y[i])) {
            cx.push_back(static_cast<float>(x[i]));
            cy.push_back(static_cast<float>(y[i]));
        }
    }
    size_t n = cx.size();
    if (n < 2) return 0.0;

    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();

        auto means_pl = metal_pipeline("pearson_means", kPearsonMeansKernel);
        auto mom_pl = metal_pipeline("pearson_moments", kPearsonMomentsKernel);
        if (!means_pl || !mom_pl) return std::numeric_limits<double>::quiet_NaN();

        id<MTLBuffer> bx = [dev newBufferWithBytes:cx.data()
                                            length:n * sizeof(float)
                                           options:MTLResourceStorageModeShared];
        id<MTLBuffer> by = [dev newBufferWithBytes:cy.data()
                                            length:n * sizeof(float)
                                           options:MTLResourceStorageModeShared];
        id<MTLBuffer> bsx = [dev newBufferWithLength:sizeof(float)
                                             options:MTLResourceStorageModeShared];
        id<MTLBuffer> bsy = [dev newBufferWithLength:sizeof(float)
                                             options:MTLResourceStorageModeShared];
        id<MTLBuffer> bsxy = [dev newBufferWithLength:sizeof(float)
                                              options:MTLResourceStorageModeShared];
        id<MTLBuffer> bsx2 = [dev newBufferWithLength:sizeof(float)
                                              options:MTLResourceStorageModeShared];
        id<MTLBuffer> bsy2 = [dev newBufferWithLength:sizeof(float)
                                              options:MTLResourceStorageModeShared];
        std::memset([bsx contents], 0, sizeof(float));
        std::memset([bsy contents], 0, sizeof(float));
        std::memset([bsxy contents], 0, sizeof(float));
        std::memset([bsx2 contents], 0, sizeof(float));
        std::memset([bsy2 contents], 0, sizeof(float));

        uint32_t un = static_cast<uint32_t>(n);
        NSUInteger maxTg = means_pl.maxTotalThreadsPerThreadgroup;
        NSUInteger tg = std::min(maxTg, static_cast<NSUInteger>(256));
        // Round grid up to a multiple of tg for clean TG reduction padding.
        NSUInteger grid = ((n + tg - 1) / tg) * tg;

        id<MTLCommandBuffer> cmd = [queue commandBuffer];

        {
            id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
            [enc setComputePipelineState:means_pl];
            [enc setBuffer:bx offset:0 atIndex:0];
            [enc setBuffer:by offset:0 atIndex:1];
            [enc setBuffer:bsx offset:0 atIndex:2];
            [enc setBuffer:bsy offset:0 atIndex:3];
            [enc setBytes:&un length:sizeof(un) atIndex:4];
            [enc dispatchThreads:MTLSizeMake(grid, 1, 1)
          threadsPerThreadgroup:MTLSizeMake(tg, 1, 1)];
            [enc endEncoding];
        }

        [cmd commit];
        [cmd waitUntilCompleted];
        if (cmd.error != nil) return std::numeric_limits<double>::quiet_NaN();

        float sum_x = *static_cast<const float*>([bsx contents]);
        float sum_y = *static_cast<const float*>([bsy contents]);
        float mean_x = sum_x / static_cast<float>(n);
        float mean_y = sum_y / static_cast<float>(n);

        id<MTLCommandBuffer> cmd2 = [queue commandBuffer];
        {
            id<MTLComputeCommandEncoder> enc = [cmd2 computeCommandEncoder];
            [enc setComputePipelineState:mom_pl];
            [enc setBuffer:bx offset:0 atIndex:0];
            [enc setBuffer:by offset:0 atIndex:1];
            [enc setBuffer:bsxy offset:0 atIndex:2];
            [enc setBuffer:bsx2 offset:0 atIndex:3];
            [enc setBuffer:bsy2 offset:0 atIndex:4];
            [enc setBytes:&un length:sizeof(un) atIndex:5];
            [enc setBytes:&mean_x length:sizeof(mean_x) atIndex:6];
            [enc setBytes:&mean_y length:sizeof(mean_y) atIndex:7];
            [enc dispatchThreads:MTLSizeMake(grid, 1, 1)
          threadsPerThreadgroup:MTLSizeMake(tg, 1, 1)];
            [enc endEncoding];
        }
        [cmd2 commit];
        [cmd2 waitUntilCompleted];
        if (cmd2.error != nil) return std::numeric_limits<double>::quiet_NaN();

        float sxy = *static_cast<const float*>([bsxy contents]);
        float sx2 = *static_cast<const float*>([bsx2 contents]);
        float sy2 = *static_cast<const float*>([bsy2 contents]);

        double denom = std::sqrt(static_cast<double>(sx2) * static_cast<double>(sy2));
        return (denom > 0.0) ? (static_cast<double>(sxy) / denom) : 0.0;
    }
}

} // namespace ba::metal

#endif // __APPLE__ && BA_HAS_METAL
