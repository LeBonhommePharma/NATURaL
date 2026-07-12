/*
 * entropy_metal.mm — Metal compute dispatch for Shannon entropy.
 *
 * Converts double host data to float for MSL (no double on Apple GPU),
 * builds histogram via atomic_uint bins, reduces entropy on the host.
 * Adaptive path uses a GPU min/max/count reduce so huge arrays avoid a
 * second host scan. Batch APIs pack segments into one multi-histogram
 * dispatch (2D grid: local index × batch item) with a single GPU wait.
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
#include <limits>
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

/** Power-of-two TG size for reduction kernels (capped at 256). */
static NSUInteger reduction_tg_size(id<MTLComputePipelineState> pipeline) {
    NSUInteger maxTg = pipeline.maxTotalThreadsPerThreadgroup;
    NSUInteger tg = std::min(maxTg, static_cast<NSUInteger>(256));
    // Ensure power of two for stride reduction.
    while (tg > 1 && (tg & (tg - 1)) != 0) {
        tg >>= 1;
    }
    return std::max<NSUInteger>(1, tg);
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

/**
 * GPU min/max/count over finite float values.
 * Returns false on Metal failure. On success, *out_count is finite count;
 * if *out_count == 0, min/max are undefined.
 */
static bool minmax_reduce_metal(const float* data, size_t count,
                                 float* out_min, float* out_max,
                                 uint32_t* out_count) {
    if (!data || count == 0 || !out_min || !out_max || !out_count) return false;

    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();
        auto pipeline = metal_pipeline("minmax_reduce", kMinMaxReduceKernel);
        if (!dev || !queue || !pipeline) return false;

        NSUInteger tg = reduction_tg_size(pipeline);
        NSUInteger ntg = (count + tg - 1) / tg;
        NSUInteger grid = ntg * tg;

        id<MTLBuffer> data_buf = [dev newBufferWithBytes:data
                                                  length:count * sizeof(float)
                                                 options:MTLResourceStorageModeShared];
        id<MTLBuffer> mins_buf = [dev newBufferWithLength:ntg * sizeof(float)
                                                  options:MTLResourceStorageModeShared];
        id<MTLBuffer> maxs_buf = [dev newBufferWithLength:ntg * sizeof(float)
                                                  options:MTLResourceStorageModeShared];
        id<MTLBuffer> cnts_buf = [dev newBufferWithLength:ntg * sizeof(uint32_t)
                                                  options:MTLResourceStorageModeShared];

        uint32_t ucount = static_cast<uint32_t>(count);

        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        [enc setComputePipelineState:pipeline];
        [enc setBuffer:data_buf offset:0 atIndex:0];
        [enc setBuffer:mins_buf offset:0 atIndex:1];
        [enc setBuffer:maxs_buf offset:0 atIndex:2];
        [enc setBuffer:cnts_buf offset:0 atIndex:3];
        [enc setBytes:&ucount length:sizeof(ucount) atIndex:4];
        [enc dispatchThreads:MTLSizeMake(grid, 1, 1)
      threadsPerThreadgroup:MTLSizeMake(tg, 1, 1)];
        [enc endEncoding];
        [cmd commit];
        [cmd waitUntilCompleted];
        if (cmd.error != nil) return false;

        const float* mins = static_cast<const float*>([mins_buf contents]);
        const float* maxs = static_cast<const float*>([maxs_buf contents]);
        const uint32_t* cnts = static_cast<const uint32_t*>([cnts_buf contents]);

        float gmin = std::numeric_limits<float>::infinity();
        float gmax = -std::numeric_limits<float>::infinity();
        uint32_t gcnt = 0;
        for (NSUInteger t = 0; t < ntg; ++t) {
            gcnt += cnts[t];
            if (cnts[t] == 0) continue;
            gmin = std::min(gmin, mins[t]);
            gmax = std::max(gmax, maxs[t]);
        }
        *out_min = gmin;
        *out_max = gmax;
        *out_count = gcnt;
        return true;
    }
}

static size_t batch_span_end(const size_t* offsets, const size_t* lengths,
                              size_t batch_count) {
    size_t end = 0;
    for (size_t b = 0; b < batch_count; ++b) {
        end = std::max(end, offsets[b] + lengths[b]);
    }
    return end;
}

/**
 * One command-buffer multi-histogram fill for adaptive shannon.
 * bins_out must hold batch_count * bin_count uint32 zeros on success.
 */
static bool dispatch_shannon_histogram_batch(const float* data, size_t data_count,
                                              const uint32_t* offsets,
                                              const uint32_t* lengths,
                                              size_t batch_count, int bin_count,
                                              const float* min_vals,
                                              const float* bin_widths,
                                              uint32_t* bins_out) {
    if (batch_count == 0 || bin_count < 1 || !data || !offsets || !lengths ||
        !min_vals || !bin_widths || !bins_out) {
        return false;
    }

    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();
        auto pipeline = metal_pipeline("shannon_histogram_batch",
                                         kShannonHistogramBatchKernel);
        if (!dev || !queue || !pipeline) return false;

        size_t max_len_u = 0;
        for (size_t b = 0; b < batch_count; ++b) {
            max_len_u = std::max(max_len_u, static_cast<size_t>(lengths[b]));
        }
        if (max_len_u == 0) {
            std::memset(bins_out, 0,
                        batch_count * static_cast<size_t>(bin_count) * sizeof(uint32_t));
            return true;
        }

        const size_t bins_total = batch_count * static_cast<size_t>(bin_count);

        id<MTLBuffer> data_buf = [dev newBufferWithBytes:data
                                                  length:data_count * sizeof(float)
                                                 options:MTLResourceStorageModeShared];
        id<MTLBuffer> off_buf = [dev newBufferWithBytes:offsets
                                                 length:batch_count * sizeof(uint32_t)
                                                options:MTLResourceStorageModeShared];
        id<MTLBuffer> len_buf = [dev newBufferWithBytes:lengths
                                                 length:batch_count * sizeof(uint32_t)
                                                options:MTLResourceStorageModeShared];
        id<MTLBuffer> min_buf = [dev newBufferWithBytes:min_vals
                                                 length:batch_count * sizeof(float)
                                                options:MTLResourceStorageModeShared];
        id<MTLBuffer> wid_buf = [dev newBufferWithBytes:bin_widths
                                                 length:batch_count * sizeof(float)
                                                options:MTLResourceStorageModeShared];
        id<MTLBuffer> bins_buf = [dev newBufferWithLength:bins_total * sizeof(uint32_t)
                                                  options:MTLResourceStorageModeShared];
        std::memset([bins_buf contents], 0, bins_total * sizeof(uint32_t));

        uint32_t ubin_count = static_cast<uint32_t>(bin_count);
        uint32_t ubatch = static_cast<uint32_t>(batch_count);

        NSUInteger tg = threadgroup_size(pipeline, max_len_u);

        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        [enc setComputePipelineState:pipeline];
        [enc setBuffer:data_buf offset:0 atIndex:0];
        [enc setBuffer:off_buf offset:0 atIndex:1];
        [enc setBuffer:len_buf offset:0 atIndex:2];
        [enc setBuffer:bins_buf offset:0 atIndex:3];
        [enc setBuffer:min_buf offset:0 atIndex:4];
        [enc setBuffer:wid_buf offset:0 atIndex:5];
        [enc setBytes:&ubin_count length:sizeof(ubin_count) atIndex:6];
        [enc setBytes:&ubatch length:sizeof(ubatch) atIndex:7];
        [enc dispatchThreads:MTLSizeMake(max_len_u, batch_count, 1)
      threadsPerThreadgroup:MTLSizeMake(tg, 1, 1)];
        [enc endEncoding];
        [cmd commit];
        [cmd waitUntilCompleted];
        if (cmd.error != nil) return false;

        std::memcpy(bins_out, [bins_buf contents], bins_total * sizeof(uint32_t));
        return true;
    }
}

static bool dispatch_circular_histogram_batch(const float* data, size_t data_count,
                                               const uint32_t* offsets,
                                               const uint32_t* lengths,
                                               size_t batch_count, int bin_count,
                                               float bin_width,
                                               uint32_t* bins_out) {
    if (batch_count == 0 || bin_count < 1 || !data || !offsets || !lengths ||
        !bins_out) {
        return false;
    }

    @autoreleasepool {
        id<MTLDevice> dev = metal_device();
        id<MTLCommandQueue> queue = metal_queue();
        auto pipeline = metal_pipeline("circular_histogram_batch",
                                         kCircularHistogramBatchKernel);
        if (!dev || !queue || !pipeline) return false;

        size_t max_len_u = 0;
        for (size_t b = 0; b < batch_count; ++b) {
            max_len_u = std::max(max_len_u, static_cast<size_t>(lengths[b]));
        }
        if (max_len_u == 0) {
            std::memset(bins_out, 0,
                        batch_count * static_cast<size_t>(bin_count) * sizeof(uint32_t));
            return true;
        }

        const size_t bins_total = batch_count * static_cast<size_t>(bin_count);

        id<MTLBuffer> data_buf = [dev newBufferWithBytes:data
                                                  length:data_count * sizeof(float)
                                                 options:MTLResourceStorageModeShared];
        id<MTLBuffer> off_buf = [dev newBufferWithBytes:offsets
                                                 length:batch_count * sizeof(uint32_t)
                                                options:MTLResourceStorageModeShared];
        id<MTLBuffer> len_buf = [dev newBufferWithBytes:lengths
                                                 length:batch_count * sizeof(uint32_t)
                                                options:MTLResourceStorageModeShared];
        id<MTLBuffer> bins_buf = [dev newBufferWithLength:bins_total * sizeof(uint32_t)
                                                  options:MTLResourceStorageModeShared];
        std::memset([bins_buf contents], 0, bins_total * sizeof(uint32_t));

        uint32_t ubin_count = static_cast<uint32_t>(bin_count);
        uint32_t ubatch = static_cast<uint32_t>(batch_count);

        NSUInteger tg = threadgroup_size(pipeline, max_len_u);

        id<MTLCommandBuffer> cmd = [queue commandBuffer];
        id<MTLComputeCommandEncoder> enc = [cmd computeCommandEncoder];
        [enc setComputePipelineState:pipeline];
        [enc setBuffer:data_buf offset:0 atIndex:0];
        [enc setBuffer:off_buf offset:0 atIndex:1];
        [enc setBuffer:len_buf offset:0 atIndex:2];
        [enc setBuffer:bins_buf offset:0 atIndex:3];
        [enc setBytes:&ubin_count length:sizeof(ubin_count) atIndex:4];
        [enc setBytes:&ubatch length:sizeof(ubatch) atIndex:5];
        [enc setBytes:&bin_width length:sizeof(bin_width) atIndex:6];
        [enc dispatchThreads:MTLSizeMake(max_len_u, batch_count, 1)
      threadsPerThreadgroup:MTLSizeMake(tg, 1, 1)];
        [enc endEncoding];
        [cmd commit];
        [cmd waitUntilCompleted];
        if (cmd.error != nil) return false;

        std::memcpy(bins_out, [bins_buf contents], bins_total * sizeof(uint32_t));
        return true;
    }
}

double shannon_entropy_metal(const double* values, size_t count, int bin_count) {
    if (!metal_is_available() || !values || count < 2 || bin_count < 1)
        return -1.0;

    auto fdata = to_float(values, count);

    // GPU min/max/count over finite floats (avoids second host scan of doubles).
    float fmin = 0.0f, fmax = 0.0f;
    uint32_t clean_count = 0;
    if (!minmax_reduce_metal(fdata.data(), count, &fmin, &fmax, &clean_count)) {
        // Fallback: host min/max if GPU reduce fails mid-path.
        fmin = std::numeric_limits<float>::infinity();
        fmax = -std::numeric_limits<float>::infinity();
        clean_count = 0;
        for (size_t i = 0; i < count; ++i) {
            float v = fdata[i];
            if (std::isfinite(v)) {
                fmin = std::min(fmin, v);
                fmax = std::max(fmax, v);
                ++clean_count;
            }
        }
    }

    if (clean_count < 2 || !(fmax > fmin)) return 0.0;

    float fwidth = (fmax - fmin) / static_cast<float>(bin_count);
    if (!(fwidth > 0.0f)) return 0.0;

    auto pipeline = metal_pipeline("shannon_histogram", kShannonHistogramKernel);
    if (!pipeline) return -1.0;

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

    auto fdata = to_float(angles, count);
    float fwidth = static_cast<float>(360.0 / static_cast<double>(bin_count));

    auto pipeline = metal_pipeline("circular_histogram", kCircularHistogramKernel);
    if (!pipeline) return -1.0;

    std::vector<uint32_t> bins(static_cast<size_t>(bin_count), 0);

    if (!dispatch_histogram(pipeline, fdata.data(), count, bin_count,
                            false, 0.0f, fwidth, bins.data())) {
        return -1.0;
    }
    // Sum of bins == finite count (kernel skips non-finite).
    double total = 0.0;
    for (int i = 0; i < bin_count; ++i) {
        total += static_cast<double>(bins[static_cast<size_t>(i)]);
    }
    return entropy_from_bins_host(bins.data(), bin_count, total);
}

void shannon_entropy_batch_metal(const double* flat, const size_t* offsets,
                                  const size_t* lengths, size_t batch_count,
                                  int bin_count, double* out_entropies) {
    if (!out_entropies) return;
    if (!metal_is_available() || !flat || !offsets || !lengths || bin_count < 1) {
        for (size_t b = 0; b < batch_count; ++b) out_entropies[b] = -1.0;
        return;
    }
    if (batch_count == 0) return;

    // Single-item: reuse optimized path (GPU min/max + hist).
    if (batch_count == 1) {
        out_entropies[0] = shannon_entropy_metal(flat + offsets[0], lengths[0], bin_count);
        return;
    }

    const size_t data_end = batch_span_end(offsets, lengths, batch_count);
    if (data_end == 0) {
        for (size_t b = 0; b < batch_count; ++b) out_entropies[b] = 0.0;
        return;
    }

    auto fdata = to_float(flat, data_end);

    std::vector<uint32_t> uoff(batch_count), ulen(batch_count);
    std::vector<float> mins(batch_count, 0.0f), widths(batch_count, 0.0f);
    std::vector<uint32_t> clean(batch_count, 0);
    std::vector<uint8_t> active(batch_count, 0);

    for (size_t b = 0; b < batch_count; ++b) {
        uoff[b] = static_cast<uint32_t>(offsets[b]);
        ulen[b] = static_cast<uint32_t>(lengths[b]);
        out_entropies[b] = 0.0;

        if (lengths[b] < 2) {
            ulen[b] = 0; // no-op on GPU
            continue;
        }

        // Per-item finite min/max on converted floats (one host pass per segment).
        float lo = std::numeric_limits<float>::infinity();
        float hi = -std::numeric_limits<float>::infinity();
        uint32_t cnt = 0;
        const float* seg = fdata.data() + offsets[b];
        for (size_t i = 0; i < lengths[b]; ++i) {
            float v = seg[i];
            if (std::isfinite(v)) {
                lo = std::min(lo, v);
                hi = std::max(hi, v);
                ++cnt;
            }
        }
        clean[b] = cnt;
        if (cnt < 2 || !(hi > lo)) {
            ulen[b] = 0;
            continue;
        }
        float w = (hi - lo) / static_cast<float>(bin_count);
        if (!(w > 0.0f)) {
            ulen[b] = 0;
            continue;
        }
        mins[b] = lo;
        widths[b] = w;
        active[b] = 1;
    }

    bool any_active = false;
    for (size_t b = 0; b < batch_count; ++b) {
        if (active[b]) {
            any_active = true;
            break;
        }
    }
    if (!any_active) return; // all zeros already written

    std::vector<uint32_t> bins(batch_count * static_cast<size_t>(bin_count), 0);
    if (!dispatch_shannon_histogram_batch(fdata.data(), data_end,
                                           uoff.data(), ulen.data(),
                                           batch_count, bin_count,
                                           mins.data(), widths.data(),
                                           bins.data())) {
        for (size_t b = 0; b < batch_count; ++b) {
            if (active[b]) out_entropies[b] = -1.0;
        }
        return;
    }

    for (size_t b = 0; b < batch_count; ++b) {
        if (!active[b]) continue;
        const uint32_t* plane = bins.data() + b * static_cast<size_t>(bin_count);
        out_entropies[b] = entropy_from_bins_host(
            plane, bin_count, static_cast<double>(clean[b]));
    }
}

void circular_shannon_entropy_batch_metal(const double* flat, const size_t* offsets,
                                           const size_t* lengths, size_t batch_count,
                                           int bin_count, double* out_entropies) {
    if (!out_entropies) return;
    if (!metal_is_available() || !flat || !offsets || !lengths || bin_count < 1) {
        for (size_t b = 0; b < batch_count; ++b) out_entropies[b] = -1.0;
        return;
    }
    if (batch_count == 0) return;

    if (batch_count == 1) {
        out_entropies[0] = circular_shannon_entropy_metal(
            flat + offsets[0], lengths[0], bin_count);
        return;
    }

    const size_t data_end = batch_span_end(offsets, lengths, batch_count);
    if (data_end == 0) {
        for (size_t b = 0; b < batch_count; ++b) out_entropies[b] = 0.0;
        return;
    }

    auto fdata = to_float(flat, data_end);

    std::vector<uint32_t> uoff(batch_count), ulen(batch_count);
    for (size_t b = 0; b < batch_count; ++b) {
        uoff[b] = static_cast<uint32_t>(offsets[b]);
        ulen[b] = (lengths[b] < 2) ? 0u : static_cast<uint32_t>(lengths[b]);
        out_entropies[b] = 0.0;
    }

    float fwidth = static_cast<float>(360.0 / static_cast<double>(bin_count));
    std::vector<uint32_t> bins(batch_count * static_cast<size_t>(bin_count), 0);

    if (!dispatch_circular_histogram_batch(fdata.data(), data_end,
                                            uoff.data(), ulen.data(),
                                            batch_count, bin_count, fwidth,
                                            bins.data())) {
        for (size_t b = 0; b < batch_count; ++b) {
            if (lengths[b] >= 2) out_entropies[b] = -1.0;
        }
        return;
    }

    for (size_t b = 0; b < batch_count; ++b) {
        if (lengths[b] < 2) continue;
        const uint32_t* plane = bins.data() + b * static_cast<size_t>(bin_count);
        // Sum of bins == finite count (histogram skips non-finite).
        double total = 0.0;
        for (int i = 0; i < bin_count; ++i) {
            total += static_cast<double>(plane[i]);
        }
        out_entropies[b] = entropy_from_bins_host(plane, bin_count, total);
    }
}

} // namespace ba::metal

#endif // __APPLE__ && BA_HAS_METAL
