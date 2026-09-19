# NATURaL release privacy and health-content review

Source inspection: 19 September 2026. Scope: app-owned iOS/iPadOS sources, embedded Watch, extensions, shared core, resolved dependencies and submission copy. This is source evidence; it is not a network capture, hardware result, signed-archive review, or medical validation. Native macOS and ClusterFuck need their own release inventories.

## Data-flow inventory

| Input / feature | Processing and destination | Source evidence | Release verification |
| --- | --- | --- | --- |
| Heart rate, HRV, activity, energy, sleep and workouts | HealthKit reads on device; app analysis and optional Health workout writes | `Bonhomme/Services/HealthKit/HealthKitManager.swift`, `HeartRateMonitor.swift`, `WorkoutRecorder.swift` | Test unavailable, denied, partial and revoked access; confirm requested data matches implemented features |
| Clinical medication records | Consent-gated HealthKit FHIR reads into memory, then local SwiftData schedules and CareKit tasks | `MedicationTracker.swift`, `MedicationPrescriptionService.swift`, `CareKitBridge.swift` | Test actual Health Records entitlement/institution access, empty results and revocation during a pending read |
| Manual medication names, dose entries and notes | Local schedules, CareKit adherence, local analysis and App Group intent snapshots | Same services plus `Bonhomme/Services/Siri/IntentBridge.swift` | Verify save failures, retained records, deletion paths and whether Siri outputs expose information on locked devices |
| Workout history and analysis records | Local SwiftData store; no configured CloudKit database | `Bonhomme/Services/Persistence/PersistentModels.swift` | Inspect final SQLite, WAL/SHM, backup flags and file protection on new and upgraded installations |
| Recovery state, consent and settings | UserDefaults in app container; shared intent/widget data in App Group suite | `WorkoutStateStore.swift`, `ClinicalConsent.swift`, `IntentBridge.swift`, `AppGroupStore` | Verify backup/protection behavior and shared-container retention after app removal |
| Paired Watch | Heart-rate/biofeedback snapshots, session state and completed workout results to paired iPhone through WatchConnectivity | Phone and Watch connectivity bridges | Test paired hardware, delayed transfer, reconnect, pause/end ordering and denied Watch Health permissions |
| Widgets, Siri and Live Activities | App Group snapshots and system UI surfaces, including potentially visible lock-screen data | `IntentBridge.swift`, widget/Live Activity sources | Check lock-screen privacy and stale-data behavior; system surfaces are distinct from developer collection |
| Adaptive music | MusicKit authorization, catalog lookup and playback through Apple; app consumes no developer music backend | `Bonhomme/Services/Music/MusicService.swift` | Inspect Release traffic and denied/limited Music access; Apple service processing is separate from app-owned storage |
| Headphone motion | Local Core Motion/AVFoundation control input | `HeadphoneMotionActuator.swift`, `LowLatencyAudioRouter.swift` | Hardware permission and availability testing |
| SharePlay | Plan ID/name, pose index, pause/resume/completion and timestamp via GroupActivities | `ChairYogaActivity.swift`, `SessionCoordinator.swift` | Verify user-selected session activation and final reachability. Current sync-message model has no medication/HR fields |
| Local TV display | Native Bonjour/TCP relay payload can contain HR, SCI, calories and pose state; AirPlay uses system display routing | `TVDisplayCoordinator.swift`, `TVDisplayPayload.swift` | No caller of `beginTVDiscovery` found in inspected shipping sources. Before enabling native discovery, require explicit destination selection and authenticated/secure transport; current implementation chooses first advertised endpoint over TCP |
| Generated narratives and cues | Explicit `SystemLanguageModel.default`, no tools, with template fallback | `InsightEngine.swift` | Test supported Apple Intelligence device and unavailable-model fallback; verify generated claims and language |
| Video player | YouTube iframe API in WKWebView under `#if DEBUG && canImport(UIKit)` | `YouTubePlayerView.swift` | Verify Debug is absent from final Release compilation; reclassify privacy/content if enabled in Release |
| Exported workout cards | System share sheet to user-selected destination | Summary/export UI | Preview exported content and explain destination retention; developer does not receive copies automatically |
| Website links and support email | External browser requests to GitHub Pages; email to developer only when user sends it | App About links; generated support/privacy site | Validate deployed policy, hosting behavior and voluntary email handling separately from in-app collection |

No app-owned developer upload endpoint, third-party analytics/tracking SDK, pharmacy credential flow or remote inference call was found in the inspected source. This supports the proposed **Data Not Collected** answer; it does not prove the absence of behavior in an uninspected final binary or future dependency change.

Apple's collection definition concerns off-device data made available to the developer or integrated partners beyond servicing the request. On-device processing and actual remote collection must be distinguished when completing the questionnaire. [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

## Consent and persistence changes

The review found a concrete race: consent was checked before awaiting HealthKit; a later result could repopulate clinical profiles after revocation and then enter SwiftData/CareKit. The fix introduces a grant-scoped `ConsentStore.AccessToken` and rechecks it after asynchronous work, before new writes and before publishing status. Grant, revoke and reset invalidate older tokens; regranting with the same timestamp cannot revive them. Task cancellation also invalidates an operation. CareKit checks the same token between each suspended operation rather than acquiring fresh permission halfway through an old sync.

Revocation clears the in-memory clinical profiles and current sync status. It does not undo a CareKit transaction already submitted under valid consent or delete older local records. That is an explicit limit, not a claim that a committed record has been erased. Hardware withdrawal tests remain required.

The review also corrected CareKit outcome handling: a storage error previously returned as successful completion. The code now verifies whether the same occurrence was actually written by another caller; otherwise it propagates the error. Consent audit entries omit medication IDs and arbitrary error descriptions. A successful Health authorization request or empty clinical query is no longer represented as evidence that read access was granted.

Manual medication entry now propagates SwiftData save failures before publishing a tracker profile or success audit. Failed inserts are removed without rolling back unrelated pending changes. The form retains its fields and displays a retry error. Clinical-import fetch/save failures stop before CareKit synchronization, and partial/failed syncs do not acquire a new successful-sync timestamp. Hosted regression tests cover failed-save cleanup, preserved unrelated edits and duplicate-free retry/import; they require Xcode and have not run on this CLT-only machine.

## Health-content findings

The Release prescription screens include substance reference data, expected entropy ranges and pharmacokinetic profiles. Listing and age-rating answers must include those surfaces. A yoga-only reading of the metadata is insufficient.

`InsightEngine` previously described simultaneous docking and HRV values as molecular binding detection or established correlation, without a corresponding causal measurement. Its deterministic copy and model instructions now distinguish imported molecular results, reference values and observed HRV changes. Timing or co-occurrence is not proof of medication causality, receptor occupancy or clinical benefit. The numerical analysis code was not redefined by this copy correction.

Still review the provenance and uncertainty of every reference profile, match/confidence label and generated response in the final UI. In particular, expected HRV ranges and reference configurational entropy values must not be presented as personally validated medical measurements. This review does not certify the research framework, validate reference values, or establish a medical-device claim. Apple reviews potentially inaccurate diagnostic/treatment information and health-data use under its applicable guidelines. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).

## Dependency and license evidence

The resolved graph includes CareKit 4.1.0, Swift Async Algorithms 1.0.1, Swift Collections 1.4.1 and FHIRModels 0.5.0. CareKitStore links AsyncAlgorithms and its Collections products. FHIRModels is resolved but belongs to CareKitFHIR, which the inspected app target does not link. See [third-party-notices.md](third-party-notices.md) for exact revisions and complete license copies with SHA-256 receipts. Reconcile final linked products and bundled notices against the archive.

## Validation boundaries

- New `ClinicalConsentTests` exercise grant/revoke, same-timestamp revoke/regrant, reset, cancellation and external policy changes.
- A direct Foundation-only executable compiled the actual `ClinicalConsent.swift` with a temporary smoke harness and passed grant, revoke, same-timestamp regrant, reset, cancellation and external-policy-change checks on this machine. This isolates consent-token behavior; it does not exercise HealthKit, CareKit or the app target.
- Swift source parsing succeeds for the modified HealthKit/CareKit/insight files. Parsing is not framework type checking or device testing.
- The machine currently has Command Line Tools but no usable Xcode test SDK. Even the isolated Foundation-only SwiftPM test package cannot resolve `XCTest`; the app and full core test suite are not claimed green.
- Before submission: run tests under Xcode, exercise consent races against actual HealthKit/CareKit, inspect storage protection/backup attributes, capture release network behavior, review archive privacy aggregation and bundled licenses, and verify the deployed multilingual policy against the same build.
