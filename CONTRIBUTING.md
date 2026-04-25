# Contributing to NATURaL

Thank you for your interest in contributing to NATURaL. This document provides guidelines and information for contributors.

## Development Setup

### Prerequisites

| Tool | Version |
|------|---------|
| Xcode | 15.0+ (26+ for Apple Intelligence features) |
| Swift | 5.9+ |
| macOS | Sonoma 14.0+ |

### Getting Started

```bash
git clone https://github.com/lmorency/NATURaL.git
cd NATURaL
open NATURaL.xcodeproj
```

### Project Structure

- **BonhommeCore/** — Platform-agnostic Swift Package (models, analysis, TV views)
- **Bonhomme/** — iOS app (iPhone + iPad hub)
- **BonhommeWatch/** — watchOS companion
- **BonhommeTV/** — tvOS companion
- **BonhommeVision/** — visionOS spatial app
- **NATURaLWidgets/** — WidgetKit extensions
- **NATURaLLiveActivity/** — ActivityKit Dynamic Island
- **Tests/** — iOS integration and UI tests

## Code Style

### Swift Conventions

- Follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- Use SwiftLint (configuration in `.swiftlint.yml`)
- All public types and methods require documentation comments
- Use `Sendable` conformance for all types shared across concurrency domains
- Prefer value types (`struct`, `enum`) over reference types

### Localization

All user-facing strings use the `LocalizedString` type with 9-language support:

```swift
LocalizedString(
    en: "English", fr: "French", es: "Spanish",
    ja: "Japanese", zh: "Chinese", ko: "Korean",
    ru: "Russian", de: "German", ar: "Arabic"
)
```

### Naming Conventions

- Types: `UpperCamelCase` (e.g., `PokeDrugSpecies`, `HRVAnalyzer`)
- Properties/methods: `lowerCamelCase` (e.g., `substanceId`, `analyzeInteraction`)
- Test methods: `test` + description (e.g., `testSpeciesCount`, `testLSDMaxHP`)
- Files: match primary type name (e.g., `PokeDrugSpecies.swift`)

## Branching Strategy

- `master` — stable release branch
- `claude/*` — feature branches for Claude Code development
- Feature branches should be descriptive (e.g., `feature/add-new-poses`)

## Testing

### Running Tests

```bash
# BonhommeCore unit tests
swift test --package-path BonhommeCore

# Full Xcode test suite
xcodebuild test \
    -scheme BonhommeCore \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Requirements

- All new features must include unit tests
- New PokeDrug species must include PK profile, binding entropy profile, and species tests
- Maintain 100% unique `substanceId` and `dexNumber` integrity
- All stats must be in 1-5 range with pharmacological justification in comments

## Pull Request Process

1. Create a feature branch from `master`
2. Make your changes with clear, atomic commits
3. Ensure all tests pass
4. Update documentation if adding new public API
5. Submit a PR with a clear description of changes

### Commit Message Format

```
type: short description

Longer explanation if needed.
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

## PokeDrug Framework Contributions

When adding new species to the PokeDrug catalog:

1. Add `PharmacokineticProfile` static entry with cited references
2. Add `BindingEntropyProfile` entry with rotatable bond count and entropy data
3. Add `PokeDrugSpecies` entry to `knownSpecies` array with:
   - Appropriate type(s) based on primary pharmacological target
   - Correct scaffold matching molecular structure
   - Stats derived from published data (Ki, TI, selectivity ratio, onset, t1/2)
   - Full 9-language localization for name and flavor text
   - Sequential dex number
4. Update `PokeDrugMatchup` chart if introducing a new scaffold
5. Update `PokeDrugHabitat.scaffoldsFound` if the species has a natural origin
6. Add tests validating the new entry

## Questions?

Contact the maintainer for collaboration inquiries.
