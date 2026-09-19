# Hosted signing without installing Xcode locally

`Manual signed archive` (`.github/workflows/signed-archive.yml`) builds on a disposable GitHub macOS runner. Choose `ios` for the combined iPhone/iPad/Watch archive, `tvos` for Apple TV, or `macos` for the native Mac app. It creates a signed `.xcarchive` ZIP and validation receipts. It never exports an IPA/PKG, uploads to Apple, or submits for review.

The workflow is implemented and its offline policy tests pass. **It has not created a signed archive yet:** this repository has no signing secrets configured. The existing unsigned CI receipts do not prove distribution signing or App Store acceptance. After supplying credentials, the first manual run must establish that evidence.

## One-time account setup

Use Apple Developer team **ZJLX84G8QV**, belonging to the confirmed membership. No App Store Connect API key, Apple ID password, or app-specific password is required for this path. Provisioning is manual, and the workflow never enables `-allowProvisioningUpdates`.

1. Create or obtain an exportable **Apple Distribution** certificate and its private key for iOS/watchOS/tvOS. For the native Mac app, use an Apple Distribution or Mac App Distribution (`3rd Party Mac Developer Application`) identity accepted by the corresponding Mac App Store profile. A Developer ID certificate is not a Mac App Store distribution identity. Do not revoke an existing certificate just to make room without checking its users.
2. Xcode is not required on this Mac to create the certificate request: use Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority. Submit the CSR through Apple Developer Certificates, download the issued certificate, and import it into the same keychain. Export the certificate **with its matching private key** as a password-protected `.p12`. An existing cloud-managed signing certificate has no exportable private key; this workflow needs an exportable identity.
3. Register the explicit App IDs below. Match their capabilities to the checked-in entitlement files: the phone currently requires HealthKit/background delivery/health records, App Groups, Siri and push; Watch requires HealthKit/background delivery and App Groups; Widgets requires App Groups. The group is `group.com.natural.Bonhomme`. Review any entitlement changes before generating new profiles.
4. Generate App Store Connect distribution profiles for the selected platform and certificate. **Set each profile's Name to its exact bundle ID** in the table. An explicit target-name lookup selects each app, Watch and extension profile; Swift package resource bundles receive no profile. Select explicit IDs, never a wildcard. Profiles must remain valid for more than 24 hours at build time. App Store profiles have no device roster; development, ad hoc, enterprise and Developer ID profiles are rejected.

| Archive | Profile Name and explicit bundle ID | Base64 profile secret |
| --- | --- | --- |
| iOS/iPadOS | `com.natural.Bonhomme` | `NATURAL_IOS_PROFILE_BASE64` |
| Embedded Watch | `com.natural.Bonhomme.watchkitapp` | `NATURAL_WATCH_PROFILE_BASE64` |
| Embedded Widgets | `com.natural.Bonhomme.Widgets` | `NATURAL_WIDGETS_PROFILE_BASE64` |
| Embedded Live Activity | `com.natural.Bonhomme.LiveActivity` | `NATURAL_LIVE_ACTIVITY_PROFILE_BASE64` |
| tvOS | `com.natural.BonhommeTV` | `NATURAL_TVOS_PROFILE_BASE64` |
| macOS | `com.natural.Bonhomme.mac` | `NATURAL_MACOS_PROFILE_BASE64` |

Apple's profile chooser calls the types **App Store Connect** for iOS/watchOS, **tvOS App Store Connect** for TV, and **Mac App Store Connect** for Mac. The iOS archive requires all four phone/Watch/extension profiles, signed for the same supplied distribution certificate. Only the selected platform's secrets are required.

## GitHub environment secrets

Create repository environment **`app-store-signing`** in GitHub Settings → Environments. Configure required reviewers and deployment branch restrictions to trusted, reviewed release branches before adding credentials. GitHub plan/repository settings determine which protection features are available; do not assume a newly created environment is protected. Anyone allowed to modify and dispatch trusted workflow code with these secrets can use the signing identity.

Add these as **environment secrets**, not variables or committed files:

| Secret | Value |
| --- | --- |
| `NATURAL_DISTRIBUTION_P12_BASE64` | Base64 of the iOS/watchOS/tvOS distribution `.p12` |
| `NATURAL_P12_PASSWORD` | Its nonempty export password |
| `NATURAL_MAC_DISTRIBUTION_P12_BASE64` | Base64 of the Mac App Store distribution `.p12` |
| `NATURAL_MAC_P12_PASSWORD` | Its nonempty export password |
| Profile secrets listed above | Base64 of each downloaded `.mobileprovision` or Mac `.provisionprofile` |

To populate a file secret from this Mac without printing credential bytes to the terminal:

```sh
base64 -i /path/to/distribution.p12 | gh secret set NATURAL_DISTRIBUTION_P12_BASE64 --env app-store-signing
base64 -i /path/to/phone.mobileprovision | gh secret set NATURAL_IOS_PROFILE_BASE64 --env app-store-signing
```

Use GitHub's secret form for passwords, or `gh secret set NATURAL_P12_PASSWORD --env app-store-signing` and enter it at the prompt. Repeat the file command for the matching table entry. Do not paste credentials into a task, issue, pull request, build log or source file. Base64 encodes bytes; it does not encrypt them.

## Run and inspect

1. Merge the reviewed workflow into the repository's default branch so GitHub exposes its manual dispatch form. Confirm the full unsigned CI suite passes for the intended commit.
2. Open Actions → Manual signed archive → Run workflow. Select a trusted branch, platform and new positive `build_number`. The receipt records the actual checked-out commit; verify it matches the release candidate. Approve the GitHub environment gate if configured.
3. The runner verifies SDK26+, source packaging, and signing policy fixtures. It installs credentials into an isolated temporary keychain and installs only the selected profiles. It validates profile team, dates, exact ID/name, distribution restrictions, certificate match and required capabilities; a mismatched input fails before archiving.
4. It first checks Xcode’s resolved signing settings for every shipping target, then archives with manual signing, checks the compiled bundle graph/signatures, and verifies each embedded profile matches the supplied bytes, the signer matches the supplied certificate, debugging is disabled, and the phone's push entitlement is production. A failed check prevents creation of the distributable archive ZIP.
5. Download `signed-archive-<platform>-<run ID>` within **7 days**. It contains the verified archive ZIP if successful, distribution validation, Xcode version, archive/structural-validation logs and `receipt.json`. A failure artifact contains receipts/logs only; it is not evidence of a valid archive. No `.p12`, private key, temporary keychain, raw secret file, derived-data tree or result bundle is uploaded.

The archive necessarily embeds public signing certificates and provisioning metadata. Artifact access follows repository/GitHub permissions, and the archive contains the unreleased app. Keep downloaded release artifacts in controlled storage. The cleanup step always restores the runner's prior keychain search list and removes the temporary keychain, installed profiles and credential files before artifact upload. GitHub destroys the hosted machine after the job. This workflow intentionally refuses self-hosted runners.

Apple Organizer/distribution validation, App Store Connect processing, physical-device acceptance checks, screenshots, review metadata and final submission remain separate gates. A successful archive does not mark any of those complete. The workflow performs no Apple upload or submission, including on success.

## Local/offline checks

```sh
python3 scripts/test_cloud_signing.py
bash -n scripts/archive-app-store.sh
```

The helper's profile tests use synthetic data. They cover wrong team/ID/platform/certificate, profile naming, expired and future credentials, device-limited and enterprise profiles, missing capabilities, development push/debug flags, safe UUID handling, and redaction of failed credential commands. Real certificate import, Xcode per-target profile expansion, archive signing and Apple's validation remain untested until the first configured hosted run.

References: [Apple App Store profile creation](https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile), [Apple certificate requests without Xcode](https://developer.apple.com/help/account/certificates/create-a-certificate-signing-request), [Apple profile structure and distribution restrictions](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles), [GitHub signing on hosted macOS runners](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications).
