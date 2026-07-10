# BonhommeAccel Testing (Dual Path)

`BonhommeAccel` is the C++20 high-performance entropy / correlation / statistics library.
It is **not** part of the default Swift Package Manager test path.

## Dual path overview

| Path | What it builds/tests | Default? | Command surface |
|------|----------------------|----------|-----------------|
| **A — Swift-only (SPM)** | `BonhommeCore` XCTest suites. No CMake, no Catch2, no linking of the real C++ Accel lib into `swift test`. | **Yes** — `make test` / `swift test` | `cd BonhommeCore && swift test` |
| **B — Accel (CMake + ctest)** | Static `BonhommeAccel` library + Catch2 suite (`ba_tests`). | Opt-in | `cmake` / `cmake --build` / `ctest` under `BonhommeAccel/` |

**Invariant:** Default SPM `swift test` must remain Swift-only and must not fail because Accel was not built. Accel linkage for the app is handled at the Xcode project level (`BONHOMME_ACCEL`), not by wiring Accel into the SPM test dependency graph.

`BonhommeCore/Package.swift` defines optional targets `clibBonhommeAccel` and `BonhommeAccelSwift`, but the main `BonhommeCore` target intentionally has `dependencies: []` so `swift test` never requires a CMake Accel build.

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
| `BA_ENABLE_OPENMP` | `ON` | OpenMP backend if toolchain finds OpenMP |
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
Path A (always):
  BonhommeCore  --swift test-->  BonhommeCoreTests (XCTest)
                 (no Accel C++ link required)

Path B (opt-in):
  BonhommeAccel --cmake/ctest--> ba_tests (Catch2)

App / Xcode (conditional):
  BONHOMME_ACCEL + BonhommeAccelSwift + clibBonhommeAccel
  links real Accel at product build time; not required for SPM tests.
```

When changing Accel math, run **both** paths when possible:

1. `cd BonhommeCore && swift test` — Swift reimplementation / call sites still pass.
2. Accel Path B `ctest` — C++ kernels and SIMD backends still pass.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| `ctest` finds 0 tests | Configure without tests or empty build dir | Re-run `cmake -B build -DBA_BUILD_TESTS=ON` then rebuild |
| Catch2 fetch fails | Network / git blocked | Retry; ensure `git` can reach `github.com/catchorg/Catch2` |
| OpenMP not found | Normal on some Apple toolchains | Build continues without OpenMP; core + SIMD still test |
| SPM `swift test` fails after Accel work | Accidental SPM dependency on Accel | Keep `BonhommeCore` target `dependencies: []`; do not force Accel into default test graph |
| Stale Accel results | Old `build/` tree | `rm -rf BonhommeAccel/build` and reconfigure |
