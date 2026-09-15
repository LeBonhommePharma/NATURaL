# App Store Connect — privacy and listing answers

Paste these after creating the app record. They match the shipping binary: on-device analysis, no developer collection.

## Identity

| Field | Value |
| --- | --- |
| Name | NATURaL: Chair Yoga |
| Bundle ID | com.natural.Bonhomme |
| SKU | natural-chair-yoga-1 |
| Primary language | English (U.S.) |
| Category | Health & Fitness |
| Secondary | Lifestyle (optional) |
| Pricing | Free |
| Apple silicon Mac | Do not offer until native Mac use is validated |

Copyright: `2026 Le Bonhomme Pharma`

URLs: marketing `https://thebonhomme.com/NATURaL/`, support `https://thebonhomme.com/NATURaL/support/`, privacy `https://thebonhomme.com/NATURaL/privacy/`

## Export compliance

`ITSAppUsesNonExemptEncryption` is `false` on iPhone and Watch. Answer that the app uses only exempt encryption (HTTPS to Apple services the user opts into).

## App Privacy

Select **Data Not Collected**.

Evidence in this checkout:

- No developer servers, accounts or analytics
- SwiftData uses `cloudKitDatabase: .none`
- No CloudKit, iCloud container or iCloud KVS entitlements
- Privacy manifests set `NSPrivacyTracking` to false and declare no collected data types
- Health samples stay in Apple Health or on-device stores we cannot read
- YouTube WKWebView is compiled only in Debug

Optional Apple Music, paired Watch, local AirPlay/tvOS display and SharePlay are user-initiated Apple or local-network paths. They are not Le Bonhomme Pharma collection.

Do not select Health, Heart Rate, Workout or other types as collected by us. Do not select tracking.

## Age rating

Answer from the reachable 1.0 UI (guided chair yoga, optional Health, optional medication reminders, experimental entropy copy). Recheck if those surfaces change.

Likely: medical/treatment information present (medication reminders and experimental entropy copy); unrestricted web access **No** in Release; no gambling, no user-generated web browsing.

## Accessibility

Declare only features verified on hardware. Simulator journeys do not authorize VoiceOver or Reduce Motion claims.

## Review notes

See [metadata.md](metadata.md). Add that records stay on device, analysis is local, and Health is optional.
