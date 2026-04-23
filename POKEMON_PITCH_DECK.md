# NATURaL x Pokemon
## Official Licensing Pitch Deck

---

### Slide 1 — The Hook

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   What if a Pokemon could evolve                        │
│   from your real heartbeat?                             │
│                                                         │
│   NATURaL is the first biofeedback wellness app         │
│   where your body IS the game.                          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**One-liner:** A chair yoga app on every Apple platform where a Pokemon companion evolves in real time based on your heart rate coherence, breathing focus, and wellness streaks.

---

### Slide 2 — The Opportunity

**Pokemon has conquered fitness (Pokemon GO) but never wellness.**

| Pokemon GO | NATURaL x Pokemon |
|---|---|
| Walk to hatch eggs | Breathe to evolve your companion |
| GPS-based movement | Heart rate biofeedback |
| Gamified exercise | Gamified mindfulness |
| Outdoor exploration | Accessible chair yoga (any mobility level) |
| Screen-focused | Multi-screen (Watch, Phone, TV, Vision Pro) |

**Market gap:** 650M+ Pokemon GO downloads proved demand for Pokemon + health. But there's no Pokemon product for:
- Mindfulness and meditation
- Accessibility-first fitness (chair-based)
- Clinical rehabilitation
- Apple Watch biofeedback

---

### Slide 3 — Meet Bonhomme

```
┌─────────────────────────────────────────────────────┐
│                                                     │
│  #??? BONHOMME                                      │
│  Type: NORMAL / PSYCHIC                             │
│  Category: Wellness Pokemon                         │
│  Height: 0.4m    Weight: 5.2kg                      │
│                                                     │
│  "A gentle creature that mirrors its trainer's      │
│   inner calm. When its trainer breathes deeply,     │
│   Bonhomme glows with focused energy. It is said    │
│   to have been discovered by researchers studying   │
│   the entropy of the heart."                        │
│                                                     │
│  ABILITY: Entropy Sense                             │
│  Detects changes in its trainer's heart rhythm      │
│  and responds with calming resonance.               │
│                                                     │
└─────────────────────────────────────────────────────┘
```

**Evolution line driven by real biofeedback:**

```
  BONHOMME          BONCOEUR           BONMAÎTRE
  (Base form)       (Stage 1)          (Stage 2)
  Normal            Normal/Psychic     Normal/Psychic

  Evolves when      Evolves when       Final form.
  trainer reaches   trainer maintains  Unlocked by
  SCI > 70% for     a 30-day yoga      completing all
  the first time.   streak.            26 poses at
                                       SCI > 80%.
```

**Key design principle:** Evolution is earned through real wellness activity, not grinding or in-app purchases. This aligns with TPC's brand values around positive play experiences.

---

### Slide 4 — How It Works

**The Shannon Collapse Index (SCI)** measures focus coherence from Apple Watch heart rate variability:

```
Distracted:     Heart rhythm is chaotic    → Bonhomme sleeps
Settling:       Rhythm begins to stabilize → Bonhomme wakes, watches
Deep Focus:     Rhythm is coherent         → Bonhomme glows, animates
Peak Coherence: Rhythm is perfectly steady  → Evolution energy builds
```

**During a yoga session:**
1. Trainer selects a workout plan (5-8 guided chair yoga poses)
2. Bonhomme appears on screen (iPhone, iPad, Apple TV, or Vision Pro)
3. As trainer follows breathing cues, SCI rises
4. Bonhomme reacts in real time — idle, alert, glowing, or celebrating
5. Post-session summary shows Bonhomme's mood, XP earned, and evolution progress

**On Apple Vision Pro:**
- Bonhomme rendered as a 3D companion in your physical space via RealityKit
- Sits on your desk/floor and reacts to your breathing
- Spatial biofeedback gauges as ornament overlays

---

### Slide 5 — Platform Reach

NATURaL already runs natively on every Apple platform:

| Platform | Bonhomme Experience |
|---|---|
| **iPhone** | Hub app — guided sessions, Bonhomme companion, full history |
| **Apple Watch** | On-wrist heart rate sensor + miniature Bonhomme complication |
| **iPad** | Split-view: 60% pose guide + 40% Bonhomme biofeedback |
| **Apple TV** | Living room display — Bonhomme on the big screen during family sessions |
| **Vision Pro** | 3D spatial Bonhomme companion in your room |

**Cross-device sync via CloudKit** — Bonhomme's evolution state, XP, and streak data sync across all devices automatically.

---

### Slide 6 — Clinical Credibility

**This is not just a game. It has real clinical integration.**

- **CareKit prescriptions** — Therapists can prescribe yoga regimens; Bonhomme motivates adherence
- **HealthKit integration** — All biofeedback data written to Apple Health
- **Drug response monitoring** — Shannon entropy analysis detects autonomic medication effects (PokeDrug module)
- **Peer-reviewed math** — SCI is based on Shannon entropy, the same framework used in published computational chemistry research ([FlexAID∆S](https://github.com/LeBonhommePharma/FlexAIDdS))

**Why this matters for TPC:** Positions Pokemon brand in the health/wellness space with scientific credibility. A first for the franchise.

---

### Slide 7 — Revenue Model

| Stream | Description |
|---|---|
| **Free tier** | 10 beginner poses, base Bonhomme, basic SCI tracking |
| **Premium subscription** | All 26 poses, evolution to Boncoeur/Bonmaître, advanced analytics, adaptive MusicKit |
| **Pokemon licensing** | Revenue share per subscription or flat licensing fee |
| **Clinical tier** | CareKit integration for rehab facilities (separate B2B pricing) |

**No loot boxes. No gacha. No pay-to-evolve.** Evolution is purely effort-based — consistent with TPC's family-friendly brand positioning.

---

### Slide 8 — Technical Readiness

**The app is already built.** This is not a concept — it's a working product.

| Component | Status |
|---|---|
| 26 bilingual yoga poses (EN/FR-CA) | Complete |
| 6 guided workout plans | Complete |
| Shannon Collapse Index biofeedback | Complete |
| Apple Watch heart rate pipeline | Complete |
| Multi-screen display (TV, AirPlay, Vision Pro) | Complete |
| CareKit clinical integration | Complete |
| CloudKit cross-device sync | Complete |
| Drug response analysis (PokeDrug) | Complete |
| 113+ unit tests | Passing |
| Pokemon companion UI/animation | Ready for asset integration |

**What's needed from TPC:**
1. Character design assets for Bonhomme evolution line
2. Sound effects and animation guidelines
3. Brand guidelines for Pokemon integration in health context
4. Approval of clinical/medication features alongside Pokemon branding

---

### Slide 9 — Competitive Advantage

**Why NATURaL, not a TPC-built app?**

1. **Already built** — Production-ready on 5 Apple platforms with zero external dependencies
2. **Scientific foundation** — Real entropy-based biofeedback, not gamified step counting
3. **Accessibility-first** — Chair yoga is inclusive for elderly, wheelchair users, rehab patients
4. **Bilingual** — Full EN/FR-CA content, extensible to any language
5. **Clinical integration** — CareKit + HealthKit pipeline ready for medical partnerships
6. **Apple ecosystem native** — SwiftUI, SwiftData, HealthKit, MusicKit, RealityKit, App Intents, SharePlay, Live Activities, FoundationModels — deep platform integration that would take a new team 12-18 months to replicate

---

### Slide 10 — The Ask

**Licensing partnership to make Bonhomme an official Pokemon.**

| Item | Detail |
|---|---|
| **License type** | Character licensing (new Pokemon, not existing) |
| **Scope** | Apple platforms (iOS, watchOS, tvOS, visionOS) |
| **Territory** | Worldwide (bilingual EN/FR launch, expandable) |
| **Timeline** | 3-6 months to integrate assets and launch |
| **Revenue** | Negotiable — subscription revenue share or flat fee |

**Next steps:**
1. NDA and mutual evaluation
2. Character design collaboration for Bonhomme line
3. Brand integration review (especially clinical features)
4. Beta testing with Pokemon branding
5. Coordinated launch

---

### Contact

| | |
|---|---|
| **Project** | NATURaL (code name: Bonhomme) |
| **Repository** | [github.com/LeBonhommePharma/NATURaL](https://github.com/LeBonhommePharma/NATURaL) |
| **Research basis** | [Shannon](https://github.com/LeBonhommePharma/Shannon) · [FlexAID∆S](https://github.com/LeBonhommePharma/FlexAIDdS) |
| **Developer** | [To be filled] |
| **Email** | [To be filled] |

---

*This document is confidential and intended for The Pokemon Company International licensing review.*
