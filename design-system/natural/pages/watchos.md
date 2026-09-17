# watchOS — wrist glance

Overrides MASTER for `BonhommeWatch/`.

- **Home:** compact `List` — Start gently, then Explore. No bloom hero art on the home list.
- **Session:** vertical paging `TabView` (pose / SCI+HR / controls). Digital Crown is β, not a hidden End gesture.
- **HUD:** `SessionGlanceStrip` + 44pt `CompactSCIMeter`. Unknown SCI is `—`, never a full ring as 0%.
- **Motion:** no bounce; Reduce Motion pauses breathing guide animation.
- **Do not:** tiny unlabeled icons; Mac-style inspector; emoji; inventing extra pages.
