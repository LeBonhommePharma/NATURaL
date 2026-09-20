# App Privacy labels — derived from source, 20 September 2026

Every answer below is derived from code and cites the file and line that
establishes it. Where the code does not settle a question, the answer is an em
dash and the question is listed under **Open — needs LP**. Nothing here is filled
in plausibly.

Companion to [app-store-connect.md](app-store-connect.md), which holds the
prepared portal answers. This file is the evidence behind them.

## Proposed questionnaire answer: **Data Not Collected**

Apple's definition of *collect* is transmitting data off the device in a way that
lets the developer or a partner access it beyond the transient processing needed
to serve the request. On that definition nothing qualifies, for the reasons below.

## What the app reads

### HealthKit — read

Derived by enumerating every `HK*Type` constructed in app sources:

| Type | Sites |
|---|---|
| `heartRate` | 8 |
| `activeEnergyBurned` | 6 |
| `heartRateVariabilitySDNN` | 5 |
| `HKSeriesType.heartbeat` | 3 |
| `mindfulSession` | 3 |
| `restingHeartRate` | 2 |
| `respiratoryRate` | 2 |
| `workoutType()` | 2 |
| `sleepAnalysis` | 2 |
| `appleExerciseTime` | 1 |
| `electrocardiogramType()` | 1 |
| `activitySummaryType()` | 1 |

Clinical records are separately entitled: `Bonhomme/Bonhomme.entitlements`
declares `com.apple.developer.healthkit.access = ['health-records']`, and
`Bonhomme/Info.plist` carries `NSHealthClinicalHealthRecordsShareUsageDescription`.
Clinical reads are additionally gated behind in-app consent
(`BonhommeCore/.../ClinicalConsentTests.swift` covers the gate).

**Not declared as collected.** HealthKit data is read under user authorization,
processed on device, and never transmitted to a developer endpoint — there is no
such endpoint (see *Network*). Apple's guidance is not to declare Health as
collected solely because the user authorized a local read.

### HealthKit — write

`com.apple.developer.healthkit` plus `NSHealthUpdateUsageDescription`
(`Bonhomme/Info.plist`); workouts are written via `HKWorkoutBuilder`
(`Bonhomme/Services/HealthKit/WorkoutRecorder.swift:8`). Writing into the user's
own Health store is not collection.

### MusicKit

`Bonhomme/Services/Music/MusicService.swift:4` imports MusicKit;
line 122 calls `MusicAuthorization.request()`. Apple Music is the user's
relationship with Apple. The app receives playback capability, does not read a
library inventory to transmit, and has nowhere to transmit it.

### Camera / Motion

`NSCameraUsageDescription` and `NSMotionUsageDescription` (`Bonhomme/Info.plist`).
Camera is the optional AR coach and is not requested on the ready screen —
`test_contracts.py` asserts `phase == .active` gating in `PoseCoachStage.swift`.
Frames are not persisted or transmitted.

## Network destinations

Complete enumeration of outbound networking in shipping code:

| Destination | Where | Ships? |
|---|---|---|
| Local-network TLS-PSK to a paired Apple TV | `Bonhomme/TVRelay/NativeCompanionClient.swift:45`, `BonhommeTV/Networking/CompanionListener.swift:30` | **Yes** — LAN only, no internet, no developer server |
| `https://www.youtube.com/iframe_api` in a `WKWebView` | `Bonhomme/Features/Workout/YouTubePlayerView.swift:80,109` | **No** — file is `#if DEBUG && canImport(UIKit)` at line 2 |
| `https://www.apple.com/legal/privacy/` | `Bonhomme/App/BonhommeApp.swift:436` | Yes — a `Link` the user taps; opens Safari |

**There is no developer-operated server.** No `URLSession`, no `URLRequest`, no
upload endpoint anywhere in shipping sources.

## Third-party SDKs

One dependency: **CareKit** (`carekit-apple/CareKit.git`, from
`NATURaL.xcodeproj`). Apple-published, open source, local CareKit store. It
receives prescription and adherence data **on device**; it has no network
component here.

No analytics, advertising, attribution or crash-reporting SDK is present —
searched for Firebase, Amplitude, Mixpanel, Segment, Sentry, Crashlytics,
AppsFlyer, Adjust, Facebook, AdMob and Google Analytics. Zero hits.

## Cloud and off-device sync

- SwiftData sets `cloudKitDatabase: .none` at
  `Bonhomme/Services/Persistence/PersistentModels.swift:517` and `:564`.
- No iCloud entitlement in any `.entitlements` file.
- `NSUbiquitousKeyValueStore` appears **once**, in a comment at
  `BonhommeCore/.../ClusterFleetPresence.swift:8` describing a wire format. The
  API is never called.
- `ClusterFleetPresenceCoordinator` uses `UserDefaults` only and documents "Does
  not publish presence off this device" (`.../ClusterFleetPresenceCoordinator.swift:19`).

## Tracking

`NSPrivacyTracking = false` and `NSPrivacyTrackingDomains = []` in all seven
manifests. No ATT prompt, no IDFA, no `AppTrackingTransparency` import.
**Answer: no tracking.**

## Linked to identity

Nothing is transmitted, so nothing can be linked. The install id in
`ClusterFleetPresenceCoordinator` is device-local in `UserDefaults` and never
leaves.

## Cross-check against the shipped manifests — one finding

All seven source manifests agree with this derivation: tracking false, tracking
domains empty, collected data types empty.

**The finding is in the guard, not the manifests.** `test_contracts.py` checked
each manifest by asking whether the text contained `<key>NSPrivacyTracking</key>`
and, separately, `<false/>` anywhere. Those are independent substrings: a manifest
declaring `NSPrivacyTracking=true` satisfied both as long as any other key was
false. Verified by flipping it — the suite stayed green.

This was the only guard for five of the seven, because `validate-submission.py`
parses manifests inside its `Bonhomme`/`BonhommeWatch` loop only (line 56).
Fixed: the check now parses with `plistlib` and asserts values, and the flip is
caught in all seven.

`NATURaLLiveActivity` carries no `NSPrivacyAccessedAPITypes`. That is correct,
not an omission — it has zero `UserDefaults`/`@AppStorage` references.

## Open — needs LP, deliberately unanswered

1. **Does any backend exist that this repo cannot see?** Everything above is
   derived from this checkout. If a server, TestFlight-only build or future sync
   exists, the answer changes. — 
2. **Is the App Group container shared with anything beyond the widgets and Live
   Activity?** `group.com.natural.Bonhomme` is declared in three targets'
   entitlements; scope beyond this repo is unverifiable here. — 
3. **`aps-environment = development` is in `Bonhomme.entitlements`.** No push
   registration code was found. If push is intended for release, it needs a
   privacy answer and the entitlement needs promoting to production; if not, it
   should be removed. — 
4. **Clinical records retention.** The app reads them under consent and stores
   locally; whether LP intends any export path is not determinable from code. — 
