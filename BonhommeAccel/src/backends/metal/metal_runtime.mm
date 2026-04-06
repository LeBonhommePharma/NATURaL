/*
 * metal_runtime.mm — Metal device detection, library compilation, and pipeline caching.
 *
 * Objective-C++ file for Apple Metal GPU compute backend.
 * Compiles MSL kernels from embedded strings at first use and caches
 * the compiled pipelines for the lifetime of the process.
 */

#if defined(__APPLE__) && !defined(BA_SKIP_METAL)

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#include "metal_shaders.h"
#include <mutex>
#include <string>
#include <unordered_map>

namespace ba::metal {

// ═══════════════════════════════════════════════════════════════════════════
// Singleton Metal Context
// ═══════════════════════════════════════════════════════════════════════════

struct MetalContext {
    id<MTLDevice> device = nil;
    id<MTLCommandQueue> queue = nil;
    std::unordered_map<std::string, id<MTLComputePipelineState>> pipelines;
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
        auto it = pipelines.find(name);
        if (it != pipelines.end()) return it->second;

        @autoreleasepool {
            NSError* error = nil;
            NSString* src = [NSString stringWithUTF8String:source];
            id<MTLLibrary> library = [device newLibraryWithSource:src
                                                          options:nil
                                                            error:&error];
            if (!library) {
                NSLog(@"BonhommeAccel: Metal library compilation failed: %@", error);
                return nil;
            }

            NSString* funcName = [NSString stringWithUTF8String:name.c_str()];
            id<MTLFunction> function = [library newFunctionWithName:funcName];
            if (!function) {
                NSLog(@"BonhommeAccel: Metal function '%s' not found", name.c_str());
                return nil;
            }

            id<MTLComputePipelineState> pipeline =
                [device newComputePipelineStateWithFunction:function error:&error];
            if (!pipeline) {
                NSLog(@"BonhommeAccel: Metal pipeline creation failed: %@", error);
                return nil;
            }

            pipelines[name] = pipeline;
            return pipeline;
        }
    }
};

// ═══════════════════════════════════════════════════════════════════════════
// Public API
// ═══════════════════════════════════════════════════════════════════════════

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

#endif // __APPLE__ && !BA_SKIP_METAL
