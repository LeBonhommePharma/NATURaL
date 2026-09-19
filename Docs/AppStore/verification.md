# Current release verification — 19 September 2026

## TV relay and tvOS preparation — integration `057b5aa`

The native tvOS app is now explicitly in the requested submission scope, alongside iOS/iPadOS/watchOS and macOS. AirPlay/HDMI remains a separate system-managed output path. The evidence below predates the next full CI run and does not establish a shipping television binary.

- Replaced automatic first-result Bonjour connection and plaintext TCP transport with explicit television selection and an ephemeral random 256-bit pairing credential. The TV generates a QR invitation/manual key only after its Pair action; it expires after five minutes and is never persisted or included in Bonjour advertisement data. The phone integration requires the user's sharing toggle and confirmation before pairing.
- Security uses the OS Network/Security TLS-PSK APIs and AES-GCM cipher suite following [Apple's peer-to-peer sample](https://developer.apple.com/documentation/network/building-a-custom-peer-to-peer-protocol). Actual macOS loopback sockets transmitted a test byte with matching keys and rejected a different random key. No application health data was used in that check.
- `TVRelayPairing` typechecked against the installed Network/Security SDK. Actual client, coordinator and listener sources typechecked on macOS with the actual relay helper module and a small display-payload stub. This does **not** typecheck the final iOS/tvOS SwiftUI application or exercise Bonjour on physical devices.
- Twenty-four standalone assertions passed against actual pairing, session/sequence/freshness, bounded-buffer and framing helpers using a stub display payload. Seven XCTest cases were added for full-package CI. One pending replacement plus one in-flight frame bounds stream memory; generation tokens isolate old send/receive callbacks; malformed/wrong-session messages and stale/end/disconnect paths clear the receiver.
- Added the shared `BonhommeTV` scheme and unsigned tvOS Release CI job. `PLATFORM=tvos` produces a separate local archive and checks the Apple TV bundle identifier, device family/platform, local-network declarations, compiled asset presence, privacy manifest, symbols and signing team. Nineteen archive-fixture tests now pass, including five tvOS cases. Scheme XML, shell syntax and changed Swift syntax checks pass locally.
- Standalone TV sessions and the phone URL/consent producer are implemented. Approved ivory/midnight icons are installed; TV has real transparent foreground/opaque background stacks and both Top Shelf formats. All 20 asset tests, 19 archive tests, 7 permission-localization tests and 8 contracts pass locally.
- Integration [CI 35470234784](https://github.com/LeBonhommePharma/NATURaL/actions/runs/35470234784) passed core XCTest/assets/Linux but exposed three SDK boundaries: Watch `DisclosureGroup`, a cipher-suite raw type difference, and an unconditional tvOS HealthKit import. Fixes must pass a subsequent exact-revision run.
- Real tvOS SDK compilation, layered icon/top-shelf compilation, AirPlay mirroring, HDMI output, Siri Remote/VoiceOver behavior, network interruption recovery, signed archive validation and App Store/TestFlight acceptance remain release gates. Synthetic archive fixtures and the loopback TLS check do not satisfy those gates.

## Other current verification

Current baseline: `main` at `3fa2c61`; Cursor’s work is already merged. Review branch: `codex/app-store-native-refinement-20260919`. Historical results below predate current source and do not prove this revision.

- LP confirmed Xcode is uninstalled. `xcodebuild -version` fails because the active developer directory is Command Line Tools; a full Swift package test also fails at asset compilation (`actool` requires Xcode). No Xcode/simulator downloads are being made.
- Source preflight including native Mac passes (`python3 scripts/validate-submission.py --include-macos`).
- Website language routing passes. Eight Python product contracts pass. Twelve archive-validator fixture tests passed before additional acknowledgment checks; the latest CI run is authoritative for the final count.
- Swift parser checks pass for changed source. This is syntax checking, not SDK typechecking or application execution.
- Shared HUD numerical smoke checks exercise the actual formatter source with minimal wire stubs: 37 assertions passed. Consent smoke checks compile the actual Foundation consent source; grant/revoke/regrant/reset/cancellation cases pass. Neither substitutes for the full app tests.
- Mac artwork export adds approximately 2.4 MB, reusing the approved bloom. No user files were deleted. Disk check showed 31 GiB available; available space can change.
- Useful unmerged Cursor commit `b07a56c` was inspected and its Watch/Vision changes applied as patches; shared HUD/contract changes are incorporated alongside the crash fixes. Already merged branches were not reapplied.
- First full remote run at `7ae2c93`: [CI 35469012431](https://github.com/LeBonhommePharma/NATURaL/actions/runs/35469012431). Native Mac Release build, iOS + embedded Watch Release build, Swift core tests, assets and Linux contracts passed. Hosted simulator test compilation failed because the test target minimum was iOS 17 while the app required iOS 18. The test targets were aligned in `51f9252`; [CI 35469339246](https://github.com/LeBonhommePharma/NATURaL/actions/runs/35469339246) passed all five jobs, including 14 hosted app tests and 9 UI tests with zero failures.
- Added 110 localized permission purpose strings across 11 languages (33 files); source validation and seven localization gate regressions pass. Actual localized system-sheet rendering remains unverified.
- Guided-session timing now uses a monotonic clock, pauses after long scheduling gaps, handles fractional/zero transitions and releases cancelled timers. Standalone exact-controller smoke: 32 assertions passed; new XCTest cases await the final CI run.
- Design reference rendered in the in-app browser at narrow/wide CSS viewports (355/1164px): no horizontal overflow or broken artwork observed; sample-state and pause controls verified. This remains a reference, not native app screenshots.
- Native layouts, HealthKit/CareKit behavior, physical-device coverage, final screenshots, distribution signing and App Store Connect remain unverified for this revision. No app was uploaded or submitted.

---

# Historical release preparation evidence — 12 September 2026

This record separates repository verification from App Store approval. No archive has been uploaded to Apple, and no App Review submission has been made.

## Environment and scope

- Repository: `/Users/lp.more/Projects/NATURaL`; preparation changes remain in the working tree.
- Host: macOS 27.0 (26A428); Xcode 27.0 (27A266a).
- iPhone Simulator: iPhone 16 Pro, iOS 18.5.
- iPad Simulator: iPad Pro 11-inch (M4), iOS 18.5.
- Default Swift-only package path; no opt-in C++ acceleration build was introduced.
- No paired Watch runtime or physical Apple device validation was completed. Watch SDK compilation does not establish sensor, background or haptic behavior.

## Completed checks

| Check | Result / evidence |
| --- | --- |
| Swift package | **548 tests passed** in latest local run; `swift test --package-path BonhommeCore --cache-path $TMP_CACHE --config-path $TMP_CONFIG --security-path $TMP_SECURITY --disable-sandbox` |
| Submission configuration | `python3 scripts/validate-submission.py` passed: icon format/resources, manifests, companion embedding, runtime paths, Live Activity entry, free access and local health storage |
| Website language routing | `node scripts/test-site-language.cjs` passed; OS preference order, regional codes, all supported languages, explicit selection, blocked storage, deep links and safe routes |
| App translation review | `NATURaL.xcodeproj/LANGUAGE_SUPPORT_STATUS.md` and code audit confirm `en`/`fr` content is complete and the remaining 9 locales remain at fallback for untranslated entries |
| Dependency notices | `Docs/AppStore/third-party-notices.md` added with concrete dependency graph and CareKit license reference |
| Initial iPhone Release UI journeys | Five passed after fixing the summary update loop; superseded by final results below |
| Initial iPad Release UI journeys | Five passed after replacing session links with explicit full-screen presentation; superseded by final results below |
| Background bug audit | iOS HealthKit and Watch session sources passed SDK typechecks; cancellation, timeout, stale callbacks, save cleanup, pause accounting and forward cue progression repaired |
| Whitespace/patch integrity | `git diff --check` passed |
| Localization regression suite | `swift test --package-path BonhommeCore --filter LocalizedStringTests` passed; `LocalizedString` and `LocalizedStringArray` cover all 11 declared codes |

## Final app validation

- iPhone Release: **19/19 passed**, comprising 10 app unit tests, three AirPlay UI tests and six workout UI journeys. Result: `~/Library/Developer/XcodeBuildMCP/workspaces/NATURaL-71262cbb7b88/result-bundles/test_sim_2026-09-12T21-11-48-738Z_pid823_dcce5cbb.xcresult`.
- Raw iPhone QA screenshots exported to `build/submission/screenshots/iphone/`. These are evidence captures; the final store screenshot selection remains a checklist item.
- Final iPad Release: **6/6 workout UI tests passed**, including active pose, pause/resume/end, summary dismissal and largest text, after the final lifecycle changes. Result bundle: `test_sim_2026-09-12T21-14-35-203Z_pid823_2cb3f692.xcresult` in the same result-bundles directory.
- Final targeted iPhone rerun: the runner reported **one executed test passed** (`testSessionCanPauseResumeAndEnd`) despite two requested selectors. Do not count the other selector as executed. Result: `test_sim_2026-09-12T21-16-46-162Z_pid823_a640f6c2.xcresult`. The active-pose journey passed on final iPad and the preceding full iPhone run.

A simulator success is not a substitute for distribution signing, Organizer validation or TestFlight. Unsigned simulator tests deliberately run without HealthKit entitlements; they validate usable guided sessions under unavailable Health access, not successful Health recording.

## Published website

- [NATURaL](https://thebonhomme.com/NATURaL/), [Privacy](https://thebonhomme.com/NATURaL/privacy/), [Support](https://thebonhomme.com/NATURaL/support/).
- Repository: `LeBonhommePharma/lebonhommepharma.github.io`.
- Published commit: `0b8f3e036d398cd32ccb015f19eed952b0133ffa`.
- [Successful GitHub Pages deployment](https://github.com/LeBonhommePharma/lebonhommepharma.github.io/actions/runs/34719000499).
- **36/36 public assets matched their prepared bytes**, including 33 pages. Receipt: `build/submission/website-verification.txt`.
- All 33 localized pages checked at 390px width: no horizontal overflow, correct language tags, 11-option selector and Arabic RTL.
- Browser visuals reviewed for desktop dark mode, phone light mode, Arabic RTL and French privacy. Internal support/privacy navigation and manual language selection verified.
- Shared parent-site tokens, typography and theme controls retained. Site design-system and palette guards (including negative checks) passed using installed GNU grep.
- Changes were published from `/private/tmp/natural-app-site-20260912`; the user's existing sibling website checkout was not modified.

## Scope of the crash repair

The macOS dialog corresponded to an **iOS Simulator Bonhomme process**, whose runtime loader could not locate bundled `libswiftCompatibilitySpan.dylib`. Adding inherited executable-relative Frameworks search paths repaired launch. A separate Live Activity extension crash was repaired by supplying its missing `@main` entry point. The app now launches and completes tested simulator journeys on this host. Native macOS/App Store iOS-on-Mac operation has not been validated.

## Outstanding release gates

See [TODO.md](TODO.md) for the complete iOS, iPadOS and watchOS checklist. Signing/provisioning, screenshot selection, accessibility declarations, physical-device coverage, TestFlight and App Store Connect metadata remain distinct gates. Privacy posture is on-device analysis with **Data Not Collected**; paste [app-store-connect.md](app-store-connect.md) into App Store Connect. The app selects OS languages automatically but untranslated app strings fall back to English; the website has 11 full language editions. Do not present those as identical translation coverage.

## Signed archive attempt

`BUILD_NUMBER=2 scripts/archive-app-store.sh` was attempted locally and failed with exit 65 before producing a usable archive. Xcode reported missing provisioning profiles for `com.natural.Bonhomme`, `com.natural.Bonhomme.watchkitapp`, `com.natural.Bonhomme.Widgets` and `com.natural.Bonhomme.LiveActivity`. Log: `build/submission/archive-attempt.log`. Provisioning updates were not enabled and nothing was uploaded. Set up profiles for team ZJLX84G8QV, then rerun with a fresh build number. A generic unsigned device build remains unverified locally; simulator builds and Watch SDK typechecks are the completed compilation evidence.

## Follow-up local checks

Configuration validation, website language regression tests and `git diff --check` passed again. The corresponding local-checks TODO is closed. A Swift package verification run was also completed with writable cache/config paths and produced **548 passing tests**. An unsigned device build was still attempted and exited 74 during package resolution because this environment still blocks CoreSimulator cache/service access during that path. Device compilation remains unverified here. Log: `build/submission/device-build.log`.
