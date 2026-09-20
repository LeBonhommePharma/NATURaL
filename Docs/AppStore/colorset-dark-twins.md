# Dark-appearance colorset twins — consumer spec for NATURaL

Status: **APPLIED 20 September 2026.** Consumed from the design-system session (`Derive universal design
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


---

## Applied — 20 September 2026

Consumed from `lebonhommepharma.github.io`, branch `design-system/canonical-source`
(`6724f5a`, `8b7a076`), per `design-system/HANDOFF-NATURAL.md`. Eleven colorsets
taken verbatim; **no values authored here**. `BrandStateFailText` is new.

The producer's guard passes against this catalog:

```
node design-system/check-colorsets.mjs --catalog …/BrandColors.xcassets
→ colorsets: all 11 have a dark twin, every pair is a relighting,
  every half clears AA.   (exit 0)
```

`test_contracts.py` now asserts independently that every colorset carries a dark
twin and that the light value sits in `universal`, so a re-inversion fails the
build. Verified non-tautological: stripping `BrandFg`'s twin fails with
`BrandFg.colorset has no dark appearance twin`.

### Reported back to the producer

Two light halves are **marginally below** WCAG AA and are reported as passing
because both the handoff table and `check-colorsets.mjs` round to two decimals
before comparing:

| colorset | light | reported | actual on `#F3EFE7` |
|---|---|---|---|
| `BrandFgMuted` | `#6B6A8D` | 4.5 / "ok" | **4.4976** |
| `BrandStateFailText` | `#C8373E` | 4.5 / "ok" | **4.4970** |

AA requires ≥ 4.5, so strictly both fail. The gap is a hair and far better than
the inverted state it replaced, so the catalog was applied as-is rather than
held — but `BrandFgMuted` is the muted *small-text* token, which is exactly where
the threshold matters. The fix belongs upstream in the solver and the guard's
comparison, not here; this repo does not author values.

### Still open

- `BrandColor.gold = 0xC4A359` — **zero call sites**, dead. Same off-palette brass
  as the site's `--hp-gold`. MASTER.md line 41 still permits it as thermodynamic
  chrome. Left untouched: it is `public` API on a package, and the handoff marked
  it LP's call. Recommendation: retire it and let ΔG chrome read tangerine
  `#FF9300` (8.86:1), which is what MASTER.md already assigns to ΔG.
- ~~Not compile-verified.~~ **Now compile-verified — answering the handoff's open
  question.** `actool` is still unavailable locally (Command Line Tools only), but
  CI's Xcode 26.6 compiles this catalogue on every push. In
  [CI 35492227384](https://github.com/LeBonhommePharma/NATURaL/actions/runs/35492227384),
  the tvOS job ran:

  ```
  actool …/BrandColors.xcassets --compile …/Release-appletvos
        --notices --warnings --target-device tv --platform appletvos
  ```

  It emitted **no error, warning or notice**: the `com.apple.actool.compilation-results`
  blocks list only output artifacts (`Assets.car`, `GeneratedAssetSymbols.*`), and
  the build succeeded. The same catalogue also compiled clean in the iOS +
  embedded watchOS and native macOS Release jobs. The eleven twinned colorsets are
  therefore verified by Xcode's own compiler on four platforms, not just by
  structural parsing.
