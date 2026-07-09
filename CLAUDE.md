# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

NATURaL (Entropy Edition) is a biofeedback-driven chair yoga app for all Apple platforms (iOS 17+, watchOS 10+, tvOS 17+, visionOS 1+). Code name: **Bonhomme**. It uses real-time Shannon entropy analysis (Shannon Collapse Index / SCI) from heart rate variability, combined with adaptive music, CareKit prescriptions, CloudKit sync, and a PokeDrug pharmacological classification framework.

Zero external Swift dependencies. Proprietary codebase.

## Sibling Repository: FlexAIDdS

[FlexAIDdS](https://github.com/LeBonhommePharma/FlexAIDdS) (`/Users/lp.more/Documents/PhD/Programs/FlexAIDdS`) is the companion entropy-driven molecular docking engine. NATURaL has **no runtime dependency** on FlexAIDdS — instead it reimplements the core Shannon entropy mathematics in Swift and accepts docking results as user-provided data. The relationship is:

- **Shared math**: `EntropyCalculator.shannonEntropy()` (HRV) and `.circularShannonEntropy()` (torsional angles) use the identical Shannon formula as FlexAIDdS's `StatMechEngine` and `ShannonThermoStack`
- **Data import, not code import**: `FlexAIDdSAnalyzer` consumes `DockingPose` structs (torsional angles from FlexAID runs) and computes configurational entropy penalty (ΔS_config) independently
- **Reference database**: `BindingEntropyProfile` embeds published ΔS_config values for 60+ substances, enabling validation without running docking
- **Cross-domain validation**: `CrossDomainValidator` correlates molecular |ΔS_config| with physiological |ΔH_hrv| via Pearson correlation (p < 0.05, n >= 5) — this is the project's novel contribution
- **Acceleration parity**: `BonhommeAccel` (C++20) mirrors FlexAIDdS's GPU/SIMD dispatch pattern for entropy, with `ba_circular_shannon_entropy()` matching FlexAIDdS's torsional binning

### FlexAIDdS Integration Data Flow
```
FlexAIDdS docking run (external)
  → DockingPose (torsional angles + score)
    → FlexAIDdSAnalyzer.analyze() → ΔS_config (bits)
      → CrossDomainValidator.validate() ← DrugResponseAnalyzer → ΔH_hrv (bits)
        → ValidationResult (Pearson r, p-value, R², significance)
```
When no docking data is available, `CrossDomainValidator.validateFromProfiles()` uses `BindingEntropyProfile` reference values instead.

### FlexAIDdS Build (for reference)
```bash
cd /Users/lp.more/Documents/PhD/Programs/FlexAIDdS
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON
cmake --build . -j $(sysctl -n hw.ncpu)
ctest --test-dir .
# Python package (no CMake needed):
cd ../python && pip install -e . && pytest tests/
```
See FlexAIDdS's own `CLAUDE.md` for full development guide.

## Build & Run

### iOS/watchOS/tvOS/visionOS (primary)
```bash
open NATURaL.xcodeproj
# Select scheme (Bonhomme, BonhommeWatch, BonhommeTV, BonhommeVision) -> Run
```
Requires Xcode 15+, Swift 5.9+.

### BonhommeCore Swift Package (shared library)
```bash
cd BonhommeCore
swift build
swift test   # runs all XCTest suites
```

### BonhommeAccel C++20 library (standalone)
```bash
cd BonhommeAccel
cmake -B build -DCMAKE_BUILD_TYPE=Release -DBA_BUILD_TESTS=ON
cmake --build build
ctest --test-dir build --output-on-failure
```
Requires CMake 3.20+. Tests use Catch2 v3.5.2 (fetched automatically). Backends: SIMD (AVX2/NEON auto-detected), OpenMP, CUDA, ROCm, Metal (all optional flags in CMakeLists.txt).

## Architecture

### Three-Layer Stack
1. **Platform Apps** (SwiftUI) — `Bonhomme/` (iOS), `BonhommeWatch/`, `BonhommeTV/`, `BonhommeVision/`, `NATURaLWidgets/`, `NATURaLLiveActivity/`
2. **BonhommeCore** (Swift Package) — shared models, analysis engines, UI components. This is the bulk of the logic.
3. **BonhommeAccel** (C++20 static library) — high-performance entropy, correlation, and statistics. Bridged to Swift via `clibBonhommeAccel` C shim -> `BonhommeAccelSwift` wrapper. Compile flag `BONHOMME_ACCEL` enables the accelerated path. Note: `BonhommeAccelSwift` is defined as a target in Package.swift but not wired as a dependency of `BonhommeCore` (conditional linkage handled at Xcode project level).

### Key Protocol Chain
`HealthSignal` (protocol) -> `SignalAnalyzer` (protocol with extensions: HRVAnalyzer, MedicationAnalyzer, DockingInsightAnalyzer) -> `FeedbackEngine` (multi-signal orchestrator producing insights).

`CrossDomainValidator` correlates molecular entropy (FlexAID dS) with physiological entropy (HRV) for the PokeDrug framework.

### Crooks Control Layer (`BonhommeCore/Sources/BonhommeCore/Control/`)
Non-equilibrium session control: SCI/HRV + FlexAID ΔS + crown β → work → σ_irr → actuators.

```
PharmaControlSessionManager
  → CrooksCycleController.update(ΔH_hrv, ΔS_config, β, bpm)
      → EigenMetalWorkKernel (Accelerate/ANE eigen work)
      → DeltaHRVFlexAIDMapper (BindingEntropyProfile residual)
      → ActuatorBus (single multiplex; BeatSyncActuatorChannel owns UniversalBeatSync)
          → crown β · AirPods dial · breathing · session log · cross-domain ground
```

Policy: σ_irr > 0.12 → grounding (92 BPM, damp β); σ_irr < 0.03 → phase flip. Universal beat locks Music / Watch / AirPods tempo once per tick.

### Service Layer (`Bonhomme/Services/`)
- **HealthKit** — HRV, heart rate, workout sessions, activity rings
- **CareKit** — therapist-prescribed plans, adherence tracking
- **Music** — SCI-driven adaptive playlist switching (3s crossfade, 30s debounce) + UniversalBeatSync playback-rate lock
- **Persistence** — SwiftData models with CloudKit sync, 5-second state saving for crash recovery
- **WatchConnectivity** — iOS <-> Watch real-time messaging
- **SharePlay** — collaborative workout sessions
- **TVRelay** — Bonjour-based AirPlay second-screen coordination

### PokeDrug Framework (`BonhommeCore/Sources/BonhommeCore/Analysis/`)
12-type pharmacological classification system. Key types: `PokeDrugType`, `PokeDrugSpecies`, `PokeDrugSuperaCluster`, `PokeDrugMatchup`. `DrugResponseAnalyzer` detects autonomic drug response via HRV entropy collapse. Validation against molecular FlexAID dS data.

### Analysis Modules (`BonhommeCore/Sources/BonhommeCore/Analysis/`)
`EntropyCalculator` is the shared base — Shannon entropy H = -Σ p_i log₂(p_i) with two modes: data-adaptive linear binning (HRV/physiological) and fixed circular binning [-180°, +180°) (torsional/molecular). Conditionally accelerated via `BonhommeAccel` when `BONHOMME_ACCEL` is defined.

**Molecular/docking layer** (FlexAIDdS-facing):
- `FlexAIDdSAnalyzer` — configurational entropy penalty (ΔS_config) from torsional angle distributions; per-bond and total entropy; energy conversion (1 bit ≈ 0.41 kcal/mol at 298K)
- `PartitionFunctionCalculator` — Boltzmann-weighted partition function Z from docking poses; ensemble free energy ΔG_ens = -kT·ln(Z); population fractions and Shannon importance
- `ThermodynamicBindingProfile` — full Gibbs decomposition (ΔG/ΔH/-TΔS) from BindingDB/SCORPIO/ChEMBL; entropy-driven vs enthalpy-driven classification; ΔS(bits) ↔ -TΔS(kcal/mol) conversion
- `BindingEntropyProfile` — reference database of 60+ substances with published ΔS_config values; heuristic ~0.5-0.7 kcal/mol per frozen rotatable bond
- `LigandEfficiencyCalculator` — LE, BEI metrics from binding data
- `CrossDomainValidator` — Pearson correlation between molecular and physiological entropy with p-value significance testing
- `DockingInsightAnalyzer` — bridges `DockingSignal` into the `FeedbackEngine` multi-signal pipeline

**Physiological/pharmacological layer**:
- `DrugResponseAnalyzer` — detects autonomic drug response via HRV entropy collapse around dose times
- `SelectivityEntropyAnalyzer`, `PopulationPKAnalyzer`, `EvolutionThermodynamics` — pharmacological analysis extensions

### Pose Engine
26 bilingual (EN/FR-CA) chair yoga poses across anatomical categories, with 3 difficulty levels, modifications, contraindications, and voice cues. Defined in `PoseCatalog.swift`. Localization supports 9 languages via `LocalizedString`.

## Xcode Project Targets (8)
Bonhomme (iOS), BonhommeWatch, BonhommeTV, BonhommeVision, NATURaLWidgets, NATURaLLiveActivity, BonhommeTests, BonhommeUITests.

## Testing

Swift unit tests are in `BonhommeCore/Tests/BonhommeCoreTests/` (analysis, models, poses, Crooks control). Xcode-level tests in `Tests/BonhommeTests/` and `Tests/BonhommeUITests/`. C++ tests in `BonhommeAccel/tests/` (5 Catch2 test files).

Run Swift tests: `cd BonhommeCore && swift test`
Run a single Swift test: `cd BonhommeCore && swift test --filter EntropyCalculatorTests`
Run C++ tests: `cd BonhommeAccel/build && ctest --output-on-failure`
Run Xcode tests from CLI: `xcodebuild test -scheme Bonhomme -destination 'platform=iOS Simulator,name=iPhone 16 Pro'`
Run Xcode tests from IDE: Cmd+U with appropriate scheme selected.

## Code Conventions

- Swift concurrency throughout: `async/await`, `@MainActor`, `Sendable`
- SwiftUI + SwiftData (not Core Data) for persistence
- No SwiftLint or formatter configured — follow Apple Framework Design Guidelines
- No CI/CD configured
- Branch naming from PRs: `claude/feature-name-ID`
