# Screenshot plan — 20 September 2026

LP cannot capture these until signing works, but he should not be deciding *what*
to photograph at that point. Dimensions are the accepted families as of the
checked date; **re-verify immediately before upload** — Apple changes slots.

Capture path matters. For any landscape shot use
`XCUIScreen.main.screenshot()` rotated +90 with expansion, never
`app.screenshot()`: the latter writes portrait-width content into a
landscape-sized buffer and clips it, losing 25% of the UI including the entire
metrics rail. Evidence in [verification.md](verification.md).

## iPhone — required

6.9" (1320×2868) is the one required family; 6.5" is accepted where present.

| # | Screen | State it must be in | Why |
|---|---|---|---|
| 1 | Home, featured card | Bloom visible, "Come back to yourself.", mint CTA | The identity shot. Bloom must render at full quality. |
| 2 | Active session | Illustrated pose mid-practice, pose name, numbered guide visible | What the app actually is. |
| 3 | Paused session | Resume/End pinned, guide still readable | Shows pausing never hides instructions — a real differentiator. |
| 4 | Pose catalogue | Style cards, "Move in your own way" | Breadth without claiming medical benefit. |
| 5 | Summary | Completed session, Done action visible | Closes the loop. |
| 6 | About & Privacy | On-device wording visible | Privacy posture is a selling point here. |

Do **not** screenshot: Prescriptions, any PokeDrug substance page, or any SCI
number presented as a measurement. Rationale in
[scientific-claims-audit.md](scientific-claims-audit.md) — a store screenshot is
a claim.

## iPad — REQUIRED (critical path)

LP scoped 1.0 to “all possible platforms”, resolved as the four verifiable ones: iPhone, iPad, Apple Watch, Mac. iPad is therefore not conditional, and this set plus native iPad device QA is on the critical path rather than a nice-to-have.

13" (2064×2752 portrait, 2752×2064 landscape).

| # | Screen | State |
|---|---|---|
| 1 | Home, split view | Sidebar populated, detail showing featured card |
| 2 | Session, landscape | Guide column **and** right metrics rail both visible |
| 3 | Paused, landscape | Pinned Resume/End across full width |
| 4 | Pose catalogue | Sidebar + detail together — shows it is not a stretched phone app |

Apple rejects stretched iPhone captures. Take these natively.

## Apple Watch — required for the watchOS listing

Accepted sizes per current families; capture from the approved build, not the simulator, once TestFlight works.

| # | Screen | State |
|---|---|---|
| 1 | Plan browser | Branded list |
| 2 | Active session | Pose + timer, heart rate if present |
| 3 | Session complete | Summary state |

If heart rate is unavailable the HUD shows an em dash — that is correct behaviour
and is contract-enforced, but it makes a poor screenshot. Capture with a real
signal.

## Appendix: Apple TV — DEFERRED, not part of 1.0

tvOS is deferred (PR #41 gates the Apple TV pairing UI behind `TVRelayPairing.appleTVAppIsPublished = false`). Capture nothing here for the 1.0 submission. Retained verbatim so the set does not have to be re-derived when tvOS is picked up.

**1920×1080 or 3840×2160, no alpha.**

| # | Screen | State |
|---|---|---|
| 1 | Standalone session | Guide at 10-foot scale |
| 2 | Paused | Pinned controls, focus visible |
| 3 | Pose transition | Next-pose state |
| 4 | Pairing | **Never capture a live pairing secret** — use an expired or placeholder code |

## Mac — REQUIRED (critical path)

Same scope decision as iPad: the native Mac app ships in 1.0, so this set plus Mac device QA is on the critical path.

1280×800 / 1440×900 / 2560×1600 / 2880×1800.

| # | Screen | State |
|---|---|---|
| 1 | Window at default size | Plan selection |
| 2 | Session | Guide + keyboard controls |
| 3 | Summary | Early-end and completion states |

Mac has no live Health feed. Do not capture anything implying it does.

## Optional across platforms

App previews (video). Not required for 1.0 and not planned here.

## Open — needs LP

1. ~~Is the app offered on iPad?~~ **Answered:** yes — iPad ships in 1.0, iPad set required.
2. ~~Is the native Mac app submitted for 1.0?~~ **Answered:** yes — submitted, Mac set required.
3. ~~Localized screenshots — English only, or also French Canadian?~~ **Answered
   20 September 2026: English and French Canadian, both.** This follows from the
   1.0 locale scope rather than being a separate preference — the build ships `en`
   and `fr` only (`LocalizedString.supportedLanguages`), so those are exactly the
   two sets that can be captured honestly. Every table above is therefore captured
   **twice**: once per locale, per platform. Budget accordingly — this doubles the
   capture count for iPhone, iPad, Apple Watch and Mac.

No open questions remain in this document.
