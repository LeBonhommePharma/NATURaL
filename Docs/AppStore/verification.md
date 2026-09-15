# Release preparation evidence — 12 September 2026

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
