# BonhommeAccel Testing (Dual Path)

`BonhommeAccel` is the C++20 high-performance entropy / correlation / statistics library.
It is **not** part of the default Swift Package Manager test path.

## Dual path overview

| Path | What it builds/tests | Default? | Command surface |
|------|----------------------|----------|-----------------|
| **A — Swift-only (SPM)** | `BonhommeCore` XCTest suites. No CMake, no Catch2, no linking of the real C++ Accel lib into `swift test`. | **Yes** — `make test` / `swift test` | `cd BonhommeCore && swift test` |
| **B — Accel (CMake + ctest)** | Static `BonhommeAccel` library + Catch2 suite (`ba_tests`). | Opt-in | `cmake` / `cmake --build` / `ctest` under `BonhommeAccel/` |
| **C — Xcode / device Accel** | App + package built with `BONHOMME_ACCEL` and prebuilt `libBonhommeAccel.a` for the destination SDK. | Opt-in | See [Path C](#path-c--xcode--device-builds-with-bonhomme_accel) |

**Invariant:** Default SPM `swift test` must remain Swift-only and must not fail because Accel was not built. App targets do **not** enable Accel by default. Opt-in is `BONHOMME_ACCEL=1` (Package.swift) and/or explicit Xcode Path C wiring — never by permanently wiring Accel into the SPM test dependency graph.

`BonhommeCore/Package.swift` defines targets `clibBonhommeAccel` and `BonhommeAccelSwift` (and exports `BonhommeAccelSwift` as an optional product). The main `BonhommeCore` target has empty dependencies unless `BONHOMME_ACCEL=1` is set when Package.swift is evaluated, so default `swift test` never requires a CMake Accel build.

---

## Path A — Swift-only (default)

From repo root:

```bash
# Makefile default test target (Swift only)
make test

# Equivalent SPM invocation
cd BonhommeCore && swift test

# Single suite filter
cd BonhommeCore && swift test --filter EntropyCalculatorTests
```

Do **not** expect Accel Catch2 cases here. Physiological entropy, Crooks control, PokeDrug, and related logic are covered by Swift XCTest under `BonhommeCore/Tests/BonhommeCoreTests/`.

---

## Path B — Accel CMake + ctest

Requires **CMake ≥ 3.20**. Catch2 v3.5.2 is fetched automatically when `BA_BUILD_TESTS=ON`.

### Configure, build, test

```bash
cd BonhommeAccel

# Configure (Release + tests)
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBA_BUILD_TESTS=ON

# Build library + ba_tests
cmake --build build -j "$(sysctl -n hw.ncpu 2>/dev/null || nproc)"

# Run Catch2 suite via CTest
ctest --test-dir build --output-on-failure
```

From repo root via Makefile (optional convenience targets):

```bash
make accel-configure   # cmake -B BonhommeAccel/build ...
make accel-build       # cmake --build BonhommeAccel/build
make accel-test        # ctest --test-dir BonhommeAccel/build --output-on-failure
make accel             # configure + build + test
```

### Re-run without reconfigure

```bash
cmake --build BonhommeAccel/build
ctest --test-dir BonhommeAccel/build --output-on-failure
```

### Verbose / filtered ctest

```bash
ctest --test-dir BonhommeAccel/build --output-on-failure -V
ctest --test-dir BonhommeAccel/build -R entropy --output-on-failure
```

### Clean Accel build tree

```bash
rm -rf BonhommeAccel/build
# or: make accel-clean
```

---

## CMake options (Accel)

| Option | Default | Meaning |
|--------|---------|---------|
| `BA_BUILD_TESTS` | `ON` | Build Catch2 `ba_tests` and register with CTest |
| `BA_ENABLE_OPENMP` | `ON` | OpenMP backend if toolchain finds OpenMP. On Apple, auto-detects Homebrew `libomp` (`brew install libomp`) and injects AppleClang `-Xpreprocessor -fopenmp` hints |
| `BA_ENABLE_CUDA` | `OFF` | CUDA backend (requires `nvcc`; runtime device probe) |
| `BA_ENABLE_ROCM` | `OFF` | ROCm/HIP backend (requires HIP; runtime device probe) |
| `BA_ENABLE_METAL` | `ON` on Apple, else `OFF` | Metal GPU backend (Apple Silicon / macOS) |
| `BA_ENABLE_AVX2` | `ON` | AVX2 SIMD (x86_64) |
| `BA_ENABLE_AVX512` | `ON` | AVX-512 flags reserved for future sources |
| `BA_ENABLE_NEON` | `ON` | ARM NEON (arm64 / aarch64) |

Example: host CPU SIMD only, no OpenMP / no Metal:

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release \
  -DBA_BUILD_TESTS=ON \
  -DBA_ENABLE_OPENMP=OFF \
  -DBA_ENABLE_METAL=OFF
```

Example: force-enable CUDA/ROCm (Linux hosts with toolchains):

```bash
cmake -B build -DCMAKE_BUILD_TYPE=Release \
  -DBA_ENABLE_CUDA=ON -DBA_ENABLE_ROCM=ON
```

### Backend selection (runtime)

`ba_detect_best_backend()` picks the first available compiled backend with a live device:

1. CUDA → 2. ROCm → 3. Metal → 4. NEON/AVX2 → 5. OpenMP → 6. Scalar

On Apple Silicon with default options, expect **Metal**. Metal MSL kernels use **float32** (Apple GPUs lack double); histogram bins remain exact integers and entropy is reduced on the host in double. GPU kernel failures fall back to NEON/AVX2/scalar. Pearson under Metal uses float32 GPU reduction with double SIMD/scalar fallback on failure.

CUDA/ROCm paths use full double precision on device.

---

## Test inventory (Path B)

Catch2 sources under `BonhommeAccel/tests/`:

- `test_entropy.cpp` — Shannon / circular Shannon entropy
- `test_correlation.cpp` — correlation kernels
- `test_pairwise.cpp` — pairwise stats
- `test_incomplete_beta.cpp` — incomplete beta / significance helpers
- `reference_values.h` — shared reference constants

Executable: `ba_tests` (discovered into CTest via `catch_discover_tests`).

---

## Relationship to Swift / Xcode

```
Path A (always / default):
  BonhommeCore  --swift test-->  BonhommeCoreTests (XCTest)
                 (no Accel C++ link required; Package.swift deps empty)

Path B (opt-in):
  BonhommeAccel --cmake/ctest--> ba_tests (Catch2)

Path C (opt-in device / host Accel in apps):
  Prebuilt libBonhommeAccel.a
    + BONHOMME_ACCEL compile condition on BonhommeCore
    + BonhommeAccelSwift / clibBonhommeAccel
  → EntropyCalculator / CrossDomainValidator delegate to ba_* APIs
```

When changing Accel math, run **both** Path A and Path B when possible:

1. `cd BonhommeCore && swift test` — Swift reimplementation / call sites still pass.
2. Accel Path B `ctest` — C++ kernels and SIMD backends still pass.

---

## Path C — Xcode / device builds with `BONHOMME_ACCEL`

### Verified baseline (do not regress)

| Layer | Default state | Notes |
|-------|---------------|--------|
| `BonhommeCore/Package.swift` | `BonhommeCore` has **no** Accel dependency unless `BONHOMME_ACCEL=1` at package evaluation | Default `swift test` / Xcode package resolve stay Swift-only |
| `NATURaL.xcodeproj` | **Does not** set `BONHOMME_ACCEL`; app targets only link the `BonhommeCore` product | Intentional — shipping path uses pure Swift entropy |
| `BonhommeAccelSwift` product | Exported from Package.swift for opt-in use | Not added to app `packageProductDependencies` by default |
| Real C++ symbols | From CMake `libBonhommeAccel.a` only | `clibBonhommeAccel` is headers + empty `shim.c` |

App targets that import `BonhommeCore` (Bonhomme, BonhommeWatch, BonhommeTV, BonhommeVision) therefore run the **Swift** `EntropyCalculator` path unless you deliberately enable Accel below.

### Compile flag semantics

Sources gate Accel with **compilation conditions**, not runtime feature flags:

```swift
#if BONHOMME_ACCEL
import BonhommeAccelSwift
#endif
```

Used in:

- `BonhommeCore/.../Analysis/EntropyCalculator.swift`
- `BonhommeCore/.../Analysis/CrossDomainValidator.swift`
- `BonhommeCore/.../Analysis/PopulationPKAnalyzer.swift`

Defining `BONHOMME_ACCEL` **without** linking `libBonhommeAccel.a` (and C++/Metal) produces **undefined symbol** link errors for `ba_*`. Defining nothing (default) leaves pure Swift — preferred for CI and everyday device builds.

> **Important:** Setting `SWIFT_ACTIVE_COMPILATION_CONDITIONS = BONHOMME_ACCEL` only on an **app** target does **not** recompile the local SPM `BonhommeCore` package with that flag. The define must apply to the **BonhommeCore** package target (via `Package.swift` / `BONHOMME_ACCEL=1`, or package-target build settings).

### Option 1 — Host CLI (macOS) with env gate

Use when validating Accel + Swift together on the Mac (same arch as the CMake build, typically `arm64`):

```bash
# 1) Build Accel (host)
make accel-build
# produces BonhommeAccel/build/libBonhommeAccel.a

# 2) Build / test BonhommeCore with Accel wired
cd BonhommeCore
BONHOMME_ACCEL=1 swift build
# optional: point at a non-default lib directory
BONHOMME_ACCEL=1 BONHOMME_ACCEL_LIB="$PWD/../BonhommeAccel/build" swift build

# Path A tests stay default-off; Accel host smoke:
BONHOMME_ACCEL=1 swift test   # requires lib present; not the default CI path
```

`Package.swift` when `BONHOMME_ACCEL=1`:

1. Adds `BonhommeAccelSwift` as a dependency of `BonhommeCore`
2. Defines `BONHOMME_ACCEL` via `swiftSettings`
3. Links `-lBonhommeAccel -lc++` + Metal/Foundation via `linkerSettings`

### Option 2 — Ship Accel for iOS device / simulator (Path C)

**Prerequisite:** `libBonhommeAccel.a` built for the **same OS + arch** as the destination.  
Host macOS `BonhommeAccel/build/libBonhommeAccel.a` **must not** be linked into an iOS app.

#### 2a. One-shot ship script (recommended)

```bash
# From repo root — builds device + simulator (arm64), creates XCFramework
make accel-ios
# or:
./scripts/build-accel-apple.sh
# optional host slice for BONHOMME_ACCEL=1 on macOS:
make accel-apple-ship   # → ./scripts/build-accel-apple.sh --with-macos
```

**Outputs** (gitignored under `BonhommeAccel/dist/`):

| Artifact | Use |
|----------|-----|
| `dist/iphoneos/libBonhommeAccel.a` | Physical iPhone (arm64), Metal + NEON |
| `dist/iphonesimulator/libBonhommeAccel.a` | iOS Simulator arm64, Metal + NEON |
| `dist/BonhommeAccel.xcframework` | Drag into Xcode or `FRAMEWORK_SEARCH_PATHS` |
| `dist/manifest.txt` | Build metadata (SDK paths, lipo info) |

Verify symbols:

```bash
nm BonhommeAccel/dist/iphoneos/libBonhommeAccel.a | grep 'T _ba_shannon_entropy'
lipo -info BonhommeAccel/dist/iphoneos/libBonhommeAccel.a
# → Non-fat file … architecture: arm64
```

Manual CMake (equivalent to the script):

```bash
cmake -B BonhommeAccel/build-iphoneos -S BonhommeAccel \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_SYSROOT=iphoneos \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=17.0 \
  -DCMAKE_BUILD_TYPE=Release \
  -DBA_BUILD_TESTS=OFF -DBA_ENABLE_OPENMP=OFF -DBA_ENABLE_METAL=ON
cmake --build BonhommeAccel/build-iphoneos -j "$(sysctl -n hw.ncpu)"
```

watchOS / tvOS: `./scripts/build-accel-apple.sh --with-watchos` / `--with-tvos` (Watch defaults Metal OFF).

#### 2b. Wire package + app (device)

1. **Package evaluation with Accel** — `Package.swift` only enables Accel when `BONHOMME_ACCEL=1` at resolve time:
   ```bash
   export BONHOMME_ACCEL=1
   # Point at the slice matching the destination SDK:
   export BONHOMME_ACCEL_LIB="$PWD/BonhommeAccel/dist/iphoneos"          # device
   # export BONHOMME_ACCEL_LIB="$PWD/BonhommeAccel/dist/iphonesimulator" # sim
   # Reset package caches if Xcode already resolved without the env:
   # File → Packages → Reset Package Caches
   open NATURaL.xcodeproj
   ```

2. **App linker settings** — use `BonhommeAccel/xcconfig/BonhommeAccel.ios.xcconfig` as a base, or set:
   - **Library Search Paths:** `BonhommeAccel/dist/iphoneos` (device) / `…/iphonesimulator` (sim)
   - **Other Linker Flags:** `-lBonhommeAccel -lc++`
   - **Frameworks:** `Metal`, `Foundation`
   - Or link **`BonhommeAccel.xcframework`** from `dist/`

3. **Do not** add Accel to **BonhommeCoreTests** / default `swift test`.

4. **Clean build** after toggling Accel so `#if BONHOMME_ACCEL` recompiles.

#### 2c. Confirm Accel is actually active

- `nm` / link map contains `ba_shannon_entropy`
- Runtime: `ba_backend_name(ba_detect_best_backend())` → Metal or NEON on device
- Or log inside `#if BONHOMME_ACCEL` in `EntropyCalculator`

### What not to do

| Anti-pattern | Why |
|--------------|-----|
| Add `BonhommeAccelSwift` as a permanent `BonhommeCore` dependency in Package.swift without env gate | Breaks Path A — `swift test` would need C++ link or fail |
| Set `BONHOMME_ACCEL` only on the app target | Package sources never see the define; Accel imports stay inactive |
| Link host `BonhommeAccel/build/libBonhommeAccel.a` into an iOS device app | Wrong platform/SDK; architecture/platform mismatch |
| Commit a forced-on Accel Xcode configuration as the team default | Device CI and contributors without CMake Accel trees would fail |
| Put Accel into `BonhommeCoreTests` dependencies | Violates dual-path invariant |
| Commit `dist/*.a` / XCFramework binaries by default | Large binaries; rebuild with `make accel-ios` |

### Suggested enablement checklist

- [ ] Path A still green: `make test` (no `BONHOMME_ACCEL` in env)
- [ ] Path B still green: `make accel` / `ctest`
- [ ] Matching-arch `libBonhommeAccel.a` built for the destination
- [ ] `BONHOMME_ACCEL` defined on **BonhommeCore** (env or package settings)
- [ ] `libBonhommeAccel` + libc++ (+ Metal) linked for the final app
- [ ] Clean build; smoke entropy path on device/simulator

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `ctest` finds 0 tests | Configure without tests or empty build dir | Re-run `cmake -B build -DBA_BUILD_TESTS=ON` then rebuild |
| Catch2 fetch fails | Network / git blocked | Retry; ensure `git` can reach `github.com/catchorg/Catch2` |
| OpenMP not found / `OpenMP = OFF` | AppleClang has no bundled libomp | `brew install libomp`, then clean reconfigure (`rm -rf BonhommeAccel/build && make accel`). CMake auto-detects `/opt/homebrew/opt/libomp` (or `brew --prefix libomp`). Manual override: `-DOpenMP_CXX_FLAGS="-Xpreprocessor -fopenmp -I$(brew --prefix libomp)/include" -DOpenMP_CXX_LIB_NAMES=omp -DOpenMP_omp_LIBRARY=$(brew --prefix libomp)/lib/libomp.dylib` |
| SPM `swift test` fails after Accel work | Accidental SPM dependency on Accel | Keep default `BonhommeCore` deps empty (no `BONHOMME_ACCEL` in env); do not force Accel into default test graph |
| Stale Accel results | Old `build/` tree | `rm -rf BonhommeAccel/build` and reconfigure |
| `Undefined symbol: _ba_shannon_entropy` | `BONHOMME_ACCEL` on but `.a` not linked / wrong search path | Build Accel for the destination; set `BONHOMME_ACCEL_LIB` or Xcode Library Search Paths |
| Accel code never runs in app | Flag only on app target | Define `BONHOMME_ACCEL` for the **BonhommeCore** package target |
| `building for iOS, but linking object file built for macOS` | Host `.a` used in device/sim link | Cross-compile with `CMAKE_SYSTEM_NAME=iOS` (see Path C) |
| Xcode still Swift-only after setting env | Package resolved before env was set | Reset Package Caches; clean build; re-open with `BONHOMME_ACCEL=1` exported |
