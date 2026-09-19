# App localization coverage

Updated 19 September 2026. OS language selection supports `en`, `fr`, `es`, `ja`, `zh`, `ko`, `ru`, `de`, `ar`, `it`, and `pt`. Regional codes resolve to the existing base-language translation; `zh-Hant` does not imply a dedicated Traditional Chinese translation.

The supplemental bundled catalog adds 75 exact English keys across all eleven languages (825 nonempty values) for common navigation, guidance and TV copy. Explicit inline translations take precedence, then the catalog, then English. Saved and relayed Codable fields retain their original content. This is offline exact-key lookup, not automatic translation of interpolated text.

Reproduce the source inventory with:

```sh
python3 scripts/localization_inventory.py --output /tmp/natural-localization.json
python3 scripts/localization_inventory.py --check-resources
python3 scripts/test_localization_inventory.py
```

The current inventory found 1,106 nonempty static English entries. Remaining static fallbacks are 390 each for Spanish, Japanese, Chinese, Korean, Russian, German and Arabic; Italian and Portuguese each have 959. Separately counted are 60 interpolated entries, 15 expression entries and 92 native SwiftUI literal candidates. Counts describe conservative source analysis, not distinct screens, translation quality or completed language support. Re-run after source changes.

Six Python resource/inventory tests pass. An isolated SwiftPM executable using actual source and bundled JSON verified all eleven language lookups, regional normalization, explicit overrides, missing keys, arrays and Codable preservation. Five added XCTest cases run in hosted CI; local Command Line Tools lack XCTest/asset compilation support.

Remaining release work: translate missing app copy, review medical/exercise terminology with qualified speakers, inspect Arabic directionality and all languages at large text on native devices, and confirm that App Store language descriptions match actual coverage. Website editions and translated permission prompts do not establish full in-app translation.
