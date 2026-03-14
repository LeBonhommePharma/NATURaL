# NATURaL

**Biofeedback-Driven Chair Yoga for Every Apple Platform**

*Guided wellness sessions with real-time heart rate, Shannon Collapse Index, and multi-screen display across iPhone, Apple Watch, Apple TV, and Apple Vision Pro.*

![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![Platforms](https://img.shields.io/badge/Platforms-iOS%20|%20watchOS%20|%20tvOS%20|%20visionOS-blue)
![iOS](https://img.shields.io/badge/iOS-17%2B-green)
![watchOS](https://img.shields.io/badge/watchOS-10%2B-green)
![License](https://img.shields.io/badge/License-Proprietary-lightgrey)

> 26 bilingual poses (EN / FR-CA) | 6 guided workout plans | Real-time biofeedback | Zero external dependencies

---

## Overview

NATURaL (code name **Bonhomme**) is a chair yoga app that pairs guided poses with live biofeedback from Apple Watch. Sessions render simultaneously on your phone, TV, and Vision Pro through a unified display architecture — native tvOS companion or AirPlay 2 second-screen, with automatic fallback between them.

The **Shannon Collapse Index (SCI)** — inspired by the entropy framework in [Shannon](https://github.com/lmorency/Shannon) and the thermodynamic scoring validated in [FlexAID∆S](https://github.com/lmorency/FlexAIDdS) — measures focus coherence from heart rate variability in real time. When HRV entropy narrows during deep breathing, the SCI rises, giving practitioners a live "focus ring" on the TV display.

```
Normal resting HRV:    H ~ 6-8 bits   (broad, variable intervals)
Focused breathing:     H ~ 2-4 bits   (narrow, coherent rhythm)
                       ─────────────────────────────────────────
SCI score:             0 ──────────── 50 ──────────── 100
                       Distracted      Settling       Deep Focus
```

---

## Features

### 🧘 Pose Engine

- **26 chair yoga poses** across 3 difficulty levels with bilingual content (English / French Canadian)
- 7 anatomical categories: spine, hip, shoulder, neck, balance, breathing, full-body
- Per-pose modifications, contraindications, and breathing patterns
- Voice cue text for guided audio in both languages

### 💓 Biofeedback Pipeline

- Real-time heart rate and calorie tracking via `HKWorkoutSession`
- Shannon Collapse Index computed from R-R interval entropy
- HR zone classification with animated gauge (Recovery → Anaerobic)
- Activity ring integration (Move / Exercise / Stand)
- Apple Fitness+ session history blended into unified timeline

### 📺 Multi-Screen Display

- **Native tvOS companion** via Bonjour (`_bonhomme._tcp`) with length-prefixed JSON framing
- **AirPlay 2 second-screen** via `UIScene` with `.windowExternalDisplayNonInteractive` role
- Automatic fallback: tvOS discovery (3s timeout) → AirPlay route detection
- Shared `TVDisplayView` rendered identically on both paths

```
┌─────────────┐         ┌──────────────────┐
│  iPhone Hub │────────▸ │  tvOS Companion  │
│  (iOS 17+)  │  NW     │  (Apple TV 4K)   │
│             │  TCP    │                  │
│  Workout    │─ ─ ─ ─▸ │  TVDisplayView   │
│  Engine     │         └──────────────────┘
│             │
│  TV Display │         ┌──────────────────┐
│  Coordinator│────────▸ │  AirPlay 2       │
│             │  AVRoute │  Second Screen   │
│             │  Detect  │                  │
│             │─ ─ ─ ─▸ │  TVDisplayView   │
└─────────────┘         └──────────────────┘
       │
       │ WCSession
       ▼
┌─────────────┐
│ Apple Watch │
│ (watchOS 10)│
│             │
│ HR Sensor   │
│ Workout     │
│ Recorder    │
└─────────────┘
```

### 🍎 Platform Integration

| Feature | Framework | Platform |
|---------|-----------|----------|
| Workout recording | HealthKit (`HKWorkoutSession`) | watchOS |
| Heart rate monitoring | HealthKit (`HKAnchoredObjectQuery`) | iOS / watchOS |
| Fitness+ history | HealthKit (source bundle filter) | iOS |
| Activity rings | HealthKit (`HKActivitySummary`) | iOS |
| Live Activities | ActivityKit | iOS |
| Home & Lock Screen widgets | WidgetKit | iOS |
| Siri shortcuts | App Intents | iOS |
| Background music | MusicKit | iOS |
| Group sessions | SharePlay (`GroupActivity`) | iOS |
| Subscriptions | StoreKit 2 | iOS |
| Spatial display | RealityKit / SwiftUI | visionOS |

---

## Pose Catalog

### Difficulty Distribution

| Level | Count | Access | Categories |
|-------|-------|--------|------------|
| Beginner | 10 | Free | Spine, Hip, Shoulder, Neck, Breathing |
| Intermediate | 11 | Premium | Balance, Full-body, Hip, Shoulder |
| Advanced | 5 | Premium | Balance, Full-body, Spine |
| **Total** | **26** | | **7 categories** |

### Workout Plans

| Plan | Poses | Duration | Level | Access |
|------|-------|----------|-------|--------|
| Morning Flow | 5 | ~4 min | Beginner | Free |
| Gentle Stretch | 5 | ~4 min | Beginner | Free |
| Quick Desk Break | 5 | ~3 min | Beginner | Free |
| Full Session | 8 | ~7 min | Mixed | Premium |
| Strength & Balance | 6 | ~5 min | Intermediate | Premium |
| Advanced Chair Yoga | 8 | ~6 min | Advanced | Premium |

<details>
<summary><strong>Full pose list (click to expand)</strong></summary>

**Beginner (Free)**
1. Seated Mountain — *Montagne assise*
2. Seated Cat-Cow — *Chat-Vache assis*
3. Seated Forward Fold — *Flexion avant assise*
4. Seated Twist — *Torsion assise*
5. Seated Side Bend — *Flexion latérale assise*
6. Neck Rolls — *Roulements du cou*
7. Shoulder Rolls — *Roulements des épaules*
8. Ankle Circles — *Cercles de chevilles*
9. Wrist Stretches — *Étirements des poignets*
10. Knee Lifts — *Levées de genoux*

**Intermediate (Premium)**
11. Seated Pigeon — *Pigeon assis*
12. Seated Eagle Arms — *Bras d'aigle assis*
13. Seated Warrior I — *Guerrier I assis*
14. Chair Pose (standing) — *Posture de la chaise*
15. Seated Hip Circles — *Cercles de hanches assis*
16. Seated Figure Four — *Quatre assis*
17. Goddess — *Déesse*
18. Reverse Warrior — *Guerrier inversé*
19. Crescent Moon — *Croissant de lune*
20. Chest Expansion — *Expansion thoracique*
21. Thread the Needle — *Enfiler l'aiguille*

**Advanced (Premium)**
22. Seated Dancer — *Danseur assis*
23. Seated Crow Prep — *Préparation corbeau assis*
24. Breath of Joy — *Souffle de joie*
25. Half Moon Balance — *Demi-lune en équilibre*
26. Seated Boat — *Bateau assis*

</details>

---

## Architecture

### Shared Swift Package

All models and TV display views live in `BonhommeCore`, a platform-agnostic Swift Package compiled for iOS, watchOS, tvOS, and visionOS:

```
BonhommeCore/
├── Package.swift                    # iOS 17, watchOS 10, tvOS 17, visionOS 1
└── Sources/BonhommeCore/
    ├── Models/
    │   ├── Pose.swift               # Bilingual pose with category, difficulty, modifications
    │   ├── PoseCatalog.swift         # 26 poses + 6 workout plans
    │   ├── LocalizedString.swift     # EN/FR-CA resolver by device locale
    │   ├── WorkoutPlan.swift         # Ordered pose sequence with computed duration
    │   ├── TVDisplayPayload.swift    # Codable message: iPhone → TV surface
    │   ├── BiofeedbackSnapshot.swift # HR, HRV, SCI, calories at a point in time
    │   └── WorkoutResult.swift       # Post-session summary with HR samples
    └── TVDisplay/
        ├── TVDisplayView.swift       # Shared layout: 60% pose + 40% biofeedback
        ├── PoseCountdownView.swift   # Circular countdown timer
        ├── HeartRateGaugeView.swift   # BPM gauge with HR zone
        ├── SCIVisualizationView.swift # Focus ring with trend indicator
        └── SessionProgressView.swift  # Pose dots + elapsed time
```

### Bilingual Data Model

Instead of `.strings` files, NATURaL uses a data-driven approach where all content is self-contained in the Swift Package:

```swift
public struct LocalizedString: Codable, Sendable, Hashable {
    public let en: String
    public let fr: String
    public var localized: String {
        Locale.current.language.languageCode?.identifier
            .hasPrefix("fr") == true ? fr : en
    }
}
```

### TV Display State Machine

```
         ┌──────────┐
         │   idle   │
         └────┬─────┘
              │ start()
              ▼
         ┌──────────┐    found tvOS     ┌───────────┐
         │searching │───────────────────▸│ nativeTV  │
         └────┬─────┘                   └───────────┘
              │ 3s timeout
              ▼
     ┌─────────────────┐  user picks    ┌─────────────────────┐
     │airplayAvailable │───────────────▸│airplaySecondScreen  │
     └─────────────────┘  AirPlay route └─────────────────────┘
```

### Repository Structure

```
NATURaL/
├── Bonhomme/                        # iOS app (iPhone hub)
│   ├── App/                         # @main entry, AppState
│   ├── Features/
│   │   ├── Workout/                 # Flow VM, guided session UI, home
│   │   ├── Summary/                 # Post-workout charts
│   │   ├── History/                 # Blended NATURaL + Fitness+ timeline
│   │   └── Paywall/                 # StoreKit 2 subscription view
│   ├── Services/
│   │   ├── HealthKit/               # HR, workout recorder, Fitness+ reader
│   │   ├── Music/                   # MusicKit yoga playlists
│   │   ├── SharePlay/               # GroupActivity session coordinator
│   │   ├── Siri/                    # App Intents + shortcuts
│   │   └── Subscription/            # StoreKit 2 entitlements
│   ├── TVRelay/                     # Coordinator, AirPlay, native companion
│   └── Shared/Components/           # Activity rings, reusable views
├── BonhommeCore/                    # Shared Swift Package
│   ├── Sources/BonhommeCore/        # Models + TV display views
│   └── Tests/BonhommeCoreTests/     # 6 unit test suites
├── BonhommeTV/                      # tvOS companion app
│   ├── App/                         # @main entry
│   ├── Networking/                  # NWListener Bonjour service
│   └── Views/                       # TV root + idle views
├── BonhommeWatch/                   # watchOS app (placeholder)
├── BonhommeVision/                  # visionOS app (placeholder)
├── NATURaLLiveActivity/             # ActivityKit Dynamic Island
├── NATURaLWidgets/                  # Streak + Activity Rings widgets
└── Tests/
    ├── BonhommeTests/               # iOS app unit tests
    └── BonhommeUITests/             # Xcode UI test suites
```

---

## Build

### Requirements

| Dependency | Version |
|-----------|---------|
| Xcode | 15.0+ |
| Swift | 5.9+ |
| iOS deployment | 17.0+ |
| watchOS deployment | 10.0+ |
| tvOS deployment | 17.0+ |
| visionOS deployment | 1.0+ |
| External dependencies | **None** |

### Quick Start

```bash
# Clone
git clone https://github.com/lmorency/NATURaL.git
cd NATURaL

# Open in Xcode
open Bonhomme.xcodeproj    # or .xcworkspace

# Select scheme → Bonhomme, destination → iPhone 15 Pro
# ⌘R to build and run
```

### Targets

| Scheme | Destination | Description |
|--------|-------------|-------------|
| Bonhomme | iPhone Simulator (iOS 17+) | Main hub app |
| BonhommeTV | Apple TV 4K Simulator (tvOS 17+) | TV companion |
| BonhommeWatch | Apple Watch Series 9 (watchOS 10+) | HR sensor + workout |
| BonhommeVision | Apple Vision Pro (visionOS 1.0+) | Spatial yoga |

---

## Testing

```bash
# BonhommeCore unit tests (platform-agnostic)
xcodebuild test -scheme BonhommeCore -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# iOS app unit tests
xcodebuild test -scheme Bonhomme -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# UI tests (requires simulator)
xcodebuild test -scheme BonhommeUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Test Suites

| Suite | Tests | Scope |
|-------|-------|-------|
| `LocalizedStringTests` | 5 | Codable, hashable, EN/FR resolution |
| `PoseTests` | 5 | Init, codable, difficulty/category enums |
| `PoseCatalogTests` | 10 | Unique IDs, bilingual coverage, distribution |
| `WorkoutPlanTests` | 4 | Duration calc, codable, edge cases |
| `TVDisplayPayloadTests` | 4 | Codable roundtrip, nil biofeedback, SCI trend |
| `WorkoutResultTests` | 3 | Result codable, nil heart rate |
| `WorkoutFlowViewModelTests` | 3 | Plan structure, TV payload, localization |
| `TVDisplayCoordinatorTests` | 3 | Payload size <10KB, framing, Bonjour type |
| `WorkoutFlowUITests` | 5 | Home screen, navigation, countdown, a11y |
| `AirPlayFallbackUITests` | 3 | TV section, connection prompt, stability |

---

## Related Projects

| Project | Role |
|---------|------|
| [Shannon](https://github.com/lmorency/Shannon) | Entropy collapse detection — provides the mathematical foundation for the SCI biofeedback metric |
| [FlexAID∆S](https://github.com/lmorency/FlexAIDdS) | Entropy-driven molecular docking — validated the thermodynamic scoring framework adapted for HRV analysis |

---

## License

Proprietary. All rights reserved.

## Contributing

This project is currently in private development. Contact the maintainer for collaboration inquiries.
