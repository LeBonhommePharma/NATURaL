# The TV sheet does not open during an active session

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
assertions are only meaningful if the sheet opens.

> **Corrected 21 September 2026 — #41's assertions do NOT pass vacuously.**
> An earlier version of this section said they "pass by asserting the absence of
> controls in a sheet that never appeared … vacuous rather than green." **That
> was wrong.** #41's author guarded against exactly that vacuity with a positive
> presence assertion before the absence checks, and that guard is what fails:
>
> ```
> AirPlayFallbackUITests testTVSheetHidesApplePairingButKeepsAirPlayAndSharingToggle :
> XCTAssertTrue failed - the TV sheet must actually open, or the absence checks below prove nothing
> ```
>
> CI 35542112178, on #41's head `2619f07`, failed this way in **both** the iPhone
> and iPad lanes (re-checked 27 September 2026). So #41 is **red because of this
> bug**, not silently green despite it: it is blocked by the bug rather than
> hiding it, and fixing the sheet presentation is what unblocks it. The proposed
> fix is PR #49 (unmerged; parked with #41 and #50 pending the scaffolding
> decision), which turns that guard green; #41's absence assertions then become
> meaningful for the first time.

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
`testTVConnectionPromptDescribesFeature`, which then failed at
`AirPlayFallbackUITests.swift:33` waiting for a `home.content` scroll view that
was never shown.

> **Note.** The diagnostic test named above was added and removed within
> `claude/measure-active-pose-render-latency` (merged to `main` as #48), and does
> not exist in the tree. The pollution sequence below is a record of what
> happened on that branch, not something reproducible from `main` as it stands.
> The line reference `:33` is correct on `main` after #48.

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
