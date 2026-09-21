# Clinical medication records are cut from 1.0

**Decided:** LP, 21 September 2026 (Montreal local).
**Status:** gated and unreachable in 1.0. **The code is retained deliberately.**

## Read this before deleting anything

Everything under `Bonhomme/Services/HealthKit/` that touches clinical records —
`HealthKitManager`, `MedicationPrescriptionService`, `MedicationTracker`,
`parseFHIRMedication` — **stays in the repository on purpose.** It is gated, not
removed, because the feature returns in a different role (below).

A future session finding unreachable clinical code and tidying it away would
destroy built, consent-gated work that LP intends to use. That is not a
hypothetical failure mode: two decisions on 20 September were re-litigated from
scratch because their reasoning was not written down anywhere reachable.

## Why it was cut

1. **It answers the wrong question.** `HKClinicalTypeIdentifier.medicationRecord`
   reports what a provider *prescribed*, sourced from a hospital system. It does
   not report what the person actually *took*, or when. The research question
   1.0 is built around — HRV over time against medication taken, which one, how
   much, when — is adherence, and prescription records cannot close that gap.
2. **It may be inert for the actual user base.** Health Records institutional
   adoption in Canada appears concentrated in Ontario, with no Québec
   institution confirmed connected. For a Montreal-based user base the feature
   could ship and read nothing for anyone.
3. **Cutting is reversible; shipping a broken feature is not.** The entitlement
   can be restored and the flag flipped. A 1.0 that ships a prominent feature
   returning no data for its users cannot be un-shipped.

## Target state — why the code stays

1.1+ **demotes** clinical records rather than removing them. The prescription
becomes a *coded-vocabulary source*: it populates the medication picker with
real, correctly-coded products the user has actually been prescribed, and the
user then logs **administration events** against those entries. Prescription
data becomes an input to identity resolution instead of a substitute for
adherence data.

That is a smaller, better-scoped role for the same code, and it is why deleting
it would be the wrong call.

## How the cut is implemented

A single flag, `HealthKitManager.clinicalMedicationRecordsEnabled = false`,
gates **two** independent doors. Both were needed:

| Door | Site | Gate |
|---|---|---|
| Authorization | `HealthKitManager.isClinicalMedicationTypeAvailable` | `guard clinicalMedicationRecordsEnabled` |
| Query | `MedicationTracker` clinical query | `guard HealthKitManager.clinicalMedicationRecordsEnabled` |

The second door matters. `MedicationTracker` reaches `HKClinicalType` directly
rather than through `isClinicalMedicationTypeAvailable`, so gating the obvious
entry point alone would have left the read reachable. Every clinical call site
in the tree now sits behind one of these two guards:

```
HealthKitManager.swift:31    inside isClinicalMedicationTypeAvailable      (door 1)
HealthKitManager.swift:106   inside requestClinicalMedicationAuthorization (door 1, transitively)
MedicationTracker.swift:62   after the door 2 guard
MedicationTracker.swift:71   after the door 2 guard
MedicationTracker.swift:76   after the door 2 guard
```

`com.apple.developer.healthkit.access = (health-records)` was removed from
`Bonhomme/Bonhomme.entitlements`. Ordinary HealthKit
(`com.apple.developer.healthkit`, `…background-delivery`) is untouched.

**Restoring the feature requires both** the flag flip and the entitlement. The
flag's doc comment says so, and the entitlements file carries a comment where
the key used to be, so neither half can be restored while silently missing the
other.

### Verified, not assumed

- Release build for `generic/platform=iOS` with `-allowProvisioningUpdates`:
  `** BUILD SUCCEEDED **`. Automatic signing regenerated the profiles; identity
  resolved as `Apple Development: Louis-Philippe Morency (Q64R7Z4MS5)`.
- `codesign -d --entitlements` on the built `Bonhomme.app` reports
  `com.apple.developer.healthkit` and `…background-delivery` and **no**
  `healthkit.access`.
- Signing style is `Automatic` on every configuration; no manual
  `PROVISIONING_PROFILE` to update.

## The launch-crash hypothesis: not confirmed

The cut was also run as an experiment, on the theory that unavailable clinical
authorization was crashing launch in the Simulator. **It was not.**

The app launched and rendered correctly in the Simulator *before* the cut, with
all clinical code intact. It launches after. The crash reports from 20 September
are `0x8BADF00D` process-launch watchdog kills whose own statistics attribute
the cause elsewhere:

```
"Elapsed total CPU time (seconds): 330.150 … 100% CPU"
"Elapsed application CPU time (seconds): 2.166, 1% CPU"
```

The application used 1% of the CPU consumed while the host ran at 100%. That is
host starvation — two `xcodebuild test` lanes running concurrently — not an app
fault. All four crash reports are dated 20 September; none since. Recorded here
so the theory is not re-proposed.

## Consequences for the 1.0 submission

With clinical records gated, the only HealthKit read that ships is ordinary
quantity data, principally `heartRateVariabilitySDNN`. No restricted entitlement,
no provider integration, and no clinical data in the privacy nutrition label.

The review story is materially simpler, and — separately verified — no
health-derived data leaves the device: no `URLSession` in shipping code, no
CloudKit (`cloudKitDatabase: .none`), no analytics SDK, and the SharePlay payload
carries pose index and timestamps only. App Review Guideline 5.1.3's
human-subjects research clauses engage when health data leaves the device for
research; on the shipped 1.0 it does not.
