# Third-party dependency notices

Reviewed 19 September 2026 against Xcode `Package.resolved`, local checkouts at those exact revisions, and their package manifests. Resolved packages are not all necessarily linked into the shipped binary.

| Package | Version / revision | Submission-path use | Exact license copy |
| --- | --- | --- | --- |
| CareKit | 4.1.0 / `348a5efbd10cb79d92c760c8023156015558b06b` | iOS links `CareKitStore`; remote open-source dependency, not an Apple system framework | [CareKit license](licenses/CareKit-LICENSE.txt) |
| swift-async-algorithms | 1.0.1 / `6ae9a051f76b81cc668305ceed5b0e0a7fd93d20` | Transitive `CareKitStore` dependency | [Swift Async Algorithms license](licenses/swift-async-algorithms-LICENSE.txt) |
| swift-collections | 1.4.1 / `6675bc0ff86e61436e615df6fc5174e043e57924` | `AsyncAlgorithms` uses `OrderedCollections` and `DequeModule` | [Swift Collections license](licenses/swift-collections-LICENSE.txt) |
| FHIRModels | 0.5.0 / `861afd5816a98d38f86220eab2f812d76cad84a0` | Resolved by CareKit; used by `CareKitFHIR`, which the inspected app target does not link. Recheck if target graph changes | [FHIRModels license](licenses/FHIRModels-LICENSE.txt) |

The [license manifest](licenses/manifest.json) records SHA-256 digests of exact upstream license files. Swift Async Algorithms and Swift Collections include Apache 2.0 and Swift runtime-exception terms; retain the complete files. CareKit carries its own redistribution conditions. Do not replace these texts with generic Apple SDK attribution or a link to a moving branch.

Apple platform frameworks (HealthKit, MusicKit, SwiftUI, SwiftData, WatchKit, AVFoundation, Foundation Models, etc.) fall under their SDK agreements. Local `BonhommeCore` is repository code. `BonhommeAccel` is opt-in and absent from the default dependency graph; enabling it requires a fresh inventory.

The app now has `Bonhomme/Resources/Acknowledgements.txt` and an About navigation entry containing the linked CareKit, Swift Async Algorithms and Swift Collections license texts. FHIRModels remains inventoried above as a resolved but unlinked package. Confirm the acknowledgements resource and accessible screen in the signed archive; source wiring alone is not an archive receipt.

Attribution and App Privacy are separate checks. See [app-store-connect.md](app-store-connect.md) and [privacy-dataflow-review.md](privacy-dataflow-review.md).
