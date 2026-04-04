# Security Policy

## Supported Versions

| Branch | Status |
|--------|--------|
| `master` | Active development and security hardening |
| Latest tagged release (`v*`) | Receives critical and high-severity patches |

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

Please report vulnerabilities through [GitHub's private vulnerability reporting](https://github.com/lmorency/NATURaL/security/advisories/new).

### What to Include

- Affected component (BonhommeCore, HealthKit integration, CareKit bridge, network relay, CloudKit sync)
- Affected file(s) and function(s), if known
- Steps to reproduce
- Impact assessment (data exposure, crash, privilege escalation)
- Suggested fix, if any

### Response Timeline

| Phase | Target |
|-------|--------|
| Triage acknowledgement | 7 calendar days |
| Severity classification | 14 calendar days |
| Fix for critical/high | 30 calendar days |
| Public disclosure | After fix is released |

## Scope

### In Scope

- **BonhommeCore analysis engine** — All 29 analysis modules, data models, and PokeDrug framework
- **HealthKit data pipeline** — Heart rate, HRV, workout recording, medication records, clinical data (FHIR)
- **CareKit integration** — OCKStore task management, outcome recording, adherence tracking
- **CloudKit / SwiftData sync** — Cross-device data persistence and iCloud synchronization
- **Network relay** — Bonjour service discovery (`_bonhomme._tcp`), NWConnection, AirPlay 2 second-screen
- **WatchConnectivity** — WCSession data transfer between iPhone and Apple Watch
- **WidgetKit / ActivityKit** — Shared app group data access, timeline providers
- **App Intents / Siri** — Shortcut parameter handling and entity resolution

### Out of Scope

- Xcode Previews and development-only configurations
- Third-party framework internals (CareKitStore, HealthKit, MusicKit)
- UI-only issues with no data/security impact
- Prototype or research-only analysis modules not exposed to user data

## Baseline Goals

- Zero known critical vulnerabilities in the health data pipeline
- Zero known high-severity memory-safety vulnerabilities in BonhommeCore
- All HealthKit and CareKit data access follows Apple's privacy guidelines
- Network relay connections validated before data transmission

## Hardening Priorities

1. Input validation on all `Codable` deserialization boundaries (TV relay payloads, WCSession messages)
2. Bounds checking on PokeDrug stat derivation helpers
3. Thread-safety audits on `FeedbackEngine` and `WorkoutFlowViewModel`
4. Secure defaults for CloudKit container access
