# iPadOS — split canvas

Overrides MASTER for `Bonhomme/` regular width.

- **Home:** `NavigationSplitView` sidebar of yoga styles (not a phone tab bar scaled up). Detail is catalog or empty-state, never a second home stack.
- **Session:** 60/40 pose stage + `SessionHUDPanel(showsGauges: true)`. Controls stay in the bottom inset (prominence `.pad`).
- **Measure:** inspector ~340pt; long copy `fixedSize(horizontal: false, vertical: true)`; gutters `SessionSpacing.xxl`.
- **Hits:** sidebar rows and Cancel ≥44pt. Accessibility sizes fall back to the phone column (`usesRegularSessionLayout` is false).
- **Do not:** edge-to-edge paragraphs; blank detail; cyan SCI.
