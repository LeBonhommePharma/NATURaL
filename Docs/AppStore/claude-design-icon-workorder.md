# Claude Design workorder — NATURaL App Store icons

Owner: LP / Le Bonhomme Pharma. Product: **NATURaL** (Bonhomme), chair yoga + biofeedback.
This is **not** Exergy. Do not draw gauges, remaining %, menu-bar pills, or usage chips.

This repo already ships **valid opaque RGB PNGs (no `tRNS`)** derived from the approved Unfolding Light bloom:

| Asset | Size | Path |
| --- | --- | --- |
| iPhone / iPad App Store | 1024×1024 | `Bonhomme/Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| Watch | 1024×1024 (circular crop) | `BonhommeWatch/Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| visionOS | 1024×1024 | `BonhommeVision/Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| tvOS small | 400×240 / 800×480 | `BonhommeTV/Assets.xcassets/AppIcon.appiconset/AppIcon-400.png` (+ `-800`) |
| tvOS flattened master | 1280×768 | `BonhommeTV/Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| Square brand master | 1024×1024 | `BonhommeTV/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` |

The 1280×768 TV file is a **letterboxed** copy of the iOS bloom on `#08091A`. It is App Store–legal (opaque RGB) but **not** a layered tvOS icon and **not** a visionOS glass stack. Produce professional per-OS finals in Claude Design / Apple Icon Composer.

## Brand (locked)

- Midnight plum field `#08091A` (edge-to-edge, fully opaque).
- Luminous unfurling bloom: amber/gold orb, coral cupped base, violet inner petals, turquoise/jade outer petals.
- No letters, no wordmark, no medical crosses, lotus clip-art, sparkle particles, or emoji.
- Recognizable silhouette at 40px. No baked iOS squircle / watch circle / TV bezel.

Prompts already approved: [icon-design.md](icon-design.md).

## Per-OS deliverables

### 1. iPhone + iPad (same iOS record)

- **1024×1024** 8-bit RGB PNG, no alpha, no `tRNS`.
- Safe zone: keep bloom in the **center 80%**. Apple applies the squircle; do not round corners.
- Light/dark: **one** marketing icon (iOS does not ship separate light/dark App Store icons). In-app bloom (`Bloom.imageset`) may match.
- Replace the current iOS master only if the new file is sharper; identity must stay Unfolding Light.

### 2. Apple Watch (companion)

- **1024×1024** 8-bit RGB PNG, no alpha.
- Composition already tighter (~68% bloom). Keep **8% margin** inside the inscribed circle — Apple applies the circular mask.
- No pre-drawn circle. No watch hardware mockup.
- Complications are not this workorder.

### 3. Apple TV (tvOS companion)

Produce a **layered** App Icon (Front / Middle / Back), not a flat poster:

| Layer | Size @1x / @2x | Content |
| --- | --- | --- |
| Back | 400×240 / 800×480 | Solid `#08091A` or a very slow plum gradient. No bloom. |
| Middle | 400×240 / 800×480 | Soft jade/violet glow, no hard edges; parallax depth only. |
| Front | 400×240 / 800×480 | Bloom + gold orb only. **Safe zone:** keep all petal tips inside the center **80%** width and **70%** height (TV overscan / parallax). |
| App Store | **1280×768** flattened RGB, opaque | Same identity; no layers in this file. |

Do not put UI, “NATURaL”, or focus rings on any layer. No transparency on the App Store 1280×768 file.

### 4. Apple Vision Pro (visionOS)

- **1024×1024** layered app icon for the visionOS glass material (Front / Middle / Back), plus a flattened **1024×1024** opaque RGB App Store fallback (no `tRNS`).
- Back: plum. Middle: soft inner illumination. Front: bloom, centered, **large side margins** (visionOS trims a circle-ish glass hover).
- No baked glass, no simulated 3D device.

## Export rules (all files)

- PNG, 8-bit, color type 2 (RGB), **no tRNS chunk**, no indexed color, no interlacing.
- sRGB. No EXIF orientation tricks.
- Do not ship emoji, SF Symbols, or charts in the icon.
- File names: keep `AppIcon.png` / `AppIcon-400.png` conventions in the catalogs above.

## Out of scope

- macOS (not a store listing).
- Android / web favicons.
- App Store screenshots (separate device capture).
- Signing, App Store Connect upload, Icon Composer project in this Linux agent.

When the layered TV + Vision files exist, drop them into the catalogs and delete the letterboxed TV placeholder if it is superseded.
