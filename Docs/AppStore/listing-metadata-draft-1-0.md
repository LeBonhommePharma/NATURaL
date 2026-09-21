# 1.0 listing metadata — DRAFT, derived 21 September 2026

**All copy below is a draft. LP approves every word before it goes near App Store
Connect.** Nothing here has been published or entered into ASC.

Derived from the code **after** the clinical-records cut
([clinical-records-cut-from-1-0.md](clinical-records-cut-from-1-0.md)). Where a
claim is derived from source it says so; where it is an assumption it says that
instead.

## Privacy nutrition label — proposed answer: **Data Not Collected**

Apple's definition of *collect* is transmitting data off the device such that the
developer or a partner can access it. **Verified from source, not from the
privacy manifest** (a manifest is a claim; the code is the fact):

| Vector | Finding | Evidence |
|---|---|---|
| HTTP / `URLSession` / `URLRequest` | **none in shipping code** | repo-wide grep |
| CloudKit / `CKRecord` / iCloud | **none**; `cloudKitDatabase: .none` | `PersistentModels.swift:517,564` |
| Analytics / attribution / crash SDKs | **none** | searched Firebase, Amplitude, Mixpanel, Segment, Sentry, Crashlytics, AppsFlyer, Adjust, AdMob, Google Analytics |
| SharePlay | pose index + timestamps only, **no health data** | `ChairYogaActivity.swift` `WorkoutSyncMessage` |
| ShareLink | a rendered image | `SummaryView.swift:322` |
| TV relay | carries HR/HRV **but LAN-only, TLS-PSK, to the user's own Apple TV** | `TVDisplayPayload.swift`, `TVRelayPairing.swift` |
| WatchConnectivity | user's own paired devices | `WCSession` |

**There is no developer-operated server.** Health data reaches the user's own TV
and watch and nowhere else.

Proposed answers: **Data Not Collected**; tracking **No**
(`NSPrivacyTracking = false`, no ATT, no IDFA, no `AppTrackingTransparency`
import); no data linked to identity, because nothing is transmitted.

> **Assumption, flagged rather than buried:** this treats LAN transmission to the
> user's own Apple TV as not-collection. That is the standard reading, and there
> is no developer access to the data, but it is a judgement and LP should know it
> was made.

## Age rating

Reuses `review-answers-derivation.md`, with the reused claims re-checked:

- **Medical/Treatment Information — Yes, infrequent/mild.** Still correct, and the
  reason is now narrower: clinical records are gated, but medication *schedules*
  and the pharmacology reference catalogue remain reachable.
- **Alcohol, Tobacco, or Drug Use or References — Yes, infrequent/mild.** The
  substance catalogue names controlled substances and describes mechanisms.
- **Unrestricted Web Access — No.** Re-verified on `main`: the only `WKWebView` is
  behind `#if DEBUG && canImport(UIKit)` at
  `Bonhomme/Features/Workout/YouTubePlayerView.swift:2`.
- Gambling, UGC, Horror, Violence, Sexual Content, Profanity, Mature Themes — **No**.

## Description — DRAFT

> **A chair. A breath. A moment to move.**
>
> NATURaL is gentle chair yoga you can start from wherever you are — no account,
> no subscription, no Apple Watch required. Every session is available from the
> first launch.
>
> Twenty-six seated poses across a range of anatomical focuses, each with plain
> instructions, suggested modifications, and the option to pause at any point
> without losing your place. Sessions run from a few minutes upward.
>
> If you wear an Apple Watch, NATURaL can read your heart rate variability during
> a session and adapt what it shows you. That is optional, and the app works
> fully without it.
>
> **Your data stays on your device.** NATURaL has no account system and no
> server. Analysis runs locally. Nothing is uploaded, and nothing is sold.
>
> Available in English and French.

*Note: the final sentence depends on PR #40 (locale narrowing to en/fr), which is
unmerged. On `main` the build still declares eleven languages. If #40 does not
land, that line must change or the listing overstates coverage.*

## Keywords — DRAFT (100-character field, distinct terms, not a sentence)

```
chair yoga,seated,gentle,mobility,HRV,breathing,stretch,accessible,desk,senior,calm,posture
```
91 characters. Deliberately excludes "NATURaL" (the app name is already indexed)
and any clinical claim.

## Promotional text — DRAFT

> Every session unlocked from day one. No account, no subscription, and your data
> never leaves your device.

## What's New (1.0) — DRAFT

> First release.

## Privacy policy and support URL — NOT YET WRITTEN

Both are **mandatory**, and both are blockers. Neither is drafted here, because
the privacy policy must be derived from the data audit above rather than from a
template, and it should be written once the nutrition-label assumption is
confirmed. Intended home: `thebonhomme.com`.

## What is NOT claimed

No therapeutic, diagnostic or drug-binding claim appears in any copy above —
consistent with `scientific-claims-audit.md` and with the in-app disclaimer
("NATURaL is a wellness app; its entropy indicators do not diagnose conditions or
measure drug binding").
