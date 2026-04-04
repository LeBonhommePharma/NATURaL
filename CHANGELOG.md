# Changelog

All notable changes to NATURaL are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- 9 new PokeDrug species (#022-#030): diazepam, psilocin, MDA, scopolamine, muscimol, ephedrine, mitragynine, CBD, harmine
- `PolypharmacologyAnalyzer` — cross-reactivity analysis, synergy pair discovery, polypharmacy risk scoring
- `PokeDrugStatComparator` — head-to-head comparison, ranking, radar profiles, archetype classification
- `NATURaLWidgetsBundle` entry point for WidgetKit extensions
- Comprehensive Xcode project (`NATURaL.xcodeproj`) with all 8 platform targets
- 3 new molecular scaffolds: benzodiazepine, beta-carboline, isoxazole
- CI/CD pipeline via GitHub Actions (build, test, SwiftLint)
- `.gitignore`, `.swiftlint.yml`, `CLAUDE.md`, `CONTRIBUTING.md`, `LICENSE`
- PR template for standardized reviews

### Changed
- PokeDrug species catalog expanded from 21 to 30 entries
- README updated with PokeDrug framework documentation, corrected Xcode project reference, expanded test coverage table
- Architecture diagram now reflects 29 analysis modules

## [0.4.0] - 2026-03-28

### Added
- `PokeDrugSuperaCluster` grouping types into pharmacological families
- World of Warcraft class color palette for PokeDrug types
- 3 new molecular scaffolds with matchup chart entries and habitat associations
- 7 new PharmacokineticProfile entries (psilocin, MDA, muscimol, ephedrine, mitragynine, CBD, harmine)
- 7 new BindingEntropyProfile entries
- Translation helper script for PoseCatalog

## [0.3.0] - 2026-03-20

### Added
- 9-language internationalization (Spanish, Japanese, Chinese, Korean, Russian, German, Arabic)
- 6 computational chemistry analysis modules (LigandEfficiency, SelectivityEntropy, PopulationPK, EnthalpyEntropyCompensation, EvolutionThermodynamics, ProfileConsistencyValidator)
- BindingDB/SCORPIO thermodynamic binding profiles integrated into PokeDrug framework
- PokeDrug pharmacology classification framework (12 types, 10 scaffolds, 21 species)
- FlexAID∆S configurational entropy module with full substance coverage
- `DrugResponseAnalyzer` for FlexAID∆S independent validation via HRV entropy

## [0.2.0] - 2026-03-12

### Added
- State restoration for mid-workout recovery
- `EntropyCalculator` extracted as shared utility
- CareKit integration (`CareKitBridge`, `YogaTaskBuilder`)
- Adaptive MusicKit with SCI-driven crossfade
- CloudKit sync via SwiftData
- watchOS companion with `HKWorkoutSession` and on-wrist SCI
- visionOS spatial app with RealityKit immersive space
- iPad `NavigationSplitView` with 60/40 layout
- Apple Intelligence on-device insight generation (`InsightEngine`)
- HealthKit background delivery for HRV, sleep, respiratory rate

### Fixed
- WCSession serialization issues
- Navigation and display bugs in TV relay

## [0.1.0] - 2026-03-01

### Added
- Initial chair yoga app scaffold with tvOS/AirPlay fallback
- 26 bilingual poses (EN / FR-CA) across 3 difficulty levels
- 6 guided workout plans
- Generalized feedback analysis pipeline (HRV, medication, survey)
- Shannon Collapse Index from R-R interval entropy
- Multi-screen display architecture (tvOS Bonjour + AirPlay 2)
- Comprehensive test suite (models, analyzers, codable, UI)
- README documentation with architecture diagrams
