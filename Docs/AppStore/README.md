# NATURaL — App Store preparation

This is repository preparation, not an uploaded or approved release. Target audience: general wellness. All chair-yoga sessions are available; no NATURaL account or login is required.

Start with the [submission TODO list](TODO.md) and [verification evidence](verification.md). The [website](https://thebonhomme.com/NATURaL/), [privacy policy](https://thebonhomme.com/NATURaL/privacy/) and [support page](https://thebonhomme.com/NATURaL/support/) are published.

## Release identity

| Field | Value |
| --- | --- |
| Display name | NATURaL |
| Account selected by owner | lp@thebonhomme.com |
| Confirmed team | ZJLX84G8QV |
| iPhone / iPad | com.natural.Bonhomme |
| Watch companion | com.natural.Bonhomme.watchkitapp |
| Widgets | com.natural.Bonhomme.Widgets |
| Live Activity | com.natural.Bonhomme.LiveActivity |
| App Group | group.com.natural.Bonhomme |
| Version | 1.0; choose a fresh build number for each upload |
| Minimum OS | iOS / iPadOS 18; watchOS 10 |
| Acceleration | Pure Swift by default; C++ remains opt-in |

The previous Watch identifier was `com.natural.BonhommeWatch`; its new identifier is a child of the iOS identifier as required for embedding. Register the companion identifier under the confirmed team. Existing developer-installed Watch data under the old identifier will not migrate automatically.

## What was prepared

- Opaque 1024-square iOS and watchOS icon assets and matching in-app bloom artwork.
- Actual resource phases for icons and privacy manifests; Watch dependency and embedding in the iOS archive.
- Correct Boolean `WKApplication`, top-level Watch background modes, companion identifier and Live Activities declaration.
- Session-first navigation, first-use introduction, optional Health permission entry, local history, Watch startup/save failure states, and responsive home layout.
- Required-reason manifests for the app, Watch, widgets, Live Activity and Swift package. They declare no tracking and no collected data types. They are not a substitute for pasting **Data Not Collected** in App Store Connect.
- Local SwiftData health storage. CloudKit and iCloud KVS entitlements are removed. Cloud session-presence is not published. Existing named on-device store is preserved. No remote records were deleted.
- OS language preference matching for all 11 supported app languages, with English fallback for untranslated strings. The website has 11 complete language editions, including Arabic RTL.
- Simulator launch, Live Activity entry-point, iPad session presentation, summary responsiveness and HealthKit/Watch lifecycle fixes.
- CI that fails on build/test errors and uses an SDK floor check; existing releases now depend on those checks.

## Verify and archive

```sh
python3 scripts/validate-submission.py
swift test --package-path BonhommeCore
xcodebuild build -project NATURaL.xcodeproj -scheme Bonhomme \
  -configuration Release -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
BUILD_NUMBER=2 scripts/archive-app-store.sh
```

The archive script creates a local signed archive and never uploads. It does not silently create identifiers or certificates. In Xcode Settings → Accounts, sign in with the confirmed account and ensure the selected team has valid provisioning for every embedded target. Enable HealthKit (including clinical records if retaining that feature), HealthKit background delivery, App Groups, Siri and the services actually shipped. Distribution certificates and profiles remain an account-side check. The local identity audit found one Apple Development certificate labeled `lmorency@me.com`; that label alone does not establish distribution readiness.

Use Organizer → Validate App on the signed archive. Inspect embedded Watch app, extension identifiers, entitlements, privacy report and icon previews. Then use TestFlight for device validation before submission.

## Remaining release gates

1. Publish the regenerated privacy/support pages to GitHub Pages, then enter the live URLs in App Store Connect. Repository copy now states on-device analysis and **Data Not Collected**.
2. Paste App Privacy from [app-store-connect.md](app-store-connect.md). Do not declare Health or other types as collected by us.
3. Verify backup exclusion/protection for personal health data on a physical device, including SwiftData, CareKit, UserDefaults recovery snapshots and App Group widget state.
4. Supply screenshots from the running final build at Apple's accepted sizes for iPhone, iPad and Watch.
5. Test VoiceOver, accessibility text sizes, landscape/split view, reduced motion, denied/revoked Health permissions, offline use, and paired Watch behavior on physical devices.
6. Resolve any remaining scientific/medical claims in shipped insights. SCI indicators are exploratory, not diagnosis.
7. Complete age-rating questions; select Health & Fitness, pricing Free, territories and release method.
8. Confirm the production Xcode build is accepted by App Store Connect.

## Sources

Checked 2026-09-12:

- [Apple submission guidance](https://developer.apple.com/app-store/submitting/)
- [SDK minimum requirements](https://developer.apple.com/news/?id=ueeok6yw)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — especially 2.1, 5.1.1 and 5.1.3(ii).
- [Asset-catalog icons](https://developer.apple.com/documentation/xcode/configuring-your-app-icon)
- [Required-reason APIs](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
- [GitHub macOS runner software](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md)
