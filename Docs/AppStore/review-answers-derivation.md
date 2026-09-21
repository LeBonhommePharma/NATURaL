# Age rating and export compliance — derived, 20 September 2026

Evidence behind the prepared answers in [app-store-connect.md](app-store-connect.md).
Where code does not settle a question it is left unanswered with an em dash.

## Export compliance

### What the app actually encrypts

One encryption path ships. `BonhommeCore/.../TVDisplay/TVRelayPairing.swift`:

| Line | Fact |
|---|---|
| `:17` | `SecRandomCopyBytes(kSecRandomDefault, …)` generates the ephemeral pairing key |
| `:71-72` | `sec_protocol_options_append_tls_ciphersuite(…, TLS_PSK_WITH_AES_128_GCM_SHA256)` |
| `:73-74` | min **and** max TLS version both pinned to `.TLSv12` |

So: AES-128-GCM under TLS 1.2 with a pre-shared key, entirely through Apple's
Network/Security frameworks. There is no custom cipher, no bundled crypto
library, and no proprietary protocol. The key is random per pairing and never
persisted off device.

### Current declaration

`ITSAppUsesNonExemptEncryption = false` in all five Info.plists (`Bonhomme`,
`BonhommeWatch`, `BonhommeMac`, `BonhommeTV`, `BonhommeVision`).

### Assessment

**`false` is defensible and is what I would keep.** The app uses encryption, but
only encryption provided by the operating system, which is the standard
exemption. Nothing here implements or bundles cryptography.

**Where I am being conservative, and where LP should confirm:** the app supplies
its *own* key material to Apple's TLS rather than relying on certificate-based
HTTPS. That is still Apple's implementation doing the cryptography, so the
exemption holds on the plain reading — but it is the one detail a reviewer could
ask about, and it is worth a deliberate confirmation rather than inheriting the
`false` by default. If LP prefers the cautious route, the alternative is to
declare encryption and claim the "only exempt encryption" exemption, which
reaches the same outcome with a questionnaire step. —

## Age rating

The primary category is Health & Fitness, but the rating is driven by
**Prescriptions**, not by the yoga content.

### Reachable content that bears on the questionnaire

- Medication logging and schedules, and clinical-record import under separate
  consent (`Bonhomme/Features/Prescriptions/PrescriptionsView.swift`).
- A pharmacology reference catalogue — `PokeDrugSpecies.swift` carries substance
  descriptions including regulatory status and mechanism (e.g. esketamine's FDA
  approval and reported onset at `:767`).
- Experimental drug-vs-HRV comparisons surfaced in
  `PokeDrugSubstanceInsightView.swift`.

### Answers and reasons

| Question | Answer | Reason |
|---|---|---|
| Medical/Treatment Information | **Yes — infrequent/mild** | Medication schedules, clinical-record import and pharmacology reference text are reachable. Answering "none" would be false. |
| Alcohol, Tobacco, or Drug Use or References | **Yes — infrequent/mild** | The substance catalogue names controlled substances and describes mechanisms. This is reference material, not depiction or encouragement, but it is present. |
| Unrestricted Web Access | **No** | The only `WKWebView` is `#if DEBUG` (`YouTubePlayerView.swift:2`) and ships in no Release build. External links open Safari. |
| Gambling / Contests | **No** | None present. |
| User-Generated Content | **No** | Notes are local free text; there is no feed, sharing surface or moderation requirement. `PrescriptionsView` warns against entering credentials. |
| Horror/Fear, Violence, Sexual Content, Profanity, Mature Themes | **No** | None present. |

**Where I was conservative:** both "Yes" answers above could be argued to "None"
on the grounds that the app neither depicts nor encourages substance use and is
not a medical device. I would not argue that. The content is reachable, Apple
asks about references rather than endorsement, and a rating that is one step
stricter than necessary costs nothing, while an understated one is a review
finding. App Store Connect derives the numeric rating from the answers — none is
asserted here.

**RESOLVED 20 September 2026 — Prescriptions ships enabled.** LP, verbatim:
*“Questions yes to Prescriptions and age rating to all”*. He has accepted the age
rating that follows from the feature shipping.

This changes the *standing* of the two “Yes” answers above without changing their
text, and the distinction matters if a reviewer asks. They were written as the
stricter of two defensible readings — “we chose the safer answer.” They are now
simply **the correct answers**: the Prescriptions feature, the medication
schedules, the clinical-record import and the pharmacology reference text are all
reachable in the shipped 1.0 build, so Medical/Treatment Information and the
substance reference are present as a matter of fact, not of caution. The
paragraph above about being one step stricter than necessary no longer describes
why these answers are what they are; it is retained only as the record of how they
were originally derived.

App Store Connect still derives the numeric rating from the answers. No numeric
rating is asserted here — LP accepted whatever it yields, not a specific number.

