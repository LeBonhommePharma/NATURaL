# tvOS — 10-foot companion

Overrides MASTER for `BonhommeTV/` + `TVDisplayView`.

- **Role:** second screen for the iPhone session (Bonjour). No HealthKit on TV. Idle state is “waiting for workout”.
- **Layout:** 60/40 pose countdown + `SessionHUDPanel(..., spaciousChips: true)`. Focusable inspector.
- **Type:** `.title3` / `.largeTitle` chips. Connection status uses mint, not system green.
- **Motion:** idle breath `TimelineView` **pauses** when Reduce Motion is on.
- **Icons:** layered App Store TV icon is a Design workorder; repo ships an opaque RGB master until layers land.
- **Do not:** iPhone chrome; hover; emoji; collecting data on the TV.
