/*
 * backend.h — Backend enum and runtime detection for BonhommeAccel.
 */

#ifndef BA_BACKEND_H
#define BA_BACKEND_H

#include "BonhommeAccel.h"
#include <atomic>

namespace ba {

/**
 * Probe hardware capabilities and return the fastest available backend.
 * Called once by ba_detect_best_backend(); result cached atomically.
 */
BABackend probe_best_backend();

/**
 * Global cached backend. Set once via compare_exchange_strong.
 * -1 = not yet probed.
 */
inline std::atomic<int> g_active_backend{-1};

/**
 * Get the active backend, probing if necessary.
 */
inline BABackend get_backend() {
    int val = g_active_backend.load(std::memory_order_acquire);
    if (val < 0) {
        val = static_cast<int>(probe_best_backend());
        int expected = -1;
        g_active_backend.compare_exchange_strong(expected, val,
            std::memory_order_release, std::memory_order_acquire);
        // If CAS failed, another thread set it first — use their value.
        if (expected >= 0) val = expected;
    }
    return static_cast<BABackend>(val);
}

} // namespace ba

#endif // BA_BACKEND_H
