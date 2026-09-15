# Third-party dependency notices (submission prep)

Scope at this moment: iOS/iPadOS/watchOS app bundle target graph as configured in
`NATURaL.xcodeproj` (Swift target dependencies and Xcode remote package references).

## In-repo and SDK dependencies

- **CareKit** (remote Swift Package):
  - Source: `https://github.com/carekit-apple/CareKit.git`
  - Requirement: up to next major, minimum 4.1.0
  - License: BSD-style terms matching the upstream header text in
    `https://raw.githubusercontent.com/carekit-apple/CareKit/main/LICENSE`.

- **Apple system frameworks** (HealthKit, MusicKit, CareKitStore overlays, SwiftUI,
  SwiftData, WatchKit, AVFoundation, etc.):
  - Provided under Apple platform SDK terms.

- **No additional remote runtime dependencies** are declared in the default
  submission path. Local `BonhommeAccel` remains opt-in and is currently not part of
  the default Swift package dependency graph used for Swift package tests.

## Notes for App Privacy/attribution

- Required-reason API manifests were verified with
  `python3 scripts/validate-submission.py` and declare no tracking and no
  collected data types. Paste **Data Not Collected** in App Store Connect; see
  `Docs/AppStore/app-store-connect.md`.
- Keep this notice file with your release artifacts and confirm the exact license text
  in App Store Connect as part of the final App Privacy/legal review.
