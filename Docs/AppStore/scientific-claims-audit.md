# Scientific claims and provenance audit

Audit date: 2026-09-19. Baseline: `c216e66`; this report accompanies source changes awaiting integration. This is a source-level release audit, not verification of the embedded scientific dataset against original experiments.

## Reachable release surfaces

- `Bonhomme/Features/Prescriptions/PrescriptionsView.swift` links both imported prescriptions and manual schedules to `PokeDrugSubstanceInsightView` after clinical-data consent. The destination is not confined to Debug.
- `Bonhomme/Services/HealthKit/MedicationTracker.swift` analyzes timestamped RR data around logged doses, keeps one response per medication ID, and calls `validateFromProfiles`. Its molecular values therefore come from the bundled catalog, not a docking run performed for that session.
- `Bonhomme/Services/HealthKit/InsightEngine.swift` can place those results in deterministic narratives and on-device model prompts. A model prompt restriction does not correct misleading deterministic fallback text, so both paths were reviewed.
- `validateThreeWay` and the thermodynamic ITC decomposition are public package APIs. No call to `validateThreeWay` was found in the shipping app sources reviewed; do not describe this as an implemented three-way validation in the product.

## Corrections in this patch

| Finding | Source evidence | Correction |
| --- | --- | --- |
| Catalog presented as measured or validated molecular data | `BindingEntropyProfile` called its constants “ground truth”; entries contain broad author/year pointers, structural notes, or “FlexAID∆S validation” without a run receipt or per-value record. | Document exact-value provenance as unverified; show catalog estimates and legacy source notes explicitly in the prescription detail. No numeric values or original source notes were silently replaced. |
| A fuzzy name-match rank looked like a probability | `PrescriptionPokeDrugBridge` assigns constants and string-overlap formula scores; detail UI displayed a percentage. | Detail shows the matching method without a confidence percentage. Matching algorithms remain unchanged. |
| Scaffold ratings looked like substance-specific binding measurements | `PokeDrugMatchup` is a hand-authored scaffold/type lookup with default `.notEffective`. The UI claimed published Ki/crystal provenance for its stars. | Label ratings illustrative, show category score, and state that low ratings do not prove absence of binding. Preserve the categorical table. |
| Catalog HRV expectations looked like personal response predictions | `PharmacokineticProfile.expectedDeltaHRange`, timings and mechanism were surfaced as “Expected ΔH” and “Drug Response”. | Label these model/catalog inputs. Remove automatic collapse/expansion mechanism labels and distinguish timing assumptions from an individual measured response. |
| Correlation described as independent cross-domain validation | `CrossDomainValidator` documentation asserted isomorphism and independent validation; its summary was headed “validation”. MAE is computed on the same pairs used to fit the line. | Label association exploratory and p-values nominal; label MAE in-sample. Record molecular input provenance per pair (docking result, unverified catalog, or unspecified) and include source counts in summaries. A docking result is a supplied computation, not independently verified experimental truth. |
| Repeated doses inflated the substance denominator | `validateFromProfiles` and `validateHybrid` appended every response, while `n` was documented as the number of substances. Eight doses of one substance could pass the five-substance gate. | Deduplicate by substance before finite filtering and minimum-count checks, retaining the last supplied pair as in the existing direct-docking path. Sort retained IDs for deterministic output. Regression and p-value kernels are unchanged. |
| SCI represented concentration or relaxation | Insight templates said “strong focus”, “focus coherence”, or that a recent dose aligned with relaxed HRV, despite SCI explanations saying otherwise. | Use experimental SCI/HRV entropy wording, remove inferred autonomic/drug effects, and keep recorded dose timing distinct from causality. Lower SCI no longer suggests changing a medication schedule. |
| Nonfinite SCI could reach integer conversion | Insight correlation and pose fallbacks used `Int(score * 100)` without the HUD finite guard. | Route SCI formatting through `SessionHUDMetrics`, filter nonfinite optional scores, and avoid unsafe heart-rate integer conversion on pose prompts. |

## Shipped-copy claim sweep (19 September 2026)

A full sweep of reachable user-facing copy across `Bonhomme`, `BonhommeCore`,
`BonhommeWatch`, `BonhommeTV`, `BonhommeVision`, `BonhommeMac`, `NATURaLWidgets`
and `NATURaLLiveActivity` for diagnosis, treatment-effect, physiological-outcome
and receptor-binding language found the corrections above intact, plus one
uncorrected claim:

| Finding | Source | Correction |
| --- | --- | --- |
| Pose cue promised a physiological outcome | `PoseCatalog.swift` ankle-circles `voiceCueText` ended “This improves circulation.” in all nine inline languages. | Sentence removed in every language. The remaining cue (“Circle your ankle slowly. Keep the rest of your leg still.”) is complete and describes the movement only. |

Deliberately left unchanged, with reasoning:

- `PoseCatalog.swift` plan description “An uplifting sequence to boost energy and
  focus.” This is aspirational session framing, not a physiological or clinical
  assertion, and removing it would degrade the product without reducing review
  risk.
- `PokeDrugSpecies.swift` substance descriptions state regulatory and
  pharmacological facts (for example esketamine's FDA approval and reported
  onset). These describe a substance in an educational catalogue rather than
  promising the user an effect. Rewriting pharmacology content is a domain call
  for LP, not a copy edit; flagged here rather than silently altered.

### Regression guard

`scripts/test_contracts.py::test_claim_honesty` now locks this in as the ninth
product contract. It fails if a pose cue pairs an outcome verb
(improves/reduces/relieves/prevents/cures/heals/treats) with a physiological
target (circulation, blood pressure, inflammation, anxiety, depression,
arthritis, pain, immunity), and if any of the required scope limits disappear:
the first-use and SCI disclaimers in `BonhommeApp.swift`, “not a diagnosis” in
`SessionTips.swift`, both dose-timing disclaimers plus the `bindingDetected`
and model-prompt limits in `InsightEngine.swift`, and the exploratory-association
wording in `PokeDrugSubstanceInsightView.swift`.

The guard was verified to be non-tautological: reintroducing “This improves
circulation.” makes `test_contracts.py` exit 1 with
`pose catalogue must not promise a physiological outcome: improves circulation`,
and restoring the corrected cue returns `OK 9 NATURaL contracts`.

This sweep covers copy reachable in shipped source. It does not verify rendered
text on device, translated copy quality, or the underlying scientific dataset.

## Data that still requires source validation

1. **BindingEntropyProfile:** provide, per value, substance identity/stereochemistry, target, method, conditions, publication identifier and exact table/record, uncertainty, and any unit conversion. For computational values retain input structures, free/bound ensemble definition, binning, seed/configuration, engine version, and output receipt. Broad reviews and a rotatable-bond heuristic are not evidence for every substance-specific number.
2. **PharmacokineticProfile:** validate route/formulation/dose/population context for timings and the actual observational protocol underlying each entropy range. The current struct has no per-range study record. Do not use these hand-entered ranges as calibrated sensitivity, specificity, or diagnosis.
3. **PokeDrug ratings:** document the mapping from specific measurements to categorical scaffold/type and species ratings, including missing-data treatment. The current lookup's default does not distinguish unmeasured affinity from evidence of no interaction. This patch corrects presentation; it does not manufacture the missing measurements.
4. **ThermodynamicBindingProfile:** require exact assay/ITC records for each decomposition. Some entries with non-nil thermodynamics identify their source as `.pdspKi` and use broad “SCORPIO ITC” or “partial ITC” notes. `validateThreeWay` currently accepts any primary profile with a non-nil decomposition, irrespective of independently verified ITC provenance. Do not expose that result as measured SCORPIO validation without resolving this.
5. **Affinity conversion:** `AffinityMeasurement.bestAffinityNM` uses `IC50 / 2` and falls back to EC50, then feeds an affinity-based free-energy calculation. Validate the assay-specific assumptions and distinguish functional potency from equilibrium affinity before treating these derived energies as thermodynamic measurements. No change to these out-of-scope model algorithms was made here.
6. **Cross-domain inference:** document subject/session identity, actual independent unit, co-medications, dose timing, posture/activity and respiration, sensor quality/gaps, pairing and missing-data rules, and a prespecified analysis protocol. Deduplicating substance IDs prevents one concrete inflation bug; it does not establish independent observations, causality, assay equivalence, or out-of-sample generalization. Investigate repeated-subject dependence and selection/multiple-comparison effects before interpreting nominal p-values.
7. **Entropy units:** both molecular angular distributions and cardiac RR distributions can produce Shannon bits, but they describe different random variables and binning. Shared units do not imply shared physical state functions. The molecular energy conversion must retain its own temperature/ensemble assumptions; never convert cardiac entropy changes to binding free energy merely because both numbers use bits.
8. **Measured HRV versus derived indicators:** retain RR sample provenance and timing with results. SCI, threshold-crossing flags, PK profile scores, and cross-domain regressions are derived model outputs. The existing `bindingDetected` API name is historical; do not label that threshold result as measured receptor binding.

## Verification and limits

- Swift frontend syntax checks passed for the edited source and test files.
- `python3 -B scripts/test_contracts.py`: all 8 existing product contracts passed.
- Added regression tests for repeated-dose minimum-count inflation and mixed catalog/docking provenance, including last-supplied-pair behavior. A temporary executable built from the actual analysis sources passed all 12 matching denominator/provenance assertions (`/private/tmp/natural-scientific-checks.log`). It used the unchanged PharmacokineticProfile extension from PokeDrugSpecies as a dependency; no mock numeric implementation was substituted.
- Full package XCTest cannot run with local Command Line Tools because asset compilation requires Xcode (`actool`); an isolated XCTest attempt also confirmed the XCTest module is absent. No Xcode installation, dataset replacement, or submission occurred. The integrated Apple build/test CI remains the authority for the full package and UI targets.
- UI rendering, translated copy review, hardware physiology behavior, original scientific record verification, and any clinical validation remain unverified by this source audit.
