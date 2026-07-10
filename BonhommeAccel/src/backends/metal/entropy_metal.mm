/*
 * entropy_metal.mm — Metal compute dispatch for Shannon entropy.
 *
 * Converts double host data to float for MSL (no double on Apple GPU),
 * builds histogram via atomic_uint bins, reduces entropy on the host.
 * Returns -1.0 on GPU failure so the C API can fall back to SIMD/scalar.
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
#include <string>
#include <vector>

namespace ba::metal {

id<MTLDevice> metal_device();
id<MTLCommandQueue> metal_queue();
id<MTLComputePipelineState> metal_pipeline(const std::string& kernel_name,
                                             const char* msl_source);

static double entropy_from_bins_host(const uint32_t* bins, int bin_count, double total) {
    if (total < 2.0) return 0.0;
    double entropy = 0.0;
    for (int i = 0; i < bin_count; ++i) {
        if (bins[i] > 0) {
            double p = static_cast<double>(bins[i]) / total;
            entropy -= p * std::log2(p);
        }
    }
    return entropy;
}

static std::vector<float> to_float(const double* values, size_t count) {
    std::vector<float> out(count);
    for (size_t i = 0; i < count; ++i) {
        out[i] = static_cast<float>(values[i]);
    }
    return out;
}

static NSUInteger threadgroup_size(id<MTLComputePipelineState> pipeline, NSUInteger n) {
    NSUInteger maxTg = pipeline.maxTotalThreadsPerThreadgroup;
    // Prefer power-of-two TG sizes for reduction-friendly kernels; clamp to n.
    NSUInteger tg = std::min(maxTg, static_cast<NSUInteger>(256));
    if (n < tg) {
        // Round up to at least 1; prefer multiple of 32 for occupancy.
        tg = std::max<NSUInteger>(1, n);
        if (tg > 1 && (tg % 32) != 0) {
            tg = std::min(maxTg, ((tg + 31) / 32) * 32);
        }
    }
    return tg;
}

static bool dispatch_histogram(id<MTLComputePipelineState> pipeline,
                                const float* data, size_t count,
                                int bin_count,
                                bool has_min_width, // shannon: min+width; circular: width only
                                float min_val, float bin_width,
                                uint32_t* out_bins) {
    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();
        if (!dev || !queue || !pipeline) return false;

        id<MTLBuffer> data_buf = [dev newBufferWithBytes:data
                                                  length:count * sizeof(float)
                                                 options:MTLResourceStorageModeShared];
        id<MTLBuffer> bins_buf = [dev newBufferWithLength:static_cast<NSUInteger>(bin_count) * sizeof(uint32_t)
                                                  options:MTLResourceStorageModeShared];
        std::memset([bins_buf contents], 0, static_cast<size_t>(bin_count) * sizeof(uint32_t));

        uint32_t ucount = static_cast<uint32_t>(count);
        uint32_t ubin_count = static_cast<uint32_t>(bin_count);

        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        [enc setComputePipelineState:pipeline];
        [enc setBuffer:data_buf offset:0 atIndex:0];
        [enc setBuffer:bins_buf offset:0 atIndex:1];
        [enc setBytes:&ucount length:sizeof(ucount) atIndex:2];
        [enc setBytes:&ubin_count length:sizeof(ubin_count) atIndex:3];
        if (has_min_width) {
            [enc setBytes:&min_val length:sizeof(min_val) atIndex:4];
            [enc setBytes:&bin_width length:sizeof(bin_width) atIndex:5];
        } else {
            [enc setBytes:&bin_width length:sizeof(bin_width) atIndex:4];
        }

        NSUInteger tg = threadgroup_size(pipeline, count);
        [enc dispatchThreads:MTLSizeMake(count, 1, 1)
      threadsPerThreadgroup:MTLSizeMake(tg, 1, 1)];
        [enc endEncoding];
        [cmd commit];
        [cmd waitUntilCompleted];

        if (cmd.error != nil) return false;

        std::memcpy(out_bins, [bins_buf contents],
                    static_cast<size_t>(bin_count) * sizeof(uint32_t));
        return true;
    }
}

double shannon_entropy_metal(const double* values, size_t count, int bin_count) {
    if (!metal_is_available() || !values || count < 2 || bin_count < 1)
        return -1.0;

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

    float fmin = static_cast<float>(min_val);
    float fwidth = static_cast<float>((max_val - min_val) / static_cast<double>(bin_count));
    if (!(fwidth > 0.0f)) return 0.0;

    auto pipeline = metal_pipeline("shannon_histogram", kShannonHistogramKernel);
    if (!pipeline) return -1.0;

    auto fdata = to_float(values, count);
    std::vector<uint32_t> bins(static_cast<size_t>(bin_count), 0);

    if (!dispatch_histogram(pipeline, fdata.data(), count, bin_count,
                            true, fmin, fwidth, bins.data())) {
        return -1.0;
    }
    return entropy_from_bins_host(bins.data(), bin_count, static_cast<double>(clean_count));
}

double circular_shannon_entropy_metal(const double* angles, size_t count, int bin_count) {
    if (!metal_is_available() || !angles || count < 2 || bin_count < 1)
        return -1.0;

    uint32_t clean_count = 0;
    for (size_t i = 0; i < count; ++i) {
        if (std::isfinite(angles[i])) ++clean_count;
    }
    if (clean_count < 2) return 0.0;

    float fwidth = static_cast<float>(360.0 / static_cast<double>(bin_count));

    auto pipeline = metal_pipeline("circular_histogram", kCircularHistogramKernel);
    if (!pipeline) return -1.0;

    auto fdata = to_float(angles, count);
    std::vector<uint32_t> bins(static_cast<size_t>(bin_count), 0);

    if (!dispatch_histogram(pipeline, fdata.data(), count, bin_count,
                            false, 0.0f, fwidth, bins.data())) {
        return -1.0;
    }
    return entropy_from_bins_host(bins.data(), bin_count, static_cast<double>(clean_count));
}

void shannon_entropy_batch_metal(const double* flat, const size_t* offsets,
                                  const size_t* lengths, size_t batch_count,
                                  int bin_count, double* out_entropies) {
    if (!out_entropies) return;
    for (size_t b = 0; b < batch_count; ++b) {
        out_entropies[b] = shannon_entropy_metal(flat + offsets[b], lengths[b], bin_count);
    }
}

void circular_shannon_entropy_batch_metal(const double* flat, const size_t* offsets,
                                           const size_t* lengths, size_t batch_count,
                                           int bin_count, double* out_entropies) {
    if (!out_entropies) return;
    for (size_t b = 0; b < batch_count; ++b) {
        out_entropies[b] = circular_shannon_entropy_metal(
            flat + offsets[b], lengths[b], bin_count);
    }
}

} // namespace ba::metal

#endif // __APPLE__ && BA_HAS_METAL
