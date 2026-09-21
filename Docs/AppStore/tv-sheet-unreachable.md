# The TV sheet does not open during an active session

*Ported to `main` 20 September 2026 from `claude/measure-active-pose-render-latency`. Every claim below was re-verified against `main`; the one that did not hold is corrected and marked inline.*

**Status:** open product bug. Unfixed. Disposition is LP's.
**Established:** 20 September 2026, by demonstration on iPhone Air / iOS 27.2.

## The finding

Tapping the toolbar TV button during an active session does not surface the TV
sheet. Share-to-TV is therefore unreachable from inside a session, which is the
only place the app offers it.

Measured, with every prerequisite passing and exactly one assertion failing:

```
navigationBar "TV display" appeared:  false
switch tv.shareSession visible:       false
session still present (pauseResume):  true
```

The session reached the active pose, the toolbar button existed, and the tap
landed. Nothing crashed and nothing dismissed the session. The sheet simply
never appears.

## Why it happens

- The sheet is `.sheet` on the root `Group` in `Bonhomme/App/BonhommeApp.swift:45`,
  bound to `appState.showsTVDisplay`.
- The session is `.fullScreenCover`, presented from
  `Bonhomme/Features/Workout/HomeView.swift:23` and
  `Bonhomme/Features/Workout/StyleDetailView.swift:38`.
- The only in-session entry point, `Bonhomme/Features/Workout/WorkoutFlowView.swift:115`,
  sets that flag from *inside* the cover.

The shape is established by reading the source. The behaviour is established by
running it. Those are separate claims and only the second is proof.

## Consequence for the tvOS gating work (PR #41)

PR #41 adds absence assertions against this same sheet — that Apple-pairing
controls are hidden while the AirPlay row and sharing toggle remain. Those
assertions are only meaningful if the sheet opens. It does not, so they pass by
asserting the absence of controls in a sheet that never appeared. That is
vacuous rather than green. **#41 needs re-examining before it merges.**

## Why this is a document and not a test

A test that fails by design turns a finding into a permanent alarm, and the
person it alarms is whoever reads the CI notifications. The diagnostic that
established this — `testDiagnosticDoesTheTVSheetOpenDuringAnActiveSession` —
was removed for that reason, and for a second one found after it ran:

Because it failed mid-session with `continueAfterFailure = false`, it abandoned
an active workout. The app persists session state for crash recovery and calls
`checkForResumableWorkout()` on launch, so the abandoned session **outlived the
test process** and relaunched into the next test. That broke the two
pre-existing tests in the same class, `testTVSectionShowsOnHomeScreen` and
`testTVConnectionPromptDescribesFeature`, which then failed on the
`home.content` `waitForExistence` inside `revealTVCard()` — `AirPlayFallbackUITests.swift:29`
on `main` — waiting for a scroll view that was never shown.

> **Ported note.** The run that produced this was on
> `claude/measure-active-pose-render-latency`, where that assertion sits at
> `:33`; the branch adds four lines to `setUp`. The assertion is the same one.
> The diagnostic test named above never existed on `main` — it was added and
> removed entirely on that branch — so the pollution sequence below is a record
> of what happened there, not something reproducible from `main` as it stands.

Confirmed by controlled subtraction rather than by argument — same code, same
test selection, same simulator, with persisted app state as the only variable:

| Precondition | Result |
| --- | --- |
| polluted (diagnostic had run) | both failed, 22.6s / 21.0s |
| polluted (an `simctl uninstall` had silently failed) | both failed, 23.0s / 58.6s |
| verified clean, precondition-gated | both **passed**, 16.8s / 12.5s |

A UI test that can strand the app in a recoverable session is a hazard to every
test that runs after it, in that run and in later ones. Any future reproduction
of this bug must either avoid leaving the session open or clear app state
afterwards.

## Reproducing it

Manually: start any session, tap the TV button in the session toolbar, observe
that no sheet appears. No instrumentation required.
