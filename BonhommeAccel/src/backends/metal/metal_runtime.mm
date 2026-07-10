/*
 * metal_runtime.mm — Metal device detection, library compilation, and pipeline caching.
 *
 * Compiles MSL kernels from embedded strings at first use and caches
 * pipelines for the process lifetime. Failed compilations are cached as nil
 * so repeated calls do not re-parse broken sources.
 */

#if defined(__APPLE__) && defined(BA_HAS_METAL)

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "metal_backend.h"
#include "metal_shaders.h"
#include <mutex>
#include <string>
#include <unordered_map>

namespace ba::metal {

struct MetalContext {
    id<MTLDevice> device = nil;
    id<MTLCommandQueue> queue = nil;
    // Cached pipelines; absent key = not yet attempted; nil value = hard failure.
    std::unordered_map<std::string, id<MTLComputePipelineState>> pipelines;
    std::mutex pipeline_mutex;
    bool available = false;

    static MetalContext& instance() {
        static MetalContext ctx;
        return ctx;
    }

    bool initialize() {
        static std::once_flag flag;
        std::call_once(flag, [this]() {
            @autoreleasepool {
                device = MTLCreateSystemDefaultDevice();
                if (device) {
                    queue = [device newCommandQueue];
                    available = (queue != nil);
                }
            }
        });
        return available;
    }

    id<MTLComputePipelineState> getPipeline(const std::string& name,
                                              const char* source) {
        std::lock_guard<std::mutex> lock(pipeline_mutex);
        auto it = pipelines.find(name);
        if (it != pipelines.end()) return it->second;

        @autoreleasepool {
            NSError* error = nil;
            NSString* src = [NSString stringWithUTF8String:source];
            MTLCompileOptions* opts = [MTLCompileOptions new];
            // languageVersion defaults to the highest supported by the device.
            id<MTLLibrary> library = [device newLibraryWithSource:src
                                                          options:opts
                                                            error:&error];
            if (!library) {
                NSLog(@"BonhommeAccel: Metal library compilation failed (%s): %@",
                      name.c_str(), error);
                pipelines[name] = nil;
                return nil;
            }

            NSString* funcName = [NSString stringWithUTF8String:name.c_str()];
            id<MTLFunction> function = [library newFunctionWithName:funcName];
            if (!function) {
                NSLog(@"BonhommeAccel: Metal function '%s' not found", name.c_str());
                pipelines[name] = nil;
                return nil;
            }

            id<MTLComputePipelineState> pipeline =
                [device newComputePipelineStateWithFunction:function error:&error];
            if (!pipeline) {
                NSLog(@"BonhommeAccel: Metal pipeline creation failed (%s): %@",
                      name.c_str(), error);
                pipelines[name] = nil;
                return nil;
            }

            pipelines[name] = pipeline;
            return pipeline;
        }
    }
};

bool metal_is_available() {
    return MetalContext::instance().initialize();
}

id<MTLDevice> metal_device() {
    auto& ctx = MetalContext::instance();
    ctx.initialize();
    return ctx.device;
}

id<MTLCommandQueue> metal_queue() {
    auto& ctx = MetalContext::instance();
    ctx.initialize();
    return ctx.queue;
}

id<MTLComputePipelineState> metal_pipeline(const std::string& kernel_name,
                                             const char* msl_source) {
    auto& ctx = MetalContext::instance();
    if (!ctx.initialize()) return nil;
    return ctx.getPipeline(kernel_name, msl_source);
}

} // namespace ba::metal

#endif // __APPLE__ && BA_HAS_METAL
