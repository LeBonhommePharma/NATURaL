# PokeDrug: Drug Response via Entropy Collapse Detection

**Final Plan** — NATURaL / Bonhomme

---

## 1. Thesis

A drug binding to an autonomic receptor changes cardiac RR-interval variability.
Shannon entropy — the same formula used in FlexAID∆S molecular docking — detects
that change as an entropy collapse (sympathomimetic) or expansion (parasympathomimetic).
NATURaL becomes an **independent physiological validation** of the FlexAID∆S
configurational entropy framework.

```
FlexAID∆S (in silico)           NATURaL (in vivo)
─────────────────────           ─────────────────────
Torsional angles (°)            RR intervals (ms)
H = -Σ p_i log₂(p_i)           H = -Σ p_i log₂(p_i)    ← identical math
Binding → ΔS_config < 0        Drug → ΔH_hrv < 0        ← identical signal
                    ↘                     ↙
                  EntropyCalculator (shared)
```

---

## 2. Architecture Overview

### 2.1 Module Map

```
BonhommeCore/Sources/BonhommeCore/
├── Analysis/
│   ├── EntropyCalculator.swift          # Shared Shannon engine (linear + circular)
│   ├── HealthSignal.swift               # Protocol + DockingSignal, MedicationSignal, HRVSignal
│   ├── SignalAnalyzer.swift             # Protocol + AnalysisInsight, AnalysisContext
│   ├── FeedbackEngine.swift             # Multi-signal orchestrator
│   ├── HRVAnalyzer.swift                # SCI from RR intervals
│   ├── MedicationAnalyzer.swift         # Adherence scoring
│   ├── DrugResponseAnalyzer.swift       # ΔH detection around dose events
│   ├── PharmacokineticProfile.swift     # 70+ substance PK/autonomic profiles
│   ├── BindingEntropyProfile.swift      # 60+ molecular ΔS_config reference values
│   ├── FlexAIDdSAnalyzer.swift          # Torsional ΔS_config computation
│   ├── CrossDomainValidator.swift       # |ΔS_config| ↔ |ΔH_hrv| (p-values)
│   ├── DockingInsightAnalyzer.swift     # SignalAnalyzer adapter for FeedbackEngine
│   └── … (PokeDrug types/species, selectivity, partition Z, thermodynamics)
├── Consent/
│   └── ClinicalConsent.swift            # Policy-versioned consent + ConsentStore + audit
├── Control/
│   ├── PharmaControlSessionManager.swift
│   ├── CrooksCycleController.swift      # Heuristic σ_irr control (not verified FT)
│   ├── DeltaHRVFlexAIDMapper.swift      # Cross-domain residual → grounding assist
│   ├── ActuatorBus.swift / UniversalBeatSync.swift / … crown · AirPods · breath
│   └── EigenMetalWorkKernel.swift
└── UI/
    └── BreathingGuideView.swift         # Session breath guide (rate from actuators)

Bonhomme/Services/
├── HealthKit/
│   ├── MedicationTracker.swift          # FHIR import + dose logging + response analysis
│   ├── MedicationPrescriptionService.swift  # Consent-gated prescriptions
│   └── InsightEngine.swift              # On-device FM + template insights
├── Music/MusicService.swift             # Dual-path adaptive music + beat lock
├── CareKit/CareKitBridge.swift          # Yoga + medication tasks
└── Persistence/PersistentModels.swift   # WorkoutRecord, DrugResponseRecord, consent mirror
```

### 2.2 Data Flow

```
                    ┌─────────────────────────────────┐
                    │        HealthKit / FHIR          │
                    │  (clinical medication records)    │
                    └──────────────┬───────────────────┘
                                   │
                    ┌──────────────▼───────────────────┐
                    │      MedicationTracker (iOS)      │
                    │  - fetchClinicalMedications()     │
                    │  - logDose()                      │
                    │  - analyzeDrugResponse()          │
                    └──────────────┬───────────────────┘
                                   │
        ┌──────────────────────────┼──────────────────────────┐
        │                          │                          │
        ▼                          ▼                          ▼
 MedicationSignal            DoseEventSummary           RR time series
        │                          │                (fetchRRIntervalsAround)
        │                          │                          │
        ▼                          ▼                          ▼
 FeedbackEngine           DrugResponseAnalyzer ◄─── PharmacokineticProfile
  (multi-signal)           (ΔH detection)                    │
        │                          │                          │
        │                          ▼                          │
        │                 DrugResponseResult ──►──────────────┤
        │                          │                          │
        │                          ▼                          │
        │                 CrossDomainValidator ◄── BindingEntropyProfile
        │                          │           ◄── FlexAIDdSAnalyzer
        │                          ▼
        │                 ValidationResult
        │                 (Pearson r, R², MAE)
        │
        ├──► DockingInsightAnalyzer (if docking data available)
        └──► AnalysisInsight (score, trend, bilingual summary)
```

---

## 3. Implemented Components

### 3.1 EntropyCalculator — Shared Mathematical Core

**File:** `EntropyCalculator.swift` (77 lines)

The cornerstone: a single histogram-binned Shannon entropy engine used identically in
both molecular docking and cardiac physiology.

| Method | Purpose |
|--------|---------|
| `shannonEntropy(_:)` | H = -Σ p_i log₂(p_i) over 32-bin histogram |
| `entropyToScore(_:)` | Map bits → 0–1 coherence score |
| `analyze(_:)` | Combined entropy + score in one call |

### 3.2 DrugResponseAnalyzer — In Vivo Detection

**File:** `DrugResponseAnalyzer.swift` (637 lines)

Detects autonomic drug response from RR-interval entropy changes around dose events.

| Feature | Detail |
|---------|--------|
| **Single dose analysis** | Baseline (30 min pre-dose) vs post-dose windows (15–360 min) |
| **Batch analysis** | Multiple dose events → individual results |
| **Aggregate statistics** | Mean ΔH, SD, Cohen's d, detection rate, AUC |
| **Dose-response curve** | Pearson correlation: dose vs |ΔH| |
| **Profile matching** | Auto-detect best pharmacokinetic match (>50% confidence) |
| **Significance threshold** | |ΔH| ≥ 0.4 bits (2σ above resting noise floor) |

**Result model hierarchy:**

```
DrugResponseResult
├── doseEvent: DoseEventSummary
├── baselineEntropy: Double (bits)
├── measurements: [EntropyMeasurement]     ← time series of post-dose ΔH
├── peakDeltaH: Double                     ← most extreme deviation
├── peakTimeMinutes: Double
├── profileMatch: ProfileMatchResult?
├── bindingDetected: Bool                  ← |peak| ≥ 0.4 bits
├── responseDirection: ResponseDirection   ← collapse / expansion / none
├── effectSize: Double                     ← |ΔH| / baseline
├── deltaHAUC: Double                      ← bits·minutes
├── onsetMinutes: Double?
├── recoveryMinutes: Double?
└── summary: LocalizedString (EN / FR-CA)
```

**Response direction mapping:**

| Direction | ΔH | Mechanism | FlexAID∆S analog |
|-----------|-----|-----------|-----------------|
| `sympathomimeticCollapse` | < -0.4 | RR variability compressed | Torsional entropy loss |
| `parasympathomimeticExpansion` | > +0.4 | RR variability expanded | Conformational relaxation |
| `noSignificantChange` | ±0.4 | Below noise floor | No binding detected |

### 3.3 PharmacokineticProfile — Substance Database

**File:** `PharmacokineticProfile.swift` (~70+ entries)

Each profile contains:

| Field | Type | Purpose |
|-------|------|---------|
| `substanceId` | String | Unique key (lowercase) |
| `name` | LocalizedString | EN / FR-CA |
| `therapeuticClass` | TherapeuticClass | 20 categories |
| `mechanism` | AutonomicMechanism | sympathomimetic / parasympathomimetic / mixed / unknown |
| `tmaxMinutes` | Double | Time to peak plasma concentration |
| `halfLifeMinutes` | Double | Elimination half-life |
| `expectedDeltaHRange` | ClosedRange<Double> | Expected HRV entropy shift (bits) |
| `analysisWindows` | [Double] | Custom post-dose measurement times |
| `fdaApproved` | Bool | Regulatory status |
| `bindingEntropyKcal` | Double? | -TΔS from BindingEntropyProfile |

**Coverage by therapeutic class:**

| Class | Count | Examples |
|-------|-------|---------|
| Stimulants | 8 | amphetamine, methylphenidate, cocaine, caffeine, modafinil |
| Antidepressants | 12 | SSRIs, SNRIs, TCAs, MAOIs, atypicals |
| Antipsychotics | 7 | quetiapine, olanzapine, risperidone, haloperidol, clozapine |
| Anxiolytics / Sedatives | 7 | benzodiazepines, buspirone, zolpidem, suvorexant |
| Opioids | 6 | morphine, oxycodone, fentanyl, buprenorphine, tramadol |
| Beta-blockers | 5 | propranolol, metoprolol, atenolol, bisoprolol, carvedilol |
| Alpha agonists | 2 | clonidine, guanfacine |
| Anticholinergics | 4 | atropine, scopolamine, diphenhydramine, promethazine |
| Anticonvulsants | 6 | gabapentin, pregabalin, lamotrigine, valproate, lithium |
| Cardiovascular | 2 | digoxin, ivabradine |
| NSAIDs / Corticosteroids | 3 | ibuprofen, prednisone, dexamethasone |
| Psychoactive | 7 | ethanol, nicotine, THC, MDMA, psilocybin, LSD, ketamine, GHB |
| Muscle relaxants | 3 | cyclobenzaprine, baclofen, tizanidine |
| GI / Endocrine | 2 | metoclopramide, levothyroxine |
| **Total** | **70+** | |

### 3.4 BindingEntropyProfile — Molecular Reference Database

**File:** `BindingEntropyProfile.swift` (732 lines)

Published and computed configurational entropy values for 60+ substances:

| Field | Purpose |
|-------|---------|
| `rotatableBondCount` | Structural flexibility proxy |
| `expectedDeltaSBits` | ΔS_config in bits (negative = binding constrains) |
| `expectedEntropyPenaltyKcal` | -TΔS at 298K in kcal/mol |
| `reference` | Literature citation |

**Key relationship:** More rotatable bonds → larger |ΔS_config| → larger entropy penalty.

Sources: Chang & Gilson JACS 2004, Mobley & Gilson 2017, Ruvinsky 2007, FlexAID∆S validation runs, Whitesides & Krishnamurthy 2005 heuristic (~0.5–0.7 kcal/mol per frozen bond).

### 3.5 FlexAIDdSAnalyzer — In Silico Entropy

**File:** `FlexAIDdSAnalyzer.swift` (343 lines)

Computes ΔS_config from torsional angle distributions using the **same** EntropyCalculator.

| Method | Purpose |
|--------|---------|
| `entropy(of:)` | Single bond Shannon entropy |
| `analyze(freeConformation:dockingPose:)` | Full ligand ΔS_config with per-bond results |
| `analyzeBatch(...)` | Multiple poses, sorted by |ΔS| descending |
| `entropyPenaltyKcal(deltaSBits:)` | Bits → kcal/mol at given T |
| `kcalToDeltaSBits(penaltyKcal:)` | Inverse conversion |

**Significance threshold:** |ΔS_config| ≥ 0.5 bits.

**Energy conversion:** -TΔS = -T × ΔS_bits × R × ln(2), where R = 1.987×10⁻³ kcal/(mol·K).

At 298K: 1 bit ≈ 0.41 kcal/mol.

### 3.6 CrossDomainValidator — The Bridge

**File:** `CrossDomainValidator.swift` (315 lines)

Tests the core hypothesis: |ΔS_config| correlates with |ΔH_hrv|.

| Mode | Input | Fallback |
|------|-------|----------|
| `validate(...)` | Actual FlexAIDdSResult + DrugResponseResult | Requires ≥3 pairs |
| `validateFromProfiles(...)` | BindingEntropyProfile + DrugResponseResult | Uses published ΔS |
| `validateHybrid(...)` | Both sources | Docking preferred, profile fallback |

**Output (ValidationResult):**

| Metric | Interpretation |
|--------|---------------|
| `pearsonR` | Correlation between |ΔS_config| and |ΔH_hrv| |
| `rSquared` | Variance explained by in-silico entropy |
| `meanAbsError` | Prediction accuracy (bits) |
| `regressionSlope` | Scaling factor: molecular → physiological |
| `isSignificant` | r > 0.5 AND n ≥ 5 |

A significant positive correlation **validates** that entropy collapse generalizes from molecular torsional angles to cardiac intervals.

### 3.7 DockingInsightAnalyzer — FeedbackEngine Integration

**File:** `DockingInsightAnalyzer.swift` (131 lines)

Bridges FlexAID∆S results into the multi-signal FeedbackEngine:

- Ingests `DockingSignal` via `.molecularDocking` signal type
- Produces `AnalysisInsight` with score (|ΔS|/5.0 normalized), trend, status
- Cross-references with active medication context for correlation notes

### 3.8 MedicationTracker — iOS Integration Layer

**File:** `MedicationTracker.swift` (277 lines)

The iOS service that ties everything together:

| Method | Purpose |
|--------|---------|
| `fetchClinicalMedications()` | Import FHIR medication records from HealthKit |
| `logDose(...)` | Manual dose entry → MedicationSignal → FeedbackEngine |
| `analyzeDrugResponse(...)` | Single dose: query RR intervals → DrugResponseAnalyzer |
| `analyzeDrugResponseHistory(...)` | All doses for a med → DrugResponseAggregate |
| `fetchHRVAroundDose(...)` | HealthKit HRV samples ±30 min / +2 hr |
| `fetchRRIntervalsAround(...)` | Synthetic RR from HR samples (HR → 60000/bpm) |

---

## 4. Signal Types and Protocol Hierarchy

```swift
HealthSignal (protocol: Codable, Sendable)
├── HRVSignal           → .heartRateVariability    → HRVAnalyzer
├── MedicationSignal    → .medication              → MedicationAnalyzer
├── SurveySignal        → .survey                  → (extensible)
└── DockingSignal       → .molecularDocking        → DockingInsightAnalyzer
                                                          ↓
                                                    FeedbackEngine
                                                    (cross-signal orchestration)
```

---

## 5. Test Coverage

### 5.1 DrugResponseAnalyzerTests (24 tests)

| Test | Validates |
|------|-----------|
| Amphetamine entropy collapse | Sympathomimetic → ΔH < -0.4, direction match, profile match |
| Caffeine mild collapse | Smaller |ΔH| than amphetamine |
| Propranolol entropy expansion | Beta-blocker → ΔH > 0 |
| Inert substance no change | Placebo → |ΔH| < 0.4 |
| Morphine vagotonic expansion | Opioid → ΔH > 0 |
| Atropine vagal brake removal | Anticholinergic → strong collapse |
| Alprazolam GABAergic expansion | Benzodiazepine → ΔH > 0 |
| Venlafaxine SNRI collapse | NE reuptake inhibition → ΔH < 0 |
| Auto profile detection | Unknown substance → correct class match |
| Direction match classification | Correct/incorrect direction validation |
| Batch analysis & aggregation | 3 doses → mean ΔH, Cohen's d, detection rate |
| Dose-response correlation | Higher dose → larger |ΔH|, Pearson r > 0.9 |
| Insufficient baseline → nil | Edge case: < 20 RR intervals |
| No post-dose data → nil | Edge case: missing observation window |
| Custom measurement windows | Honors user-specified time points |
| Effect size & AUC | 0 < effectSize ≤ 1, AUC < 0 for collapse |
| Onset & recovery detection | Temporal landmarks |
| Profile registry completeness | 70+ profiles, unique IDs |
| Profile lookup by class | Stimulants = sympathomimetic, BBs = parasympathomimetic |
| FDA approved filter | Regulatory status correctness |
| Entropy calculator parity | Uniform → high H, concentrated → low H, ΔH > 3 bits |
| Multi-class discrimination | Stimulant/BB/placebo correctly classified by entropy alone |
| Summary generation | EN/FR bilingual, contains ΔH, direction, units |
| Aggregate statistics summary | n, Cohen's d, detection rate in text |

### 5.2 FlexAIDdSAnalyzerTests (27 tests)

| Test | Validates |
|------|-----------|
| Free rotation high entropy | ±180° → H > 3 bits |
| Constrained low entropy | ±10° → H < 2 bits |
| ΔS negative for binding | H_bound - H_free < -1 bit |
| Multi-bond total entropy | 5 bonds, total = sum of per-bond |
| Bond count mismatch → nil | Defensive edge case |
| Rigid ligand minimal ΔS | Already constrained → small |ΔS| |
| Flexible ligand large ΔS | 8 bonds wide→narrow → |ΔS| > 5 bits |
| Most/least constrained bond | Correct identification |
| Entropy penalty kcal conversion | 1 bit ≈ 0.41 kcal/mol at 298K |
| Temperature dependence | Higher T → larger penalty |
| Batch analysis sorted by ΔS | Descending |ΔS| order |
| Cross-domain correlation | Synthetic data: r > 0.9 |
| Validate from profiles | BindingEntropyProfile + synthetic ΔH → r > 0.8 |
| Insufficient pairs → nil | < 3 substances |
| Binding entropy profile uniqueness | All IDs unique |
| Profile cross-reference | Every BindingEntropyProfile ↔ PharmacokineticProfile |
| Rotatable bond ↔ ΔS correlation | More bonds → larger |ΔS| |
| DockingSignal ingestion | FeedbackEngine accepts without crash |
| DockingInsightAnalyzer insight | Score > 0, summary contains ΔS and kcal/mol |
| Empty signals → graceful nil | No data → nil score, informative message |
| Full pipeline cross-reference | DockingSignal + MedicationSignal → correlate |
| Entropy calculator parity | Same input → same output across domains |
| Score mapping consistency | Low H → high score, high H → low score |
| Summary binding detection | "penalty detected" / "détectée" |
| Summary no binding | "No significant" |
| Validation result summary | n, r, R², MAE in EN/FR |
| Profiles with binding entropy | 20+ profiles with kcal data |

---

## 6. Mathematical Foundation

### 6.1 Shannon Entropy

```
H = -Σ p_i log₂(p_i)     where p_i = bin_count_i / total_count
```

32-bin histogram. Max theoretical entropy = log₂(32) = 5 bits (uniform).
Practical max with noise ≈ 4.5–5.0 bits.

### 6.2 Entropy Collapse Detection

```
Baseline:    H_pre  = entropy(RR intervals in [-30 min, 0])
Post-dose:   H_post = entropy(RR intervals in window ± 5 min)
Delta:       ΔH = H_post - H_pre
Binding:     |ΔH| ≥ 0.4 bits (2σ above resting noise)
```

### 6.3 Profile Matching

Confidence score (0–1) with weighted components:

| Component | Weight | Criterion |
|-----------|--------|-----------|
| Direction | 40% | ΔH sign matches mechanism (negative = sympathomimetic) |
| Magnitude | 35% | |ΔH| within profile's expectedDeltaHRange |
| Timing | 25% | Peak time within ±50% of Tmax |

### 6.4 Cross-Domain Energy Conversion

```
-TΔS (kcal/mol) = -T × ΔS_bits × R × ln(2)

At T = 298K, R = 1.987 × 10⁻³ kcal/(mol·K):
    1 bit ≈ 0.41 kcal/mol entropy penalty
```

### 6.5 Statistical Validation

| Metric | Formula | Threshold |
|--------|---------|-----------|
| Pearson r | Σ(x-x̄)(y-ȳ) / √[Σ(x-x̄)²·Σ(y-ȳ)²] | r > 0.5 |
| Cohen's d | |mean(ΔH)| / SD(ΔH) | d > 0.8 = large |
| Detection rate | n(|ΔH| ≥ 0.4) / n(total) | — |
| AUC | Trapezoidal integration of ΔH(t) | bits·minutes |

---

## 7. Substance Coverage Matrix

### 7.1 Full Coverage (PK + binding entropy + expected ΔH)

Amphetamine, methylphenidate, cocaine, modafinil, caffeine, theophylline,
propranolol, metoprolol, atenolol, clonidine, sertraline, fluoxetine,
venlafaxine, quetiapine, olanzapine, haloperidol, alprazolam, diazepam,
lorazepam, morphine, oxycodone, fentanyl, gabapentin, lithium, ethanol,
nicotine, atropine, lisdexamfetamine, dextroamphetamine, methamphetamine,
armodafinil, atomoxetine, bisoprolol, carvedilol, guanfacine, digoxin,
ivabradine, escitalopram, paroxetine, duloxetine, bupropion, mirtazapine,
trazodone, amitriptyline, nortriptyline, phenelzine, tranylcypromine,
risperidone, aripiprazole, chlorpromazine, clozapine, clonazepam, buspirone,
hydroxyzine, zolpidem, suvorexant, hydrocodone, methadone, buprenorphine,
tramadol, naltrexone, pregabalin, lamotrigine, valproate, carbamazepine,
topiramate, diphenhydramine, promethazine, scopolamine, ibuprofen, prednisone,
dexamethasone, metoclopramide, levothyroxine, cyclobenzaprine, baclofen,
tizanidine, THC, dronabinol, MDMA, psilocybin, LSD, ketamine, GHB

---

## 8. Related Projects

| Project | Relationship |
|---------|-------------|
| [Shannon](https://github.com/LeBonhommePharma/Shannon) | Mathematical foundation: entropy collapse detection framework |
| [FlexAID∆S](https://github.com/LeBonhommePharma/FlexAIDdS) | Molecular docking entropy that PokeDrug validates physiologically |
| NATURaL / Bonhomme | Host application: chair yoga with HRV biofeedback |

---

## 9. Design Principles

1. **One EntropyCalculator, two domains.** The same 32-bin Shannon engine computes
   entropy for molecular torsional angles and cardiac RR intervals. No domain-specific
   math exists — the mathematical identity (Jaynes 1957) is enforced by shared code.

2. **Protocol-driven extensibility.** `HealthSignal` → `SignalAnalyzer` → `FeedbackEngine`
   allows adding new signal types (sleep, respiratory, activity) without modifying existing code.

3. **Zero external dependencies.** All math (entropy, correlation, regression, AUC) is
   implemented inline. No NumPy, no R, no third-party stats libraries.

4. **Bilingual from day one.** Every user-facing string is `LocalizedString(en:, fr:)`.
   Summaries, insights, and pose names all resolve by device locale.

5. **Sendable throughout.** All analysis types are `Sendable` and value types (structs/enums).
   Thread safety is structural, not guarded.

6. **Pharmacological ground truth.** Substance profiles cite published literature
   (Chang & Gilson 2004, Mobley & Gilson 2017, Ruvinsky 2007) rather than estimates.

---

## 10. Status — Shipped vs Remaining

Honest inventory against current code (PokéDrug branch). Analysis math was already
complete; integration layers below have largely landed. Only remaining product gaps
are called out as **Remaining**.

### 10.1 Persistence — ✅ Shipped

`DrugResponseRecord` is a SwiftData `@Model` in `PersistentModels.swift`, registered
in the app ModelContainer / CloudKit fallback path. `SummaryView` persists a record
when a `DrugResponseResult` is present (medication id, peak ΔH, direction, AUC,
profile match, etc.).

### 10.2 App Lifecycle — ✅ Shipped

- `AppState` owns app-wide `FeedbackEngine`, `MedicationTracker`, and
  `MedicationPrescriptionService`.
- Analyzers registered at init: `HRVAnalyzer`, `MedicationAnalyzer`,
  `DockingInsightAnalyzer`.
- Workout VMs accept the shared engine (session signals no longer isolated by default).

### 10.3 Consent prescriptions — ✅ Shipped

- `ClinicalConsent` + `ConsentStore` (policy-versioned grant/revoke, audit log).
- `MedicationPrescriptionService`: consent → HealthKit clinical import / manual entry
  → CareKit med tasks. Clinical reads are blocked without valid consent.
- `PrescriptionsView` UI (consent toggle, sync, schedules, audit).

### 10.4 FlexAID / cross-domain — ✅ Shipped (library + session control)

- `FlexAIDdSAnalyzer`, `BindingEntropyProfile`, `CrossDomainValidator` (p-values,
  n ≥ 5), circular torsional entropy, docking insight path through FeedbackEngine.
- Crooks control stack (`Control/`): `PharmaControlSessionManager` →
  `CrooksCycleController` (heuristic σ_irr — **not** a verified FT estimator) →
  `DeltaHRVFlexAIDMapper` residual + `ActuatorBus` (beat, crown β, breathing, log).
- Wired on iOS workout ticks and watchOS session / crown path.

### 10.5 UI / Visualization — 🟡 Partial

**Shipped:**
- Summary `drugResponseCard` (peak ΔH, direction, binding flag).
- Prescriptions UI; workout breathing overlay; Crooks metrics on Watch session.

**Remaining:**
- Full ΔH time-series chart (post-dose windows)
- Dose–response scatter (dose vs |ΔH|)
- Medication entropy history timeline
- Cross-domain plot (|ΔS_config| vs |ΔH_hrv|)

### 10.6 InsightEngine (Foundation Models) — 🟡 Partial / ✅ core path

**Shipped:**
- On-device-only FM path (iOS 26+), template fallback otherwise.
- Multi-signal narratives include HRV, medication, survey, **and** `.molecularDocking`.
- Pose cue resolve: model → cache → SCI-aware template → static voice cue.
- Template cross-notes for med adherence × SCI and docking × HRV.

**Remaining:**
- Explicit `DrugResponseResult` (post-dose ΔH curve) injection into prompts
- Richer “dose + expected sympathomimetic profile” narratives beyond docking insight

### 10.7 Siri / App Intents — ❌ Remaining (stub)

- `GetAdherenceIntent` still returns a static “available in the app” dialog.
- No intents for last drug response, medication entropy history, or aggregates.

### 10.8 Adjacent shipped product (not PokeDrug-only, documented for sync)

| Area | Status | Notes |
|------|--------|--------|
| Multi-kind workouts | ✅ | `WorkoutKind` = `YogaStyle`; 15 kinds (yoga + strength/cardio/mobility/meditation/general) with per-kind plans + Crooks nominal BPM |
| Breathing | ✅ | `BreathingGuideView` / overlay; rate from `BreathingGuideActuatorChannel`; Watch haptics |
| Dual-path music | ✅ | Local dual-player crossfade **or** MusicKit (iOS 18+ transition / iOS 17 gap fallback) + UniversalBeatSync rate lock |
| README | ✅ | Main README documents PokeDrug, FlexAID bridge, multi-kind, Crooks, consent, breathing, dual-path music |

### 10.9 Roadmap (remaining only)

1. Drug-response charts (ΔH series, dose–response, cross-domain scatter)
2. `DrugResponseResult` → InsightEngine prompt path
3. Non-stub Siri intents for response / entropy history
4. Optional: history browser for `DrugResponseRecord` list queries

---

## 11. Research Quality Enhancements

Enhancements to improve scientific rigor and numerical robustness.

### 11.1 Circular Entropy for Torsional Angles

**Problem:** Torsional angles are circular [-180°, +180°], but `EntropyCalculator.shannonEntropy` used data-adaptive linear binning. Angles -179° and +179° (2° apart physically) were histogram-binned ~358° apart, underestimating entropy for wrapped distributions.

**Fix:** Added `circularShannonEntropy(_:)` to EntropyCalculator with fixed bins spanning [-180°, +180°), wrapping inputs via modular arithmetic. `FlexAIDdSAnalyzer` now uses circular entropy for all torsional angle computations while `DrugResponseAnalyzer` continues using linear entropy for RR intervals (correct for linear domains).

**File:** `EntropyCalculator.swift`, `FlexAIDdSAnalyzer.swift`

### 11.2 Statistical Significance Testing (p-values)

**Problem:** `CrossDomainValidator` declared correlations "significant" when r > 0.5, but at n=5, r=0.5 has p ≈ 0.39 (not significant). The minimum pair count of 3 was too small for meaningful inference.

**Fix:** Added proper p-value computation via t-distribution (t = r × √(n-2) / √(1-r²)) using the regularized incomplete beta function (Lentz's continued fraction). `ValidationResult.isSignificant` now requires p < 0.05 AND n ≥ 5. Minimum pairs raised from 3 to 5.

**File:** `CrossDomainValidator.swift`

### 11.3 Centralized AnalysisConfiguration

**Problem:** 12+ hardcoded thresholds scattered across 5 source files with no central configuration.

**Fix:** Created `AnalysisConfiguration` struct consolidating all thresholds (histogram bins, significance levels, Cohen's d cap, normalization constants). All analyzers accept optional configuration via new `init(configuration:)` with backward-compatible defaults.

**File:** `AnalysisConfiguration.swift` (new), all analyzer files modified

### 11.4 Numerical Robustness

- **NaN/infinity guards:** `EntropyCalculator` filters non-finite values before computation. Pearson correlation in both `CrossDomainValidator` and `DrugResponseAnalyzer` filters non-finite pairs.
- **Cohen's d cap:** Capped at 10.0 (was `.infinity` when SD = 0). Values above 10 are not meaningfully interpretable.

### 11.5 New Test Coverage

| Test File | Tests Added | Coverage |
|-----------|------------|----------|
| `EntropyCalculatorTests.swift` (new) | 10 | Circular wraparound, uniform, NaN filtering, edge cases |
| `CrossDomainValidatorTests.swift` (new) | 13 | p-value accuracy, minimum pairs, hybrid validation, NaN handling |
| `FlexAIDdSAnalyzerTests.swift` | +1 | Circular entropy for boundary angles |
| `DrugResponseAnalyzerTests.swift` | +2 | Cohen's d capping |

**Total test count:** 51 → 77 (26 new tests)

## 12. Summary

PokeDrug bridges computational chemistry and wearable health monitoring through a single
mathematical principle: Shannon entropy measures the cost of binding — whether a ligand
locking into a receptor pocket (ΔS_config) or a drug compressing cardiac rhythm variability
(ΔH_hrv).

**Shipped:** 70+ PK profiles, 60+ binding entropy refs, circular torsional entropy,
CrossDomainValidator (p < 0.05, n ≥ 5), app-wide FeedbackEngine + MedicationTracker +
DockingInsightAnalyzer, consent-gated prescriptions, SwiftData `DrugResponseRecord`,
Crooks-inspired session control with FlexAID residual mapping, breathing actuators,
dual-path adaptive music, multi-kind workouts, and on-device Foundation Models insights
(with template fallback). Unit tests cover entropy, analyzers, consent, and Crooks control.

**Remaining (product polish):** rich drug-response charts, deeper DrugResponseResult
narratives in InsightEngine, and non-stub Siri intents for response history.

The framework is ready for real-world validation: collect Apple Watch RR intervals around
medication doses, run DrugResponseAnalyzer, persist results, and correlate |ΔH_hrv|
against |ΔS_config| via CrossDomainValidator.
