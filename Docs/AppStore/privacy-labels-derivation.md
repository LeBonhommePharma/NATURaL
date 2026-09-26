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

## Traced 20 September 2026 — code half settled, intent half separated

Three questions were previously filed whole as "needs LP". That was the wrong
split: each has a code half that is derivable and an intent half that is not.
Folding them together handed LP a vaguer question than necessary.

### App Group scope — **not shared with any other app on this disk**

Scanned every repo under `~/Projects` for an *entitlement* declaring
`group.com.natural.Bonhomme`. Declarations exist in exactly two places:

- `NATURaL/` — `Bonhomme`, `BonhommeWatch`, `NATURaLWidgets` (this app)
- `FlexAIDdS/NATURaL/` — a **copy of this same app**, same bundle ids
  (`com.natural.Bonhomme`, `.Widgets`, `.LiveActivity`, `BonhommeTV`), not a
  separate product

ClusterFuck uses a **different** group, `group.com.natural.BonhommeRemote`.
Worth recording how that surfaced: an unterminated grep for
`group.com.natural.Bonhomme` matched it, because NATURaL's group is a **prefix**
of ClusterFuck's. The terminated search (`…Bonhomme<`) did not. That is the same
name-versus-value failure this repo fixed in its guards today, reproduced in the
search used to investigate it.

**What this establishes:** the group is not shared with any other app in this
family, and that is what was checked. **What it does not:** any app signed by the
same team could declare the group without appearing on this disk. A negative
across the repos present is not proof of global absence.

*Still LP's:* whether any app outside this checkout is intended to share it. —

### `aps-environment` — **vestigial, and it ships in Release**

Exhaustive trace across every Swift file in every target. All eleven
push-adjacent symbols return zero: `UNUserNotificationCenter`,
`registerForRemoteNotifications`, `didRegisterForRemoteNotifications`,
`UNNotificationRequest`, `PushKit`, `PKPushRegistry`,
`UNUserNotificationCenterDelegate`, `remoteNotification`, `apns`,
`UNAuthorizationOptions`, `UserNotifications`. No notification service or
content extension in the project. No `remote-notification` background mode —
the only background mode anywhere is the Watch's `workout-processing`.

**The app contains no push code whatsoever.** The entitlement is vestigial.

Second finding, on configurations: each entitlements file appears exactly twice
in the pbxproj, once for Debug and once for Release, so there is a single file
per target and **`aps-environment = development` ships in the Release build**.
An App Store build carrying a `development` APNs entitlement is a signing
mismatch worth removing before archive validation rather than discovering at
upload.

*Still LP's, and now a much smaller question:* remove the unused entitlement? He
is no longer being asked whether he wants push. —

### Clinical records export — **no path exists today**

Enumerated every egress API in shipping Swift. Present: `ShareLink` (1),
`GroupActivities`/`GroupSession`/`SharePlay` (12), `WCSession` (40),
`sendMessage` (5), `updateApplicationContext` (2), `NWConnection` (8). Absent
entirely: `UIActivityViewController`, `NSSharingService`, `UIPasteboard`,
`NSPasteboard`, `fileExporter`, `URLSession`, `CKRecord`, `NSItemProvider`.

Checked each for medication, dose, drug, substance, prescription and clinical
content:

- **Share card** — a rendered image; the only data fields are date and duration.
- **TV relay payload** — no medication or clinical field of any kind.
- **WCSession / SharePlay / relay call sites** — zero matches for any of the six
  terms.

**No route carries clinical or medication data off the device today.**

**Coverage limit, stated rather than implied:** this searched 16 egress APIs and
then six clinical terms at those call sites. Data passed under a neutral name —
`payload`, `record` — whose contents happen to be clinical would not be caught by
a term search. The negative is strong but is a term search, not a taint analysis.

*Still LP's:* whether an export path is intended in future. The privacy answer
describes the shipped binary, and today that binary has none. —

## Open — needs LP

1. ~~**Does any backend exist outside this checkout?**~~ **CLOSED 20 September 2026.**
   LP, verbatim: *“backend is on device”*. That was the only half not derivable from
   the code; the code half was already settled — no developer endpoint, no `URLSession`,
   no upload path, the only internet reference a `Link` the user taps. With his answer as
   the source for the half the repository cannot show, **Data Not Collected** is no longer
   merely defensible: it is an accurate description of the shipped binary. Source of record:
   LP, relayed 20 September 2026 — not inferred from code, because code cannot prove the
   absence of a server it was never told about.
2. **Export compliance route.** `false` is defensible on the plain reading; the
   alternative is declaring encryption and claiming the exemption. Equivalent
   outcome, his preference. —
3. **Clinical records retention intent** — see above; no path exists today. —
