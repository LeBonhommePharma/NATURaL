# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/natural/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** NATURaL (Bonhomme) — chair yoga + biofeedback
**Generated:** 2026-09-17 01:37:01 (ui-ux-pro-max persist)
**Brand override:** FlexAIDΔS v2 tokens from `BrandColor` / thebonhomme.com/tokens.css. The tool’s sage/teal wellness palette is **not** used.
**Category:** Chair yoga, breath, Shannon Collapse Index (SCI)
**Design Dials:** Variance 3/10 (Centered / Minimal) | Motion 3/10 (Subtle) | Density 4/10 (Spacious session, not a dashboard)
**Stack:** SwiftUI. SF Pro maps the Lora/Raleway wellness pairing. Metrics use SF Mono (`SessionType.metric`).
**Design coverage:** iPhone, iPad, watchOS, macOS, tvOS and visionOS. iPhone/iPad/Watch and the existing native Mac target are in App Store preparation at LP’s request (19 September 2026). tvOS is also explicitly in the App Store release scope, including pairing, large-screen kinematics/HUD, icons, packaging and device validation. Vision retains its companion design; its distribution readiness is tracked separately. Native Mac is guided movement without a live Health feed.

---

## Global Rules

### Color Palette (quantity-bound — never reassigned)

| Role | Hex | Token | Quantity |
|------|-----|-------|----------|
| Background / page ink | `#08091A` | `--color-background` / `BrandColor.bg` | Surface |
| Panel | `#111226` @ 92% | `BrandColor.bgPanel` | Surface |
| Card | `#111226` @ 82% | `BrandColor.bgCard` | Surface |
| Foreground | `#E4E3F5` | `--color-foreground` / `BrandColor.fg` | 15.60:1 on ink |
| Muted | `#8D8CB0` | `BrandColor.fgMuted` | 6.12:1 on ink |
| Primary CTA / pass / ΔH | `#45E0A8` | `--color-accent` / `BrandColor.mint` | Enthalpy |
| SCI / ΔS | `#8B5CF6` | `BrandColor.violet` | Configurational entropy |
| Stats / ΔG | `#FF9300` | `BrandColor.tangerine` | Free energy |
| Gold chrome (optional) | `#C4A359` | thermodynamic family | Not a CTA; never replace mint |
| Destructive / T | `#F5232B` | `BrandColor.firetruck` | Temperature fail |
| Warn / receptor | `#FF2F92` | `BrandColor.strawberry` | Grounding / pause |
| Apo baseline | `#DCDCE4` | `BrandColor.magnesium` | Unknown / waiting |
| Vibrational | `#00A2FF` | `BrandColor.aqua` | AirPods / music |

**Approved icon direction (19 September 2026):** Preserve the jewel bloom. Light appearance uses warm ivory `#F3EFE7`; dark appearance uses website midnight indigo `#08091A` with a subtle violet lift to soften the contrast. Approved exports and the original are retained in `assets/approved/`. iOS supports system dark icon appearance; legacy macOS/watchOS catalogs use the ivory default. Layered tvOS/visionOS delivery is tracked separately.

**Color Notes:** Midnight indigo + jewel bloom. Gold is allowed as thermodynamic chrome. Do not restyle NATURaL as Exergy (usage tracker) or a generic spa app.

Light appearance twins live in `BrandColors.xcassets`. **Session HUD always reads the sRGB values above** so SCI / ΔH / ΔG stay identical across themes.

### Typography

- **Heading / body:** SF Pro (Apple HIG). Tool recommendation Lora + Raleway is wellness mood only.
- **Metrics / SCI / BPM / countdown:** SF Mono via `SessionType.metric`.
- **Dynamic Type:** use text styles (`.body`, `.title`, `.caption`), not fixed `system(size:)` except Watch glance numerals that already `minimumScaleFactor`.
- **Mood:** calm, precise, breath, chair yoga — not clinical, not a crypto dashboard.

### Spacing (`SessionSpacing` — 8pt grid)

Density dial 4 maps to the existing HUD scale, not a dense dashboard.

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 4 | Chip internals |
| `xs` | 8 | Icon gaps, Watch rows |
| `sm` | 12 | HUD stack |
| `md` | 16 | Phone padding |
| `lg` | 24 | iPad / TV gutters |
| `xl` | 32 | iPad session |
| `xxl` | 40 | Split columns |
| `minTapTarget` | 44 | All hits (Watch too) |
| `phoneControlHeight` | 52 | Pause / End |

### Radii (`SessionRadius`, continuous)

chip 10 · control 16 · card 22 · panel 26 · sheet 34

### Motion (`SessionMotion`, dial 3)

- Micro: 180–220ms ease-out.
- SCI ring: spring only when Reduce Motion is off.
- Decorative `TimelineView` breath loops **pause** when `accessibilityReduceMotion` is true.
- Never animate layout width/height. Never bounce on Watch.

### Icons

Outline/hierarchical **SF Symbols** only. No emoji as chrome. Entropy states use `SessionEntropyState.symbolName` (`leaf.fill`, `wind`, `eye.fill`, `checkmark.circle.fill` — not 🎨/🔥).

---

## Component Specs (SwiftUI)

### Primary CTA

`SessionBeginButton` / `.sessionProminentButtonStyle()` · mint fill · 52pt phone height · label "Begin Session".

### Session HUD

Phone: `SessionHUDBar` in the thumb-zone inset (SCI + HR first, chips, pose progress last).
iPad / TV: `SessionHUDPanel` inspector (gauges on, TV `spaciousChips: true`).
Watch: `SessionGlanceStrip` + vertical `TabView` pages.
visionOS: same metrics via `SessionHUDMetrics` in the trailing ornament — never invent cyan/orange SCI.

Unknown SCI/HR renders `—`, never `0`. Grounding always wins the entropy chip.

### Controls

Pause/Resume + End · `session.pauseResume` / `session.end` · 44pt minimum · destructive End is strawberry/firetruck, not greyed fake taps.

### Scrim

Pause overlay: ultra-thin material, `allowsHitTesting(false)` so controls stay tappable. Scrim ~50% black equivalent.

---

## Anti-Patterns (Do NOT Use)

- ❌ Sage/teal spa palette or Exergy menu-bar chrome
- ❌ Emoji as icons or navigation
- ❌ Raw `Color.cyan` / `.green` / `.orange` for SCI or HR
- ❌ Showing used-progress as “SCI %” when the value is unavailable (must be `—`)
- ❌ Hover-only affordances (this is a native app)
- ❌ Decorative infinite motion when Reduce Motion is on
- ❌ Medical diagnosis copy from SCI
- ❌ Paywalls / `SubscriptionStoreView`
- ❌ CloudKit / iCloud KVS for health records
- ❌ Inventing Android / web App Store targets or claiming unvalidated Apple targets are ready

---

## Pre-Delivery Checklist

- [ ] SF Symbols only (no emoji chrome)
- [ ] Hits ≥44pt; 8pt gaps
- [ ] Reduce Motion pauses breath/glow loops
- [ ] Dynamic Type: session controls remain reachable
- [ ] Contrast: fg on bg ≥4.5:1 (lock `#E4E3F5` on `#08091A`)
- [ ] Safe areas: phone HUD in `safeAreaInset`; Watch digital crown does not cover End
- [ ] SCI honesty: non-finite → unknown; grounding wins
- [ ] Privacy manifests: tracking false, collected types empty
