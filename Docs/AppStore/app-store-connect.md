# App Store Connect — proposed submission answers

Source review: 19 September 2026. These are prepared answers for the current iOS/iPadOS app and embedded Watch companion, not a receipt of completed portal entry. Match them to the final signed archive. Native macOS requires separate target and runtime review.

## Identity

| Field | Prepared value |
| --- | --- |
| Name | NATURaL: Chair Yoga; availability not verified |
| Bundle ID | com.natural.Bonhomme |
| Team | ZJLX84G8QV |
| SKU | natural-chair-yoga-1; confirm unused when creating record |
| Primary language | English (U.S.) |
| Category | Health & Fitness |
| Secondary | Lifestyle (optional) |
| Pricing | Free; no in-app purchase products required |
| Apple silicon Mac availability | Validate the iPad app on Mac separately from a native macOS target before enabling |

Copyright: `2026 Le Bonhomme Pharma`

- Marketing: `https://thebonhomme.com/NATURaL/`
- Support: `https://thebonhomme.com/NATURaL/support/`
- Privacy: `https://thebonhomme.com/NATURaL/privacy/`

Use English and French listing copy in [metadata.md](metadata.md). Developer membership renewal does not prove bundle registration, signing profiles, accepted agreements or an existing app record.

## App Privacy

**Proposed answer: Data Not Collected**, based on the inspected app-owned source paths. No developer-operated upload endpoint, account service, analytics SDK or advertising integration was found. Health, medication, workout and analysis data are processed in local stores; SwiftData explicitly uses `cloudKitDatabase: .none`. YouTube's web player is behind `#if DEBUG`.

This answer describes collection by the developer and integrated partners; it does not mean the app never handles sensitive data or never communicates. Paired Watch transfer, Apple Health, MusicKit, SharePlay, system sharing and website navigation need the distinctions in [privacy-dataflow-review.md](privacy-dataflow-review.md). Required-reason API declarations and empty collection arrays in a privacy manifest do not independently prove the questionnaire answer.

Before submitting, inspect the archive privacy report and actual release network behavior, including linked dependency versions. Reassess if third-party web players, analytics, remote inference, developer sync or diagnostics uploads enter Release. Apple includes integrated partners in disclosure scope and requires disclosure even when collection is for functionality. [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

Do not declare Health/Fitness as collected solely because the user authorizes local HealthKit reads; do declare them if a future data flow meets Apple's collection definition. No tracking integration was found in the inspected paths.

## Export compliance

The source iPhone and Watch plists set `ITSAppUsesNonExemptEncryption` to `false`. Inspected app-owned source uses Apple platform networking and has no custom encryption implementation. Verify the linked release artifacts and answer consistently. This is a prepared technical assessment, not a completed questionnaire. [Apple encryption documentation](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/).

## Age rating and health content

Complete the actual questionnaire against every reachable Release surface. Prescriptions contains medication logging, pharmacology reference profiles and experimental drug/HRV comparisons; the yoga-focused description is not the whole content inventory. Medical/treatment information is present. Assess alcohol, tobacco and drug-reference questions from the substance catalog, not the primary category. No numeric age rating is asserted here; App Store Connect derives it from the answers.

Release excludes the Debug YouTube web player. The inspected product has no general web browser, gambling or public user-generated feed. External privacy/support links remain. Review generated content as well as static screens. [Apple age-rating guidance](https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/).

## Accessibility and macOS

Declare only accessibility features demonstrated for the actual release build and supported platforms. Source labels and simulator journeys alone do not establish the full VoiceOver, Voice Control, larger text, reduced motion or contrast experience. Native macOS and “Designed for iPad” on Mac are different distribution paths; one successful path does not validate the other.

## App Review handoff

Use [metadata.md](metadata.md), with these additional details:

1. No NATURaL account or payment is required. Guided sessions remain available when Health or Music permissions are declined.
2. Health samples depend on permission and available measurements. Clinical import additionally requires in-app consent, Health Records entitlement and a connected supported institution; manual entry is the fallback inside the consent flow.
3. Prescriptions and PokeDrug reference screens are available from home. Logged doses, reference molecular values and HRV observations are distinct sources. Experimental comparisons are not measurements of receptor binding, diagnosis or dosing recommendations.
4. Supported on-device Apple Intelligence may generate wording; deterministic text is the fallback. Review both paths. `InsightEngine` makes no remote model call.
5. The Watch companion records sessions on the wrist; live sensors and phone/Watch transfers require hardware testing.

Supply a reachable reviewer name, email and phone; no phone number has been inferred. Upload, processed-build selection, TestFlight, final review submission and approval remain separate actions with their own receipts.

## Native tvOS listing and review path

Use bundle `com.natural.BonhommeTV`, team `ZJLX84G8QV`, and the standalone-TV EN/FR section of `metadata.md`. The native TV app offers all catalog plans without a phone, account, payment or Health permission. Reviewers can choose a plan, Begin, pause/resume with the remote, and finish. Standalone TV shows unavailable Health/SCI values; it does not synthesize sensor readings.

Optional companion mode requires NATURaL on iPhone/iPad and the same local network. On TV choose Pair iPhone or iPad. On phone scan the invitation with Camera, enable session sharing and confirm the selected TV. The invitation expires after five minutes. Native transport uses OS-provided TLS with a random pre-shared key; the key is not advertised or stored. On-screen health readings are visible to people in the room. AirPlay Screen Mirroring and wired HDMI use the iOS external-display path separately.

Capture actual standalone and paired TV screens after SDK/device validation; do not publish a live pairing credential. Verify listing platform association and bundle identifiers in App Store Connect before creating records. Signed upload, privacy/export answers, device tests, screenshots and final review submission remain pending.
