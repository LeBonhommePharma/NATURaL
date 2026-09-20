# Dark-appearance colorset twins — consumer spec for NATURaL

Status: **blocked on the design-system session** (`Derive universal design
system`, `lebonhommepharma.github.io`). LP ruled on 20 September 2026 that the
twins should exist and that `design-system/natural/MASTER.md` stands as written —
softening the doc is off the table.

NATURaL **consumes** what that session produces and does **not** author its own
twins. Two sources of truth are how this gap appeared; duplicating the generation
would recreate it. This file exists only so the producer knows the consumer's
exact shape.

## Target

```
BonhommeCore/Sources/BonhommeCore/Resources/BrandColors.xcassets/
```

All ten colorsets currently hold a single universal colour with **no
`appearances` entry**, so nothing adapts. `BrandColor.fg` and
`BrandColor.fgAsset` both resolve to a fixed `#E4E3F5`.

| Colorset | Light value | Semantic role (quantity-bound, never reassigned) |
|---|---|---|
| `BrandBg` | `#08091A` | Background / page ink |
| `BrandFg` | `#E4E3F5` | Foreground — 15.60:1 on bg |
| `BrandFgMuted` | `#8D8CB0` | Muted — 6.12:1 on bg |
| `BrandMint` | `#45E0A8` | Primary CTA / ΔH |
| `BrandViolet` | `#8B5CF6` | SCI / ΔS |
| `BrandTangerine` | `#FF9300` | Stats / ΔG |
| `BrandFiretruck` | `#F5232B` | Destructive / T |
| `BrandStrawberry` | `#FF2F92` | Grounding / pause |
| `BrandMagnesium` | `#DCDCE4` | Apo baseline / unknown |
| `BrandAqua` | `#00A2FF` | Vibrational / AirPods / music |

## Format that drops straight in

Each `Contents.json` keeps its existing universal entry and gains one carrying:

```json
{ "appearances": [{ "appearance": "luminosity", "value": "dark" }] }
```

with `"color-space": "srgb"` and components as three-decimal strings, matching
the convention already in these files (`BrandFg` is red `0.894`, green `0.890`,
blue `0.961`, alpha `1.000`). Keeping that exact style means zero diff noise.

## Constraints from this side

1. **The approved bloom icon identity is frozen** — warm ivory `#F3EFE7` light,
   midnight indigo `#08091A` dark. Nothing here may alter it.
2. **The palette is quantity-bound.** Mint, violet, tangerine, aqua and
   strawberry carry fixed semantic roles and are never reassigned, so a twin must
   remain recognisably the same role. The generator's hue-within-3° rule already
   gives this.

## Why this matters concretely

Moving the home style-card icons onto `BrandColor.fg` rendered them nearly
invisible on the light home surface, because that token does not adapt. The
icons use `.primary` as a stopgap. See `verification.md`.

## On arrival

1. Drop in the generated colorsets; change no palette values here.
2. Revisit light-surface brand usage, starting with the home style chrome.
3. Add a contract asserting every colorset carries a dark `appearances` entry, so
   the gap cannot silently return.
