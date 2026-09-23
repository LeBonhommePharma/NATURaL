# Age rating and export compliance — derived, 20 September 2026

Evidence behind the prepared answers in [app-store-connect.md](app-store-connect.md).
Where code does not settle a question it is left unanswered with an em dash.

## Export compliance

### Determination

**Decided 20 September 2026. `ITSAppUsesNonExemptEncryption = false`; the
exemption is claimed.** This is no longer an open question and should not be
re-derived from scratch.

The reasoning, stated plainly: Apple's TLS stack performs all of the
cryptography. The app supplies key material to that stack but implements no
cipher and bundles no cryptographic library.
`TLS_PSK_WITH_AES_128_GCM_SHA256` is an OS-provided ciphersuite reached through
Network.framework. Supplying a pre-shared key is *using* Apple's implementation,
not adding to it, and the exemption does not turn on whether the key material
arrived from a certificate chain or from a QR code.

**Provenance — read this before relying on the determination.** It is LP's own
determination, made on 20 September 2026 (Montreal local time). It has **not**
been reviewed by counsel and has **not** been submitted to BIS. No outside
opinion was obtained. Treat it as a documented engineering-and-owner judgement,
which is what it is, and not as a legal clearance.

### The artefact this determination covers

The scope is one code path, and the determination extends no further than it.
`BonhommeCore/Sources/BonhommeCore/TVDisplay/TVRelayPairing.swift`:

| Line | Fact |
|---|---|
| `:17` | `SecRandomCopyBytes(kSecRandomDefault, …)` generates the ephemeral pairing key — a random number generator, not encryption |
| `:70` | `sec_protocol_options_add_pre_shared_key(…)` — the call site the determination is about |
| `:71-72` | `sec_protocol_options_append_tls_ciphersuite(…, TLS_PSK_WITH_AES_128_GCM_SHA256)` |
| `:73-74` | min **and** max TLS version both pinned to `.TLSv12` |

The secret is 32 bytes, generated per pairing, distributed **out of band** by
on-screen QR or manual code, and never advertised over Bonjour or persisted.
The channel carries session telemetry — heart rate, SCI and pose state — to the
TV display over local-network peer-to-peer.

**This code is present in the shipped binary.** `nm -u` against the 1.0 (1)
archive resolves `_sec_protocol_options_add_pre_shared_key` and
`_sec_protocol_options_append_tls_ciphersuite` in `Bonhomme.app/Bonhomme`.
PR #41 hides the TV pairing *user interface* while the tvOS app is unpublished;
that is a UI change and does not remove the code. A future reader must not
conclude from the hidden UI that the encryption path is absent from the build.

### Audit evidence — what was searched for and not found

The negative results are the substance of the determination. If a reviewer asks
what was checked, this is the list. Searched across the app target, both
appexes (`NATURaLLiveActivity`, `NATURaLWidgets`) and the watch app:

| Searched for | Result |
|---|---|
| `import CryptoKit`, `import CommonCrypto`, `CommonCrypto.h` | none |
| `CC_SHA*`, `CCCrypt`, `CCHmac`, `CCKeyDerivationPBKDF`, `CCCryptorCreate` | none |
| `SecKeyCreateEncryptedData`, `SecKeyCreateDecryptedData`, `SecEncryptTransform`, `SecDecryptTransform` | none |
| Third-party crypto: OpenSSL, BoringSSL, libsodium, CryptoSwift, RNCryptor, Themis, sqlcipher, swift-crypto | none |
| Hand-rolled cipher, KDF, or "encrypt before writing" path | none |
| CocoaPods / Carthage manifests | none present; SPM only |

Resolved SPM dependencies are CareKit, FHIRModels, swift-async-algorithms and
swift-collections. None is a cryptographic library.

Two findings are encryption-adjacent and are **exempt** on their own terms:
Keychain is not used at all, and data at rest relies on iOS Data Protection
(`FileProtectionType.completeUntilFirstUserAuthentication`,
`Bonhomme/Services/Persistence/PersistentModels.swift`), which is OS-provided.

### What would re-open this determination

The determination is inherited by future builds only while the facts above hold.
Any of the following invalidates it, and the audit must be re-run rather than the
`false` inherited:

- Adding any cryptographic dependency to `Package.swift` or the Xcode project.
- Introducing `CryptoKit`, `CommonCrypto`, or Security-framework encryption APIs
  beyond Keychain storage and random-number generation.
- Any hand-rolled cipher, key-derivation function, or proprietary protocol.
- Changing what `TVRelayPairing` carries, or how its key is derived or exchanged.
- Widening the relay beyond local-network pairing — for example relaying through
  a server, or making the channel reachable off the local network.

### What the enforcement scripts do and do not cover

`scripts/test_contracts.py` and `scripts/validate-submission.py` both assert that
`ITSAppUsesNonExemptEncryption` is `false` in the shipped plists. That is all
they do. **Neither script audits source for cryptography.** A green contract run
proves the declaration is still present and still `false`; it proves nothing
about whether the code behind it still qualifies. Do not read a passing test as
a fresh audit.

### Reporting obligation

Under a `false` declaration the exemption is claimed and no annual
self-classification report to BIS is owed. A future reader should not go looking
for a filing that was never required. This follows from the determination above
and carries the same caveat: it is LP's judgement, not counsel's.

### Original derivation, retained as record

The paragraph below is how the question was first worked through, when it was
still open. It is kept because it shows the reasoning, not because it is still
the operative statement — the determination above is. It ended by asking LP to
confirm the one detail it was uneasy about; that confirmation is what the
determination records.

> **`false` is defensible and is what I would keep.** The app uses encryption, but
> only encryption provided by the operating system, which is the standard
> exemption. Nothing here implements or bundles cryptography.
>
> **Where I am being conservative, and where LP should confirm:** the app supplies
> its *own* key material to Apple's TLS rather than relying on certificate-based
> HTTPS. That is still Apple's implementation doing the cryptography, so the
> exemption holds on the plain reading — but it is the one detail a reviewer could
> ask about, and it is worth a deliberate confirmation rather than inheriting the
> `false` by default. If LP prefers the cautious route, the alternative is to
> declare encryption and claim the "only exempt encryption" exemption, which
> reaches the same outcome with a questionnaire step.

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

