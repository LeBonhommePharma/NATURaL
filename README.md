<h1 align="center">
<pre>
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║    ███╗   ██╗ █████╗ ████████╗██╗   ██╗██████╗  █████╗  ║
║    ████╗  ██║██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔══██╗ ║
║    ██╔██╗ ██║███████║   ██║   ██║   ██║██████╔╝███████║ ║
║    ██║╚██╗██║██╔══██║   ██║   ██║   ██║██╔══██╗██╔══██║ ║
║    ██║ ╚████║██║  ██║   ██║   ╚██████╔╝██║  ██║██║  ██║ ║
║    ╚═╝  ╚═══╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝ ║
║               E  N  T  R  O  P  Y     E  D  I  T  I  O  N  ║
║                                                          ║
║        Biofeedback-Driven Chair Yoga for Every           ║
║                   Apple Platform                         ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
</pre>
</h1>

<p align="center">
  <i>Guided wellness sessions with real-time heart rate, Shannon Collapse Index, adaptive music, CareKit prescriptions, and multi-screen display across iPhone, iPad, Apple Watch, Apple TV, and Apple Vision Pro.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/TYPE-FIRE%20%2F%20SWIFT_5.9-orange?style=for-the-badge" alt="Swift">
  <img src="https://img.shields.io/badge/TYPE-GRASS%20%2F%20iOS_17%2B-green?style=for-the-badge" alt="iOS">
  <img src="https://img.shields.io/badge/TYPE-WATER%20%2F%20watchOS_10%2B-blue?style=for-the-badge" alt="watchOS">
  <img src="https://img.shields.io/badge/TYPE-PSYCHIC%20%2F%20visionOS_1%2B-purple?style=for-the-badge" alt="visionOS">
  <img src="https://img.shields.io/badge/TYPE-ELECTRIC%20%2F%20tvOS_17%2B-yellow?style=for-the-badge" alt="tvOS">
  <img src="https://img.shields.io/badge/LICENSE-PROPRIETARY-lightgrey?style=for-the-badge" alt="License">
</p>

<p align="center">
  <code>26 bilingual poses (EN / FR-CA)</code> ·
  <code>6 guided workout plans</code> ·
  <code>Real-time biofeedback</code> ·
  <code>CareKit clinical integration</code> ·
  <code>CloudKit sync</code> ·
  <code>Zero external dependencies</code>
</p>

---

```
           NATURaL RPG                 TRAINER CARD
   ╔════════════════════════╗    ╔═══════════════════════╗
   ║  Press START to begin  ║    ║ NAME: Bonhomme        ║
   ║                        ║    ║ REGION: Apple          ║
   ║   ◄ NEW GAME ►        ║    ║ BADGES: 13             ║
   ║     CONTINUE           ║    ║ CODEX: 26/26           ║
   ║     OPTIONS            ║    ║ TIME: ∞                ║
   ╚════════════════════════╝    ╚═══════════════════════╝
```

---

## Codex Entry #001 — Overview

```
┌─────────────────────────────────────────────────────┐
│  #001  NATURaL                                      │
│  Code Name: Bonhomme                                │
│  Type: BIOFEEDBACK / ENTROPY                        │
│  Region: All Apple Platforms                        │
│                                                     │
│  "A chair yoga app that pairs guided poses with     │
│   live biofeedback from Apple Watch. Sessions       │
│   render simultaneously on phone, TV, and Vision    │
│   Pro through a unified display architecture."      │
│                                                     │
│  STATS          ░░░░░░░░░░░░░░░░░░░░                │
│  HP ████████████████████░░░  85/100                  │
│  ATK ██████████████░░░░░░░  65/100  (Entropy)       │
│  DEF ████████████████████░  90/100  (Stability)     │
│  SPD ██████████████████░░░  80/100  (Real-time)     │
│  SP  █████████████████████  95/100  (Multi-signal)  │
└─────────────────────────────────────────────────────┘
```

The **Shannon Collapse Index (SCI)** — inspired by the entropy framework in [Shannon](https://github.com/lmorency/Shannon) and the thermodynamic scoring validated in [FlexAID∆S](https://github.com/lmorency/FlexAIDdS) — measures focus coherence from heart rate variability in real time. When HRV entropy narrows during deep breathing, the SCI rises, giving practitioners a live "focus ring" on every display surface.

```
Normal resting HRV:    H ~ 6-8 bits   (broad, variable intervals)
Focused breathing:     H ~ 2-4 bits   (narrow, coherent rhythm)
                       ─────────────────────────────────────────
SCI score:             0 ──────────── 50 ──────────── 100
                       Distracted      Settling       Deep Focus
```

---

## Moves & Abilities

> *NATURaL acquired the following skills!*

### MOVE 1 — Pose Engine `NORMAL`

| | |
|---|---|
| **Power** | 26 poses / 3 levels |
| **Accuracy** | Bilingual EN + FR-CA |
| **PP** | Unlimited |

- **26 chair yoga poses** across 3 difficulty levels with bilingual content (English / French Canadian)
- 7 anatomical categories: spine, hip, shoulder, neck, balance, breathing, full-body
- Per-pose modifications, contraindications, and breathing patterns
- Voice cue text for guided audio in both languages
- Category-specific SF Symbols and accent colors for visual differentiation

---

### MOVE 2 — Biofeedback Pipeline `PSYCHIC`

| | |
|---|---|
| **Power** | Real-time HRV |
| **Accuracy** | Shannon Entropy |
| **PP** | Continuous |

- Real-time heart rate and calorie tracking via `HKWorkoutSession`
- **Shannon Collapse Index** computed from R-R interval entropy via shared `EntropyCalculator`
- Generalized `HealthSignal` → `SignalAnalyzer` → `FeedbackEngine` architecture supporting unlimited signal types
- Cross-signal correlation (medication timing vs. HRV response)
- HR zone classification with animated gauge (Recovery → Anaerobic)
- Activity ring integration (Move / Exercise / Stand)
- Apple Fitness+ session history blended into unified timeline
- Background delivery for HRV, sleep, respiratory rate, and medication records

---

### ABILITY — Multi-Signal Analysis Engine `DRAGON`

*Critical hit!* The analysis pipeline is built on a protocol-driven architecture that generalizes the SCI methodology to any health signal:

```
HealthSignal (protocol)          SignalAnalyzer (protocol)
├── HRVSignal ──────────────────▸ HRVAnalyzer (Shannon entropy → SCI)
├── MedicationSignal ───────────▸ MedicationAnalyzer (adherence scoring)
├── DockingSignal ─────────────▸ DockingInsightAnalyzer (FlexAID∆S entropy)
└── SurveySignal ───────────────▸ (extensible for ResearchKit surveys)
                                         │
                                         ▼
                                   FeedbackEngine
                                   (orchestrator with cross-signal context)
                                         │
                                         ▼
                                   AnalysisInsight
                                   (score 0–1, trend, status, bilingual summary)
```

The `EntropyCalculator` — extracted as a shared utility — enables entropy-based scoring for any distribution: HRV intervals, sleep stage durations, respiratory rate patterns, or activity variability.

---

### MOVE 3 — Drug Response Analysis (PokeDrug) `POISON`

| | |
|---|---|
| **Power** | 70+ pharmacokinetic profiles |
| **Accuracy** | p < 0.05 validated |
| **PP** | Per-dose event |

Detects autonomic drug response signatures by measuring Shannon entropy changes in HRV RR-interval distributions around medication dose events — the physiological analog of [FlexAID∆S](https://github.com/lmorency/FlexAIDdS) molecular docking entropy:

```
FlexAID∆S (in silico)           NATURaL (in vivo)
─────────────────────           ─────────────────────
Torsional angles (°)            RR intervals (ms)
H = -Σ p_i log₂(p_i)           H = -Σ p_i log₂(p_i)     ← same math
Binding → ΔS_config < 0        Drug → ΔH_hrv < 0         ← same signal
                    ↘                     ↙
                  EntropyCalculator (shared)
```

- **DrugResponseAnalyzer** — Computes baseline entropy (30 min pre-dose), measures ΔH at post-dose windows (15–360 min), detects entropy collapse (sympathomimetic) or expansion (parasympathomimetic)
- **70+ pharmacokinetic profiles** — Substance database with autonomic mechanism, Tmax, expected ΔH range, therapeutic class, and FDA status
- **60+ binding entropy profiles** — Published ΔS_config values (bits) and -TΔS (kcal/mol) from computational chemistry literature
- **CrossDomainValidator** — Correlates |ΔS_config| (molecular) with |ΔH_hrv| (physiological) via Pearson r to validate the entropy-collapse framework across domains
- **FlexAIDdSAnalyzer** — Computes configurational entropy from torsional angle distributions using the same EntropyCalculator
- **MedicationTracker** — HealthKit FHIR medication import, manual dose logging, automatic drug response analysis

See [POKEDRUG_PLAN.md](POKEDRUG_PLAN.md) for the complete technical plan.

---

### MOVE 4 — Adaptive MusicKit `FAIRY`

| | |
|---|---|
| **Power** | SCI-driven |
| **Accuracy** | 3s crossfade |
| **PP** | Per-session |

Music dynamically adjusts based on real-time SCI during workouts:
- **High coherence + improving** (SCI > 70%): crossfade to energizing playlists
- **Low coherence** (SCI < 30%): fade to meditative/calming tracks
- **Mid-range**: maintain current mood
- 30-second debounce prevents jarring rapid transitions
- 3-second volume crossfade between mood switches

---

### MOVE 5 — CareKit Integration `STEEL`

| | |
|---|---|
| **Power** | Clinical-grade |
| **Accuracy** | OCKStore |
| **PP** | Prescribed |

For clinical and rehabilitation settings where a therapist prescribes yoga regimens:
- `CareKitBridge` manages `OCKStore` with prescribed task scheduling
- `YogaTaskBuilder` maps `WorkoutPlan` to `OCKTask` with frequency-based scheduling
- Workout completions automatically recorded as `OCKOutcome` with duration, calories, SCI score
- Adherence tracking over configurable time windows
- "Prescribed" section in HomeView when active prescriptions exist

---

### MOVE 6 — State Restoration `GHOST`

| | |
|---|---|
| **Power** | Seamless |
| **Accuracy** | 5s intervals |
| **PP** | Automatic |

If the app is killed mid-workout, the session resumes seamlessly:
- `WorkoutStateStore` persists phase, pose index, and timing every 5 seconds
- On relaunch, the app detects persisted state and offers a resume prompt
- HealthKit workout sessions recovered via `HKWorkoutSession` persistence (iOS 17+)
- State cleared on normal completion or explicit stop

---

### MOVE 7 — CloudKit Sync `ICE`

| | |
|---|---|
| **Power** | Cross-device |
| **Accuracy** | SwiftData |
| **PP** | Automatic |

Cross-device persistence with automatic iCloud synchronization:
- `WorkoutRecord` — full workout history with SCI scores
- `SessionStreak` — daily practice streak tracking
- `UserPreferences` — language, music mood, notification settings
- `MedicationSchedule` — user-defined dose reminders
- Shared app group container for widget data access
- Automatic fallback to local storage when iCloud unavailable

---

### MOVE 8 — Apple Intelligence `PSYCHIC`

| | |
|---|---|
| **Power** | On-device AI |
| **Accuracy** | FoundationModels |
| **PP** | iOS 26+ |

On-device insight generation via the FoundationModels framework:
- `InsightEngine` synthesizes natural-language narratives from multi-signal analysis
- Personalized pose coaching based on current biofeedback context
- Post-workout summary generation correlating HRV, medication, and survey data
- Template-based bilingual fallback on pre-iOS 26 devices

---

### MOVE 9 — Multi-Screen Display `FLYING`

| | |
|---|---|
| **Power** | 5 surfaces |
| **Accuracy** | Bonjour + AirPlay |
| **PP** | Simultaneous |

- **Native tvOS companion** via Bonjour (`_bonhomme._tcp`) with length-prefixed JSON framing
- **AirPlay 2 second-screen** via `UIScene` with `.windowExternalDisplayNonInteractive` role
- Automatic fallback: tvOS discovery (3s timeout) → AirPlay route detection
- Shared `TVDisplayView` rendered identically on both paths

```
                                       ┌──────────────────┐
              ┌───── NWConnection ────▸ │  tvOS Companion  │
              │                        │  TVDisplayView    │
┌─────────────┤                        └──────────────────┘
│  iPhone Hub │
│  (iOS 17+)  │                        ┌──────────────────┐
│             ├───── AVRouteDetect ───▸ │  AirPlay 2       │
│  Workout    │                        │  Second Screen    │
│  Engine     │                        └──────────────────┘
│             │
│  FeedbackEng│                        ┌──────────────────┐
│  ine + SCI  ├───── WCSession ───────▸ │  Apple Watch     │
│             │      (biofeedback)     │  Native HKSession│
│  Adaptive   │                        │  On-wrist SCI    │
│  MusicKit   │                        └──────────────────┘
│             │
│  CareKit    │                        ┌──────────────────┐
│  Bridge     ├───── SwiftUI ─────────▸ │  iPad            │
│             │      (NavigationSplit)  │  60/40 Split     │
│  SwiftData  │                        └──────────────────┘
│  + CloudKit │
└─────────────┤                        ┌──────────────────┐
              └───── RealityKit ──────▸ │  Vision Pro      │
                                       │  Immersive Space │
                                       │  3D Pose Figure  │
                                       └──────────────────┘
```

---

### Party Roster — Platform Integration

> *Your party is ready for battle!*

| Feature | Framework | Platform |
|---------|-----------|----------|
| Workout recording | HealthKit (`HKWorkoutSession`) | iOS / watchOS |
| Heart rate monitoring | HealthKit (`HKAnchoredObjectQuery`) | iOS / watchOS |
| On-wrist SCI computation | FeedbackEngine + HRVAnalyzer | watchOS |
| Watch ↔ Phone relay | WatchConnectivity (`WCSession`) | watchOS / iOS |
| Fitness+ history | HealthKit (source bundle filter) | iOS |
| Activity rings | HealthKit (`HKActivitySummary`) | iOS |
| Background delivery | HealthKit (`enableBackgroundDelivery`) | iOS |
| Medication records | HealthKit (FHIR clinical records) | iOS |
| Mindful session write | HealthKit (`HKCategoryType.mindfulSession`) | iOS |
| Live Activities | ActivityKit | iOS |
| Home & Lock Screen widgets | WidgetKit | iOS |
| Siri shortcuts | App Intents (4 intents + 2 entities) | iOS |
| Adaptive music | MusicKit (SCI-driven crossfade) | iOS |
| Group sessions | SharePlay (`GroupActivity`) | iOS |
| Subscriptions | StoreKit 2 | iOS |
| Care plan prescriptions | CareKitStore (`OCKStore`) | iOS |
| Data persistence + sync | SwiftData + CloudKit | iOS |
| On-device AI insights | FoundationModels (iOS 26+) | iOS |
| iPad multicolumn | NavigationSplitView | iPadOS |
| Spatial display | RealityKit + ImmersiveSpace | visionOS |

---

## Codex — Pose Catalog

> *Collect every pose!*

### Difficulty Distribution

| Level | Caught | Access | Categories |
|-------|--------|--------|------------|
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
<summary><strong>Full Codex (click to expand)</strong></summary>

**COMMON — Beginner (Free)**
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

**UNCOMMON — Intermediate (Premium)**
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

**RARE — Advanced (Premium)**
22. Seated Dancer — *Danseur assis*
23. Seated Crow Prep — *Préparation corbeau assis*
24. Breath of Joy — *Souffle de joie*
25. Half Moon Balance — *Demi-lune en équilibre*
26. Seated Boat — *Bateau assis*

</details>

---

## Region Map — Architecture

### Shared Swift Package

All models, analysis engine, and TV display views live in `BonhommeCore`, a platform-agnostic Swift Package compiled for iOS, watchOS, tvOS, and visionOS:

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
    │   ├── BiofeedbackSnapshot.swift # HR, HRV, SCI, calories + multi-signal insights
    │   └── WorkoutResult.swift       # Post-session summary with HR samples
    ├── Analysis/
    │   ├── EntropyCalculator.swift   # Shared Shannon entropy utility (reusable)
    │   ├── HealthSignal.swift        # Protocol + HRVSignal, MedicationSignal, DockingSignal
    │   ├── SignalAnalyzer.swift      # Protocol + AnalysisInsight, AnalysisContext
    │   ├── HRVAnalyzer.swift         # Shannon Collapse Index from R-R intervals
    │   ├── MedicationAnalyzer.swift  # Adherence scoring with HRV correlation
    │   ├── FeedbackEngine.swift      # Thread-safe multi-signal orchestrator
    │   ├── DrugResponseAnalyzer.swift # ΔH detection around medication dose events
    │   ├── PharmacokineticProfile.swift # 70+ substance PK/autonomic profiles
    │   ├── BindingEntropyProfile.swift # 60+ molecular ΔS_config reference values
    │   ├── FlexAIDdSAnalyzer.swift   # Torsional ΔS_config computation
    │   ├── CrossDomainValidator.swift # |ΔS_config| ↔ |ΔH_hrv| correlation
    │   └── DockingInsightAnalyzer.swift # SignalAnalyzer adapter for FeedbackEngine
    └── TVDisplay/
        ├── TVDisplayView.swift       # Shared layout: 60% pose + 40% biofeedback
        ├── PoseCountdownView.swift   # Circular countdown timer with category color
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

### Repository Structure

```
NATURaL/
├── Bonhomme/                        # iOS app (iPhone + iPad hub)
│   ├── App/                         # @main entry, AppState, SwiftData container
│   ├── Features/
│   │   ├── Workout/                 # Flow VM, guided session UI, home (iPad split)
│   │   ├── Summary/                 # Post-workout charts + SwiftData persistence
│   │   ├── History/                 # Blended NATURaL + Fitness+ timeline
│   │   └── Paywall/                 # StoreKit 2 subscription view
│   ├── Services/
│   │   ├── HealthKit/               # HR, workout recorder, Fitness+ reader,
│   │   │                            # InsightEngine, MedicationTracker, ResearchKit
│   │   ├── Music/                   # MusicKit adaptive playlists (SCI-driven)
│   │   ├── Persistence/             # WorkoutStateStore, SwiftData PersistentModels
│   │   ├── CareKit/                 # CareKitBridge, YogaTaskBuilder
│   │   ├── WatchConnectivity/       # PhoneConnectivityBridge (iOS ↔ Watch)
│   │   ├── SharePlay/               # GroupActivity session coordinator
│   │   ├── Siri/                    # App Intents + 4 shortcuts
│   │   └── Subscription/            # StoreKit 2 entitlements
│   ├── TVRelay/                     # Coordinator, AirPlay, native companion
│   └── Shared/Components/           # Activity rings, reusable views
├── BonhommeCore/                    # Shared Swift Package (all platforms)
│   ├── Sources/BonhommeCore/        # Models + Analysis + TV display views
│   └── Tests/BonhommeCoreTests/     # Unit tests (entropy, analyzers, codable)
├── BonhommeTV/                      # tvOS companion app
│   ├── App/                         # @main entry
│   ├── Networking/                  # NWListener Bonjour service
│   └── Views/                       # TV root + idle views
├── BonhommeWatch/                   # watchOS companion app
│   └── App/                         # WatchApp, WorkoutManager, WCSession bridge,
│                                    # SessionView (3-page vertical), HomeView
├── BonhommeVision/                  # visionOS spatial app
│   └── App/                         # VisionApp, SpatialPoseView, ImmersivePoseSpace,
│                                    # SpatialBiofeedbackView (ornament gauges)
├── NATURaLLiveActivity/             # ActivityKit Dynamic Island
├── NATURaLWidgets/                  # Streak + Activity Rings widgets
└── Tests/
    ├── BonhommeTests/               # iOS app unit tests
    └── BonhommeUITests/             # Xcode UI test suites
```

---

## Professor's Lab — Build

### Requirements

| Dependency | Version |
|-----------|---------|
| Xcode | 15.0+ (26+ for Apple Intelligence) |
| Swift | 5.9+ |
| iOS deployment | 17.0+ |
| watchOS deployment | 10.0+ |
| tvOS deployment | 17.0+ |
| visionOS deployment | 1.0+ |
| External dependencies | **None** (CareKit added at project level) |

### Quick Start

> *The Professor: "Are you ready? Your very own NATURaL adventure is about to unfold!"*

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
| Bonhomme | iPhone / iPad Simulator (iOS 17+) | Main hub app with adaptive layout |
| BonhommeTV | Apple TV 4K Simulator (tvOS 17+) | TV companion display |
| BonhommeWatch | Apple Watch Series 9 (watchOS 10+) | Native HR sensor + on-wrist SCI |
| BonhommeVision | Apple Vision Pro (visionOS 1.0+) | Spatial yoga with 3D pose figure |

### Entitlements

| Entitlement | Purpose |
|-------------|---------|
| HealthKit | Workout recording, HR/HRV monitoring, medication records |
| HealthKit (clinical) | FHIR medication record access |
| Background Modes | HealthKit background delivery, workout processing |
| iCloud (CloudKit) | SwiftData cross-device sync |
| Apple Intelligence | On-device Foundation Model insight generation |

---

## Arena Challenge — Testing

> *"You've defeated the ARENA MASTER! You earned the test badge!"*

```bash
# BonhommeCore unit tests (platform-agnostic)
xcodebuild test -scheme BonhommeCore -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# iOS app unit tests
xcodebuild test -scheme Bonhomme -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# UI tests (requires simulator)
xcodebuild test -scheme BonhommeUITests -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Arena Badges Earned

| Badge | Tests | Scope |
|-------|-------|-------|
| `LocalizedStringTests` | 5 | Codable, hashable, EN/FR resolution |
| `PoseTests` | 5 | Init, codable, difficulty/category enums |
| `PoseCatalogTests` | 10 | Unique IDs, bilingual coverage, distribution |
| `WorkoutPlanTests` | 4 | Duration calc, codable, edge cases |
| `TVDisplayPayloadTests` | 4 | Codable roundtrip, nil biofeedback, SCI trend |
| `WorkoutResultTests` | 3 | Result codable, nil heart rate |
| `AnalyzerTests` | 17 | Shannon entropy, SCI scoring, medication adherence, FeedbackEngine multi-signal, EntropyCalculator edge cases + parity |
| `DrugResponseAnalyzerTests` | 24 | Sympathomimetic/parasympathomimetic detection, dose-response curves, profile matching, batch aggregation, Cohen's d, AUC |
| `FlexAIDdSAnalyzerTests` | 27 | Torsional entropy, ΔS_config, kcal/mol conversion, cross-domain validation, BindingEntropyProfile registry, DockingInsightAnalyzer pipeline |
| `WorkoutFlowViewModelTests` | 3 | Plan structure, TV payload, localization |
| `TVDisplayCoordinatorTests` | 3 | Payload size <10KB, framing, Bonjour type |
| `WorkoutFlowUITests` | 5 | Home screen, navigation, countdown, a11y |
| `AirPlayFallbackUITests` | 3 | TV section, connection prompt, stability |

---

## Legendary Allies — Related Projects

```
┌─────────────────────────────────────────────────────────┐
│  LEGENDARY ALLIES ENCOUNTERED!                         │
│                                                         │
│  Shannon          — Entropy collapse detection.         │
│                     Provides the mathematical           │
│                     foundation for the SCI              │
│                     biofeedback metric.                 │
│                                                         │
│  FlexAID∆S        — Entropy-driven molecular docking.   │
│                     Validated the thermodynamic          │
│                     scoring framework adapted for        │
│                     HRV analysis.                       │
└─────────────────────────────────────────────────────────┘
```

| Project | Role |
|---------|------|
| [Shannon](https://github.com/lmorency/Shannon) | Entropy collapse detection — provides the mathematical foundation for the SCI biofeedback metric |
| [FlexAID∆S](https://github.com/lmorency/FlexAIDdS) | Entropy-driven molecular docking — validated the thermodynamic scoring framework adapted for HRV analysis |

---

## Hall of Fame

```
╔══════════════════════════════════════════════════╗
║                 HALL OF FAME                     ║
║                                                  ║
║  LICENSE: Proprietary. All rights reserved.      ║
║                                                  ║
║  CONTRIBUTING:                                   ║
║  This project is currently in private            ║
║  development. Contact the maintainer for         ║
║  collaboration inquiries.                        ║
║                                                  ║
║           SAVE GAME? [Y] / [N]                   ║
╚══════════════════════════════════════════════════╝
```
