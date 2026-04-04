# CLAUDE.md — NATURaL Project Guide

## Project Overview

NATURaL (codename: Bonhomme) is a biofeedback-driven chair yoga app for all Apple platforms. It combines guided yoga poses with real-time HRV-based Shannon Collapse Index (SCI) scoring, adaptive MusicKit, CareKit clinical integration, and a comprehensive PokeDrug pharmacology classification framework.

## Build & Test

```bash
# Build BonhommeCore package
swift build --package-path BonhommeCore

# Run BonhommeCore tests
swift test --package-path BonhommeCore

# Build iOS app via xcodebuild
xcodebuild build -project NATURaL.xcodeproj -scheme Bonhomme -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# Run all tests
xcodebuild test -project NATURaL.xcodeproj -scheme Bonhomme -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## Architecture

### Targets (8 total)

| Target | Platform | Entry Point |
|--------|----------|-------------|
| Bonhomme | iOS 17+ | `Bonhomme/App/BonhommeApp.swift` |
| BonhommeTV | tvOS 17+ | `BonhommeTV/App/BonhommeTVApp.swift` |
| BonhommeWatch | watchOS 10+ | `BonhommeWatch/App/BonhommeWatchApp.swift` |
| BonhommeVision | visionOS 1+ | `BonhommeVision/App/BonhommeVisionApp.swift` |
| NATURaLLiveActivity | iOS 17+ (ext) | `NATURaLLiveActivity/NATURaLLiveActivityBundle.swift` |
| NATURaLWidgets | iOS 17+ (ext) | `NATURaLWidgets/NATURaLWidgetsBundle.swift` |
| BonhommeTests | iOS 17+ | `Tests/BonhommeTests/` |
| BonhommeUITests | iOS 17+ | `Tests/BonhommeUITests/` |

### BonhommeCore Package

Platform-agnostic Swift Package consumed by all app targets. Three main directories:

- `Models/` — Data types (Pose, WorkoutPlan, LocalizedString, BiofeedbackSnapshot)
- `Analysis/` — 29 modules: biofeedback pipeline + PokeDrug pharmacology framework
- `TVDisplay/` — Shared SwiftUI views for TV surfaces

### Key Patterns

- **Protocol-driven analysis**: `HealthSignal` + `SignalAnalyzer` → `FeedbackEngine`
- **Data-driven localization**: `LocalizedString` with 9 languages (no .strings files)
- **Sendable everywhere**: All shared types conform to `Sendable`
- **Value types preferred**: `struct` and `enum` over `class`

## PokeDrug Framework

The Analysis directory contains the PokeDrug pharmacology system:

- **12 types** (`PokeDrugType`): serotonin, opioid, dopamine, empathogen, dissociative, cannabinoid, kappa, stimulant, sedative, cholinergic, adenosine, sigma
- **13 scaffolds** (`MolecularScaffold`): tryptamine, ergoline, morphinan, phenethylamine, tropane, terpenoid, isoquinoline, benzodioxole, xanthine, iboga, benzodiazepine, betaCarboline, isoxazole
- **30 species** (`PokeDrugSpecies.knownSpecies`): dex #001-#030
- **Type matchup chart** (`PokeDrugMatchup`): scaffold vs. target effectiveness
- **7 habitats** (`PokeDrugHabitat`): biome origins
- **Evolution chains** (`EvolutionChain`): biosynthetic pathways

### Adding a New Species

1. Add `PharmacokineticProfile` static entry in `PokeDrugSpecies.swift` extension
2. Add `BindingEntropyProfile` entry in `BindingEntropyProfile.swift`
3. Add `PokeDrugSpecies` entry to `knownSpecies` array with sequential dex number
4. Register PK profile in `PharmacokineticProfile.knownProfiles`
5. Update tests in `PokeDrugSpeciesTests.swift`

## Code Style

- SwiftLint config in `.swiftlint.yml`
- Max line length: 160 (warning), 200 (error)
- All public API requires doc comments
- Stats comments cite published data sources (Ki, PDSP, ChEMBL)
- Identifier exceptions for short names: `i`, `j`, `id`, `hp`, language codes

## Dependencies

- **BonhommeCore**: Zero external dependencies (Swift Package)
- **Bonhomme (iOS)**: CareKitStore (remote SPM from github.com/carekit-apple/CareKit)
- All other frameworks are Apple first-party (HealthKit, MusicKit, etc.)
