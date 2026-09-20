# App Store submission TODO — NATURaL 1.0

Owner: LP / Le Bonhomme Pharma. Updated 19 September 2026.

This checklist covers **iOS/iPadOS with the embedded watchOS companion**, the existing **native macOS target** added by Cursor, and the **native tvOS app** explicitly requested by LP. AirPlay/HDMI second-screen output remains part of the iOS product. Vision UI/icon designs remain part of the family but do not establish a visionOS release. ClusterFuck readiness is tracked in `/Users/lp.more/Projects/ClusterFuck/docs/AppStore/TODO.md`.

Checked boxes record the scope of a completed check, not overall readiness. Cursor’s subsequent changes and the current fixes require new build, runtime and visual verification. **The apps are not yet proven ready to submit.**

Checklist legend:

- `[x]` **Local/Repository complete** (validated in this checkout)
- `[ ]` **Unfinished or unverified**, including local product work, CI, portal and physical-device checks

A reproduced failure documents a blocker; it does not satisfy its release gate.

## In-repo status — 19 September 2026

The repository-side work is complete and green. Every remaining `[ ]` in this
file needs something this checkout cannot provide: Apple credentials, physical
hardware, an App Store Connect session, a full Xcode install, or a qualified
human reviewer. None of them can be closed by editing source here.

**Green:** [CI 35480771304](https://github.com/LeBonhommePharma/NATURaL/actions/runs/35480771304)
at `c235664` passed all seven jobs — 613 core tests, 9 product contracts, all
submission-asset checks, four platform Release builds (iOS+watchOS, macOS, tvOS),
and both simulator journey lanes (**21 app tests and 10 UI tests, zero failures,
on each of iPhone 17 Pro Max and iPad Pro 13-inch M5, iOS 26.5**). Local gates:
archive validation 19, submission assets 20, permission localizations 7, cloud
signing 21, localization inventory 6, product contracts 9, website routing PASS,
`validate-submission.py --include-macos` PASS.

### Merge readiness for PR #39 — waiting on Apple vs waiting on us

76 unchecked / 79 checked as of 20 September 2026. The split LP will ask for:

**Waiting on nothing — we could finish these today (4).** None blocks the merge;
all are decisions, not work.
| Item | What it needs |
|---|---|
| ~~Unreferenced YouTube flow~~ **withdrawn** | Not a decision. All four files are `#if DEBUG` from line 2, so none ships. See §UI craft. |
| Pose-illustration accent ramp (§UI craft) | LP picks one of three recorded options. |
| Session-surface redundancies (§UI craft) | LP picks; each is a small change. |
| `BrandColor.gold` retirement | Authorized, then halted: `test_contracts.py:693` asserts `0xC4A359` exists, so it is a three-part change (contract, declaration, MASTER.md 33/41), not a delete. |

**Waiting on a human, not on Apple (3).**
Translations for nine languages (870 keys), linguistic review, and per-value
scientific provenance — the last needs original source records held outside this
repo. No Apple dependency; none blocks the merge.

**Waiting on Apple credentials + a full Xcode (≈20).**
Distribution signing, provisioning, Organizer validation and **Validate App**,
archive creation, upload, TestFlight. This Mac has Command Line Tools only.

**Waiting on physical hardware (≈25).**
Device QA across iPhone, iPad, paired Watch, Apple TV and Mac: permissions
matrices, Health denied/revoked, haptics, Digital Crown, Siri Remote focus,
AirPlay/HDMI, pairing expiry, backup exclusion on real files.

**Waiting on App Store Connect — but the content is now drafted (≈14).**
These were filed as blocked. Most were not waiting on Apple at all; they were
waiting on someone to write the answers, which needs no certificate and no
device. Drafted 20 September 2026:

| Field | Drafted in | Derived from code? |
|---|---|---|
| App Privacy questionnaire | [privacy-labels-derivation.md](privacy-labels-derivation.md) | Yes — every answer cites file and line |
| Age rating questionnaire | [review-answers-derivation.md](review-answers-derivation.md) | Yes, with where it is conservative |
| Export compliance | [review-answers-derivation.md](review-answers-derivation.md) | Yes — cipher suite and TLS pinning cited |
| Name, subtitle, promo, description, keywords | [metadata.md](metadata.md) | Pre-existing, EN + FR-CA |
| What's New (1.0) | [metadata.md](metadata.md) | New, EN + FR-CA |
| Screenshot plan per platform | [screenshot-plan.md](screenshot-plan.md) | New — screens, states, dimensions, capture path |

What genuinely remains on Apple: creating the record, pasting these in, pricing
and territory selection, and submission. **Eleven questions across those files are
left unanswered** and listed under "Open — needs LP" — a backend that this repo
cannot see, App Group scope, the stray `aps-environment` entitlement, clinical
retention intent, whether Prescriptions ships enabled in 1.0, iPad/Mac listing
scope, and localized screenshot scope. Each is an em dash, not a guess.

**Waiting on a final signed build (≈8).**
Every store screenshot slot. Downstream of signing, so not independently
actionable.

**Out of scope for this release.** visionOS layered icon delivery — there is no
visionOS scheme or CI job, and MASTER.md tracks Vision's distribution readiness
separately.

**Merge read:** nothing in the repo blocks merging. Required checks pass on the
current revision, which is the stated precondition on the merge line below.
Everything else is external, and merging does not make any of it worse —
submission remains gated regardless. The four "waiting on nothing" rows are LP
decisions that can land before or after the merge.

**Remaining gates, by what actually unblocks them:**

| Gate | Blocked on | Items |
| --- | --- | --- |
| Distribution signing, Organizer validation, upload, TestFlight | Real Apple credentials + a full Xcode install | §0, §1, §8, tvOS archive |
| Physical-device QA (iPhone, iPad, Watch, Apple TV, Mac) | Hardware | §4–§7, TV pairing/transport, pose safety |
| App Store Connect record, metadata, privacy labels, age rating, pricing, export compliance | An App Store Connect session | §0, §2, §3 |
| Final store screenshots at accepted dimensions | A final signed build on device/simulator | All platform screenshot items |
| tvOS layered icon + Top Shelf **structure** | **Nothing — already validated automatically.** CI's Xcode 26.6 runs `actool --app-icon AppIcon --notices --warnings` against the real catalogue on every push, with zero diagnostics | — |
| tvOS icon focus/parallax behaviour, and assets inside a signed bundle | Apple TV hardware + Organizer | TV § |
| visionOS layered icon delivery | A visionOS build; there is **no** visionOS CI job today, so nothing validates it | Kinematics § |
| In-app translation for nine languages | A qualified human translator per language | §2, localization § |
| Per-value scientific provenance | Original experimental/source records held outside this repo | §3, claims § |

Two things are explicitly **not** closed despite green CI, and are written up
where they belong rather than ticked:

1. ~~The iPad landscape screenshots are not valid visual evidence.~~ **Resolved.**
   A controlled comparison in CI 35481919944 showed `app.screenshot()` clips 25%
   while `XCUIScreen.main.screenshot()` is faithful; the landscape layout renders
   correctly and the app is not letterboxed. Landscape store assets must use the
   display path rotated +90.
2. In-app translations were deliberately not machine-generated. The gap is
   measured exactly (870 unique keys) in
   [localization-coverage.md](localization-coverage.md); filling it with
   unreviewed output would lower the fallback counters without any qualified
   speaker having read medication, dosage or consent copy.

`[ ]` items are unresolved blockers that still require additional work or external/portal actions.

## Submission matrix (current source; device gates pending)

- **iPhone / iOS**
  - [x] Swift-only code checks, localized site routing checks, and release simulation regression gates pass.
  - [x] App icon resources, Info/entitlement wiring, Live Activity entry point, Watch embedding, and free-access checks pass offline.
  - [ ] Create and validate a signed archive in Organizer on team `ZJLX84G8QV`.
  - [ ] Install from TestFlight on physical iPhone and complete permission/backward/permission-revoke behavior matrix.
  - [ ] Capture App Store iPhone screenshots and finalize all App Store Connect privacy/age-rating/review fields.
- **iPad / iPadOS**
  - [x] Responsive iPad session layout and larger-text journeys passed the historical 12 September run.
  - [x] Re-run the current revision on iPad, including landscape guide and controls: the iPad Pro 13-inch (M5) / iOS 26.5 lane passed in [CI 35480771304](https://github.com/LeBonhommePharma/NATURaL/actions/runs/35480771304) (**21 app tests, 10 UI tests, 0 failures, none skipped**). Native screenshots are retained as the `native-screenshots-iPad` artifact. The landscape capture path is **settled**: `app.screenshot()` clipped 25% and dropped the whole metrics rail, `XCUIScreen.main.screenshot()` rotated +90 is faithful, and the landscape layout is confirmed correct and **not** letterboxed. See [verification.md](verification.md).
  - [ ] Validate portrait/landscape, split-view/resizable windows, and hardware permissions on physical iPad.
  - [ ] Capture final iPad screenshots at currently accepted App Store families.
- **watchOS**
  - [x] Companion embedding, startup retries, save-failure visibility, and lifecycle cancellation safety are in place.
  - [ ] Validate first-launch, pairing, haptics, interruptions, and Health-denied behavior on paired physical Watch.
  - [ ] Capture final Watch screenshots from approved test build and confirm installation path with app archive.
- **Apple TV / tvOS**
  - [x] Add a shared `BonhommeTV` scheme, unsigned Release CI job, and `PLATFORM=tvos` archive/inspection path.
  - [x] Implement explicit ephemeral QR/manual pairing, standard TLS-PSK transport, bounded sends, generation filtering and stale/end clearing.
  - [x] Pass tvOS SDK and layered-icon compilation at `c216e66` / CI `35470772237`; rerun after subsequent source changes.
  - [ ] Register/sign `com.natural.BonhommeTV` on team `ZJLX84G8QV`, configure its App Store Connect platform/listing, and validate a signed Apple TV archive.
  - [ ] Verify actual paired iPhone/iPad → Apple TV sessions, interruptions, screen privacy, Siri Remote focus and VoiceOver on hardware.
  - [ ] Capture actual Apple TV screenshots and complete the tvOS review/TestFlight gates below.

**Current environment:** Xcode is uninstalled (confirmed by LP). Command Line Tools cannot compile asset catalogs or run Apple-platform tests. Keep this Mac lightweight; run builds on the existing GitHub macOS runners. Local source/contract/archive-fixture checks pass, but do not prove a device build. Distribution signing and App Store Connect completion remain open.

## Current review and integration — 19 September 2026

- [x] Inspect current `main` and Cursor history; preserve the shared design tokens, native Mac target, unknown-value and Reduce Motion improvements.
- [x] Incorporate useful unmerged Cursor `b07a56c` Watch/Vision unknown-progress changes and shared HUD guards; avoid duplicate cherry-picks of already merged work.
- [x] Repair extension destination (`PlugIns`) and native Mac icon/privacy resource wiring.
- [x] Harden HUD numeric formatting and small-width layout; add targeted regression coverage.
- [x] Guard clinical consent across asynchronous reads/writes and remove unsupported receptor-binding claims from insight copy.
- [x] Bundle exact linked dependency notices and expose them in iPhone/iPad About.
- [x] Fix dose-label overflow in schedule/profile formatting and retain small fractional doses instead of rounding them to zero.
- [x] Wire hosted medication persistence and dose-format tests into the Xcode test target.
- [x] Execute the failed-save, retry and dose-format tests: `51f9252` / CI `35469339246`, 14 hosted app tests and 9 UI tests passed. Re-run after integration changes.
- [x] Review, commit and push the integration branch (`057b5aa` contains TV/kinematics/icon work).
- [ ] Merge only after current-revision required checks pass and remaining review findings are resolved.
- [x] Add 110 permission purpose strings across 11 supported languages and regression checks.
- [ ] Complete missing app-content translations; OS language selection falls back to English where content is untranslated. **Gap now measured exactly: 870 unique English keys** (381 needing all nine gap languages, 489 needing it/pt only; ~9,570 translated values), broken down by source area in [localization-coverage.md](localization-coverage.md). Machine translation was evaluated and rejected — it would lower the fallback counters without any qualified speaker reading medication, dosage and consent copy. Open pending human translation.
- [x] Execute iOS/Watch/Mac/TV Release builds and app tests at `c216e66`: all six jobs passed in CI `35470772237`, including 21 hosted app tests and 9 UI tests. Later changes require a fresh green run.
- [x] Add manual hosted signing with isolated credentials and distribution-profile checks; see [cloud-signing.md](cloud-signing.md).
- [ ] Configure the protected signing environment and run actual signed archives; offline fixtures do not establish working signing.
- [x] Add exact-key supplemental translations for common navigation/guide/TV phrases and a reproducible fallback inventory.
- [ ] Complete linguistic review and remaining untranslated static, interpolated and native SwiftUI copy; see [localization-coverage.md](localization-coverage.md). No box here may be checked on machine-drafted output.
- [ ] Review final native rendering across sizes, accessibility and every supported language. HTML/design references are not runtime proof.
- [ ] Validate TV/Vision layered icon delivery with their SDKs; flattened source assets are not enough to certify those store products.
- [x] Audit reachable profile/insight claims, distinguish catalog estimates from actual docking, and prevent repeated doses inflating the substance denominator; see [scientific-claims-audit.md](scientific-claims-audit.md).
- [ ] Complete per-value experimental profile provenance and validation; wording repairs alone do not validate scientific claims.

## TV display and native tvOS release

- [x] Implement standalone free TV sessions with the shared session controller, illustrated guide, pinned remote controls, pause/transition and completion. No phone or Health data is required.
- [x] Wire the iPhone/iPad sharing toggle, QR invitation confirmation, latest-state producer and scene/finish clearing. External-display output uses the same payload as native TV.
- [x] Export actual two-layer tvOS icons and standard/wide Top Shelf assets; retain original source artwork and validate dimensions/alpha/safe margins. SDK acceptance remains a separate gate below.

- [x] Discovery lists receivers without connecting to the first Bonjour result. Pairing requires a selected television and its ephemeral 256-bit credential; no plaintext socket fallback remains.
- [x] Use Apple's Network/Security TLS-PSK APIs. Matching-key loopback transfer succeeds and a different key is rejected; this verifies the transport helper on macOS, not the full tvOS app.
- [x] Bound output to one in-flight frame plus one latest replacement. Filter obsolete callbacks, reject wrong sessions/sequences, and clear display state on end/disconnect/staleness.
- [x] Add 7 relay regression tests and tvOS archive fixtures; see [verification.md](verification.md) for evidence limits.
- [ ] Exercise the phone's explicit sharing toggle and scanned-link confirmation. Declining, canceling and stopping must leave every display clear; no pose/health data may be transmitted before confirmation.
- [ ] Verify pairing expiry, wrong/manual keys, local-network permission denial, two phones, Wi-Fi loss/rejoin, application backgrounding, TV sleep, blocked sends and renewed pairing on real devices.
- [ ] Verify Control Center **Screen Mirroring** and HDMI external scenes separately. `AVRoutePickerView` selects supported media routes; it does not by itself establish whole-screen mirroring.
- [ ] Inspect focus/parallax on Apple TV and confirm the signed bundle's assets in Organizer. **The `actool` half is done:** the tvOS job compiles `BonhommeTV/Assets.xcassets` with `--app-icon AppIcon --notices --warnings` on the appletvos SDK with zero actool diagnostics, over two real two-layer imagestacks and both Top Shelf sizes (1920×720 / 2320×720 and their @2x); `test_submission_assets.py` asserts the same structure offline. See [verification.md](verification.md). Hardware focus/parallax and Organizer remain. [Apple asset guidance](https://developer.apple.com/documentation/xcode/configuring-your-app-icon), [brand asset format](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_ref-Asset_Catalog_Format/BrandAssetsType.html).
- [ ] Capture real tvOS pairing, active, paused and transition screens at accepted Apple TV dimensions, **1920×1080 or 3840×2160**, without alpha; never expose a live pairing secret in store screenshots. [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).
- [x] Prepare EN/FR tvOS metadata distinguishing standalone sessions from optional phone pairing.
- [ ] Review the final tvOS listing, privacy and export-compliance answers against the signed native transport and runtime behavior.
- [ ] Run `PLATFORM=tvos BUILD_NUMBER=<fresh-number> scripts/archive-app-store.sh` on the signing machine, complete Organizer validation, upload/process the build, test through TestFlight and obtain LP's release approval.

## UI/UX craft pass — 20 September 2026

Run against `design-system/natural/MASTER.md` (the `ui-ux-pro-max` persist from
17 September) and that skill's native pre-delivery checklist. MASTER.md was
**not** regenerated: `--persist` skips an existing file, and `--force` would have
discarded LP's recorded brand override. Palette v2 stays canonical — the audit
confirmed the generic wellness tokens (`--teal`, `--gold`, `--terra`, `--coral`,
`--cyan`, yellow, salmon) appear nowhere in the app, and a contract now keeps
them out of MASTER.md. The approved bloom was not touched.

- [x] Audit small text on the session surface for WCAG AA. Computed composites
      against `#08091A`: brand fg 15.60:1 and muted 6.12:1 (matching MASTER.md's
      published figures), MotionCoach cue 15.42:1, MotionCoach step 20.57:1,
      breathing label 11.09:1 — but the breathing **rate readout was 3.75:1**
      (white at 0.40 compositing to `#6B6B76`) at 10pt, where the 3:1 large-text
      allowance does not apply. Fixed to `BrandColor.fg` / `fgMuted` and guarded
      by `test_brand_tokens_and_design_system`, verified non-tautological.
- [x] ~~Unreferenced YouTube flow.~~ **Finding withdrawn — it was wrong.** I
      reported this as dead code shipping in the App Store build. It is not
      shipped at all: `YouTubePlayerView.swift`, `YouTubeWorkoutScreen.swift`,
      `YouTubeProgramPickerView.swift` and `YouTubeWorkoutViewModel.swift` each
      open with `#if DEBUG` (or `#if DEBUG && canImport(UIKit)`) on line 2, so the
      whole feature — including the `WKWebView` that loads `youtube.com` — is
      compiled out of Release. `app-store-connect.md` already said this correctly
      and I contradicted it. The 16 raw-system-colour uses I flagged are in
      Debug-only development surface, which is the right place for them. No action.
- [ ] **Decide the pose-illustration accent ramp with LP.** `Pose.accentHue`
      still drives the MotionCoach illustration gradients from the same free HSB
      generator, and its own source comments name the results: `spine` cyan-blue,
      `shoulders` teal, `neck` cyan, `breathing` green, `core` orange, `back`
      cyan (`#55F2F2` pure cyan, `#58F255` pure green). That is off-palette by
      MASTER.md's quantity-bound rule. It is **not** changed here: the illustrated
      pose stage is the app's signature visual, and restyling it is LP's call, not
      a lint fix. Three options — give categories a brand-sanctioned sub-palette;
      drop per-category colour and differentiate by form alone; or constrain the
      ramp to the brand's blue→violet→magenta arc. Reassigning existing tokens
      (mint/violet/aqua/tangerine) is **not** an option: MASTER.md binds them by
      quantity and forbids reassignment.
- [x] **Consumed the generated dark-appearance colorsets** (applied 20 September 2026). All ten `BrandColors.xcassets` colorsets currently
      hold a single universal value with no `appearances` entry, so nothing
      adapts. LP ruled on 20 September that the twins should exist and MASTER.md
      stands as written. They are being generated from the canonical palette via
      the site's OKLCH relation — hue within 3°, lightness differs, chroma free to
      fall and up to +0.05 — each pair contrast-verified against `#F3EFE7` and
      `#08091A`. **Do not author twins here**; consume that output. On arrival:
      revisit light-surface brand usage (home style chrome currently uses
      `.primary` as a stopgap) and add a contract asserting every colorset has a
      dark twin.
- [ ] **Session-surface redundancies — LP's taste call, evidence attached.**
      Read from the exported paused-session frame in
      [CI 35490123182](https://github.com/LeBonhommePharma/NATURaL/actions/runs/35490123182),
      not from code review, and confirmed persistent in source rather than
      transient:
      1. The breathing cue renders **twice** — once as the stage overlay in
         `MotionCoachView` (gated on `phase == .active`, so persistent for the
         whole pose) and again below the countdown in the scroll flow. Identical
         text, ~80pt of vertical space, on the app's most-used screen.
      2. **"Paused" appears twice** — the chip on the stage and the chip in the
         HUD bar, simultaneously.
      3. The HUD shows heart rate as an em dash while a gold "85 BPM" chip sits
         beside it. If that chip is the music/grounding tempo rather than heart
         rate, the shared "BPM" unit reads as a contradiction and wants
         distinguishing.
      Deliberately **not** changed here. The earlier fixes in this pass were
      compliance defects with a right answer — off-palette generated chrome and a
      3.75:1 contrast failure. Which of two valid cue placements to keep is taste,
      on the signature surface, under contract, on a green branch. That is LP's.
- [ ] Re-review hierarchy, spacing, motion and states on device once hardware QA
      is possible. Spacing already resolves to a clean 4/8/12/16/24/32/40/48 scale
      and `phoneControlHeight` is 52pt (above the 44pt minimum); motion is already
      Reduce-Motion gated and contract-enforced. What remains needs eyes on glass.

## 0. External release blockers (must be completed before upload)

- [ ] In Xcode / App Store Connect, complete Team membership usability, all bundle identifiers, App Group, entitlements mapping and distribution signing for `com.natural.Bonhomme` plus extensions.
- [ ] Create/confirm App Store Connect app record, metadata, age rating, category, keywords, pricing model, URLs, and release settings.
- [ ] Run Organizer validation and upload a signed archive; install TestFlight builds on iPhone, iPad and paired Watch for device verification.
- [ ] Complete final App Review artifacts: privacy labels, accessibility declarations, screenshots, reviewer notes, and submission details.

## Kinematics and approved identity

- [x] Preserve the approved bloom, with warm ivory light and website midnight-indigo dark exports; iOS uses the system dark-icon appearance.
- [x] Provide illustrated pose guides and persistent numbered steps, breathing, adaptations and catalog cautions across phone, tablet, Watch, Mac and TV.
- [x] Keep pause state authoritative, stop hidden/background animation and honor Reduced Motion. Pausing leaves instructions visible.
- [x] Share one guided-session model between Vision window and immersion; remove the fabricated static SCI ring.
- [x] Make iOS AR optional with camera consent, tracking feedback and fallback to the complete 2D guide.
- [ ] Inspect every pose in 2D and spatial rendering on target hardware, including comfortable movement direction and timing. Source geometry checks do not certify exercise safety or anatomical correctness.
- [ ] Verify guide scrolling, pinned controls, VoiceOver, large text, RTL languages, TV focus and reduced motion in final native builds.
- [ ] Finish valid visionOS layered icon delivery and its SDK validation before a separate Vision release.

## 1. Identity, membership and signing

- [x] Owner confirmed Apple Developer Team **ZJLX84G8QV**, account **lp@thebonhomme.com**.
- [x] Configure the main app as `com.natural.Bonhomme`.
- [x] Configure and embed Watch companion `com.natural.Bonhomme.watchkitapp` with the correct companion identifier and Boolean `WKApplication`.
- [x] Retain extension identifiers `com.natural.Bonhomme.Widgets` and `com.natural.Bonhomme.LiveActivity`.
- [ ] In Xcode → Settings → Accounts, confirm the renewed membership and the selected team are usable. An existing development certificate labeled `lmorency@me.com` does not by itself establish distribution readiness.
- [ ] Register/verify every bundle identifier and App Group `group.com.natural.Bonhomme` under that team.
- [ ] Verify HealthKit, clinical records if retained, background delivery, App Groups, Siri and all other shipped entitlements on the corresponding profiles. CloudKit and iCloud KVS are not shipped.
- [ ] Provision distribution signing for the app, Watch and extensions; verify the archive uses the intended team.
- [ ] Confirm the SDK/Xcode version is accepted for production uploads. This Mac currently has only Command Line Tools. Verify the selected CI/release-machine Xcode and SDK against Apple’s current requirements.

## 2. Product and metadata

- [x] Remove all NATURaL access-restriction screens and keep sessions immediately accessible.
- [x] Add first-use guidance, optional Health entry, local history, save-error feedback and branded artwork.
- [x] Prepare English and French Canadian listing copy in [metadata.md](metadata.md).
- [x] Provide website routes under `https://thebonhomme.com/NATURaL/`, with privacy and support pages and 11 supported website languages.
- [x] Match the OS language preference list, normalize regional language codes and fall back safely when a translation is unavailable.
- [x] Verify website localization and RTL behavior for all 11 supported languages using `node scripts/test-site-language.cjs`.
- [x] Review app translation coverage in all 11 declared languages; English fallback is still used for strings without translations. Test Arabic layout and regional formats on devices.
- [ ] Create or confirm the App Store Connect record with the exact bundle ID. Check availability of display name **NATURaL**; choose an internal SKU and primary language.
- [x] Keep all plans freely accessible in the app.
- [ ] Confirm **Free** pricing in App Store Connect; no account-side change is inferred from source code.
- [ ] Complete business/trader status and territory-specific account requirements shown by App Store Connect; verify public contact information.
- [ ] Enter category, subtitle, keywords, copyright, territories and release method. Review localized copy for the actual shipping feature set.
- [ ] Set Marketing URL to `https://thebonhomme.com/NATURaL/`, Support URL to `https://thebonhomme.com/NATURaL/support/`, and Privacy Policy URL to `https://thebonhomme.com/NATURaL/privacy/`.
- [ ] Complete age-rating questions based on the medication/substance content actually reachable in the app.
- [ ] Complete export-compliance questions consistently with the shipped binary; check the existing exempt-encryption declaration.
- [ ] Decide whether to offer the iPad app on Apple-silicon Macs in App Store Connect. The repaired macOS dialog came from an **iOS Simulator process**; native Mac operation has not been validated.

## 3. Privacy, permissions and claims

- [x] Bundle required-reason API manifests for the app, Watch, widgets, Live Activity and shared Swift package. Manifests declare no tracking and no collected data types.
- [x] Keep health-related SwiftData on-device, remove CloudKit/iCloud entitlements, and do not publish cloud session presence.
- [x] Configure backup exclusion and data protection on local app health-storage directories.
- [x] Link privacy/support information from the app; explain optional permissions and experimental indicators.
- [x] Audit source data flows and prepare the policy revision; see [privacy-dataflow-review.md](privacy-dataflow-review.md).
- [ ] Verify the public policy and translations against the actual final signed binary and enabled integrations; publish reviewed revisions.
- [x] Complete App Privacy labels from the actual data flows and dependencies. Required-reason API manifests are **not** an answer to the data-collection questionnaire. Draft: [app-store-connect.md](app-store-connect.md) — **Data Not Collected**. Enter the same answers in App Store Connect.
- [ ] Verify backup exclusion and file protection on a real device, including SQLite/WAL files, CareKit, recovery snapshots and App Group state.
- [x] Resolve retention/deletion and migration for records that earlier development builds may have synchronized to CloudKit. This release no longer uses or accesses that container and does not delete leftover remote records; users can remove them from iCloud settings.
- [x] Review medication, SCI and generated insight text across every shipped **source** surface. Swept all platform targets for diagnosis/treatment/physiological/binding language; removed one unqualified pose claim (“This improves circulation.”, nine languages) and locked the result with the new `test_claim_honesty` contract (9th). Reasoning and deliberate non-changes in [scientific-claims-audit.md](scientific-claims-audit.md). **Source-level only — on-device rendering and translated copy remain unverified below.**
- [ ] Test Health denied, partial, revoked and unavailable states, plus clinical medication consent grant/revoke. Guided iPhone/iPad sessions must remain usable without granting Health access.
- [x] Review third-party licenses and required notices for the actual dependency graph, including CareKit. Dependency notice artifact added at `Docs/AppStore/third-party-notices.md`.

## 4. iPhone / iOS

- [x] Fix the Swift runtime search path that caused the reported simulator launch crash.
- [x] Fix the Live Activity extension's missing entry point.
- [x] Fix the eager workout-service initialization loop observed at session end.
- [x] Add pause/resume/end controls and a persistent Done action on the summary.
- [x] Verify the initial five release journeys on iPhone Simulator, including largest accessibility text. Later changes require the final run recorded in [verification.md](verification.md).
- [x] Complete final Release simulator regression runs; see exact executed scope in verification.md.
- [ ] Test on a physical iPhone: cold launch, full session completion, pause/resume, early end, background/foreground, crash recovery, offline use and failed local saves.
- [ ] Declare accessibility support per platform in App Store Connect only after verifying each selected feature.
- [ ] Verify VoiceOver order, button labels, Reduce Motion, contrast, rotation, safe areas and large text in active sessions and all settings/history screens.
- [ ] Verify Health recording, Live Activities, lock screen/Dynamic Island and widgets on supported hardware/OS versions.
- [ ] Capture final App Store screenshots at currently accepted iPhone dimensions. Keep raw simulator/device screenshots separate from compressed QA previews.

## 5. iPad / iPadOS

- [x] Provide sidebar/catalog layout and scrolling session content.
- [x] Verify the final session presentation fix: all six iPad UI regression tests passed.
- [ ] Test portrait and landscape, split view, resizable windows, keyboard navigation and largest text, including session controls and summary dismissal.
- [ ] Verify no blank detail panel, duplicate navigation stack, truncated instruction or inaccessible primary action. **Partially covered:** blank detail panel and inaccessible primary action are closed by the green iPad lane (detail `home.content` holds `home.start`, asserted hittable and tapped; session controls and `summary.done` hittable in landscape). **Still open:** the iPad home tree reports three `NavigationBar` elements with two overlapping at y=138 — normal split-view structure or a duplicate stack is undetermined without device/Xcode inspection — and nothing asserts text truncation. See [verification.md](verification.md).
- [ ] Run a full session and local-history round trip on a physical iPad, with and without Health access.
- [ ] Capture accepted iPad App Store screenshots from the final build. Do not stretch iPhone captures to fit.

## 6. Apple Watch / watchOS

- [x] Install the approved Watch icon and branded plan browser.
- [x] Include Watch as an embedded dependency of the iOS archive.
- [x] Add startup retry, visible save failures and cleanup paths; all sessions are accessible.
- [x] Complete the background lifecycle audit: cancellation-safe startup, failed-save cleanup, stale callback filtering, correct paused timing and Watch cue progression. SDK typechecks passed; final build evidence is recorded separately.
- [ ] Test on a paired physical Watch: first launch and permission choices, phone reachable/unreachable, heart-rate delivery, pause/resume, early end, full completion, failed recording/save and app interruption.
- [ ] Verify haptics, Digital Crown behavior, foreground/background transitions and cancellation leave no orphaned workout.
- [ ] Check the smallest supported watch display, larger displays, accessibility text sizes and VoiceOver.
- [ ] Verify companion install/update and decide how to handle development data under the old `com.natural.BonhommeWatch` identifier.
- [ ] Supply current accepted Watch screenshots and confirm the companion appears correctly in the archive and store listing.

## 7. Native macOS

- [x] Reuse Cursor’s native `BonhommeMac` target (`com.natural.Bonhomme.mac`, macOS 14+).
- [x] Bundle approved bloom icon at native Mac sizes, privacy manifest, sandbox entitlement and export declaration.
- [x] Refine plan selection, pose guidance, scrollable window, keyboard controls, early-end summary and privacy/support entry points.
- [x] Show only supported session information; native Mac has no live Health feed or workout recording.
- [x] Pass native macOS Release compilation at `c216e66` / CI `35470772237`.
- [ ] Test actual launch, window resize/close, keyboard navigation, VoiceOver and complete session flow on Mac.
- [ ] Verify timer behavior through app suspension/sleep; ensure outcome and elapsed time remain coherent.
- [ ] Verify distribution identity, Mac App Store archive, signing, sandbox, notarization/validation as required by the selected distribution path, screenshots and metadata describing actual Mac capabilities.
- [ ] Confirm Mac App Store record strategy for the separate bundle identifier; do not assume it can share the iOS record automatically.

## 8. Archive, TestFlight and review

- [x] Add deterministic submission-configuration checks, Swift tests, simulator regression CI and unsigned device-build CI.
- [x] Run local configuration, language, Swift and simulator checks and record exact results in [verification.md](verification.md):

  ```sh
  python3 scripts/validate-submission.py
  node scripts/test-site-language.cjs
  swift test --package-path BonhommeCore
  xcodebuild test -project NATURaL.xcodeproj -scheme Bonhomme \
    -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
  ```

- [x] Attempted a new build number and archive invocation:

  ```sh
  BUILD_NUMBER=2 scripts/archive-app-store.sh
  ```

  Failure was deterministic: unsigned/provisioning requirements are missing for several bundle IDs (log in `build/submission/archive-attempt.log`). Re-run with a fresh build number after provisioning is fixed.

- [ ] In Organizer, inspect the app, Watch and extensions, entitlements, privacy report, icons, version/build numbers, architectures and symbols. Run **Validate App**.
- [ ] Upload the validated archive to App Store Connect when authorized; resolve processing and compliance messages.
- [ ] Install through TestFlight on iPhone, iPad and a paired Watch and complete the hardware checks above.
- [ ] Add review contact details and notes explaining free access, optional Health/Watch, medication consent and experimental metrics. No demo login is needed.
- [ ] Select the processed build, complete every required App Store field, and submit for review when LP approves the final release.
- [ ] After approval, verify the public listing, download/install path, website links and actual production behavior.

No build has been uploaded or submitted to App Review by this task.

## Apple references

Checked 12 September 2026. Recheck immediately before upload because accepted SDKs and screenshot slots can change.

- [Submission and platform requirements](https://developer.apple.com/app-store/submitting/)
- [Upload screenshots and app previews](https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
