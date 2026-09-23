# Privacy policy — DRAFT, not published

**Status: draft.** Not deployed, not linked from App Store Connect. Publishing to
`thebonhomme.com` is LP's trigger, not this session's.

Derived from the code as it stands after the clinical-records cut
([clinical-records-cut-from-1-0.md](clinical-records-cut-from-1-0.md)) and from
the confirmed not-collection determination in
[listing-metadata-draft-1-0.md](listing-metadata-draft-1-0.md). Every statement
below traces to something in the source. **Where the code does not settle a
question, the draft says so rather than filling the gap with boilerplate.** Those
gaps are listed at the end and must be closed by LP before this is published.

---

## Privacy Policy for NATURaL

**Last updated: 21 September 2026**

### The short version

NATURaL does not collect your data. There is no account, no server, and no
analytics. What the app records stays on your device.

### What NATURaL reads

**Health data (only with your permission).** If you allow it, NATURaL reads
heart rate variability, and related workout signals, from Apple Health during a
session. It uses them to adapt what it shows you while you practise. You can
refuse this and the app works fully without it.

**Data you enter.** Medication entries, session notes and preferences you type
into the app.

**Camera and motion (optional).** If you use the movement coach, NATURaL uses the
camera and motion sensors while that feature is on screen. **Frames are not
saved and are not transmitted.**

### What NATURaL writes

If you permit it, NATURaL saves completed sessions to Apple Health as workouts
and mindful minutes, so they appear in Health and Fitness alongside your other
activity. That writes into your own Health store. It does not send anything to us.

### Where your data goes

**Nowhere we can reach.** NATURaL has no server, no account system and no
analytics. We cannot see your data, because there is no mechanism by which it
could reach us.

Data moves off your iPhone in exactly three cases, all of them to hardware you
own or to a destination you choose at the moment you choose it:

- **Your Apple Watch**, if you have one paired.
- **Your Apple TV**, if you start a TV display during a session. This travels
  over your own local network on an encrypted connection, and only while the
  session is running. It is not stored on the TV.
- **A workout image you explicitly share.** If you tap Share on a completed
  session, you choose the destination. The image contains the date and duration
  of the session.

If you use a SharePlay session with others, the app sends which pose the group is
on and when. **No health data is included.**

### What NATURaL does not do

- No advertising, and no advertising identifiers.
- No tracking across apps or websites. There is no ATT prompt because there is
  nothing to ask about.
- No analytics, crash-reporting or attribution SDKs.
- No sale or sharing of personal information.
- No account, so no email address, password or profile.

### Apple Music

If you connect Apple Music, playback is handled by Apple under your own Apple
Music relationship. NATURaL does not read or transmit your library.

### Your control

- Health permissions are granted per data type in Apple Health and can be
  withdrawn there at any time.
- Deleting the app removes the data it stored on your device.
- Because nothing is transmitted to us, there is no account to close and no
  server-side copy to request or erase.

### Children

NATURaL is not directed to children and does not knowingly collect information
from them. It collects no personal information from anyone.

### Changes

Material changes will be posted here with an updated date.

### Contact

*[Support contact — see open gaps.]*

---

## Open gaps — must be closed before publishing

These are **not** guesses left in the text; they are questions the code cannot
answer, listed so they are closed deliberately.

1. **Contact address.** No support email appears anywhere in the source. LP must
   supply one; the support page needs the same address.
2. **Governing jurisdiction.** Not derivable from code. Québec/Canada (Law 25,
   PIPEDA) is the obvious candidate given the developer's location, and Law 25
   has specific requirements, but the choice and any required statutory language
   are LP's and arguably counsel's.
3. **Legal entity name.** The policy currently says "we" without naming who that
   is. Whether NATURaL ships under a personal name or a company is LP's to state.
4. **GDPR/UK applicability.** If the app is offered in the EU/UK, a lawful-basis
   statement and data-subject-rights section are expected even where no data is
   collected. Whether those storefronts are enabled is an App Store Connect
   setting, not a code fact.
5. **Retention period for on-device data.** The app persists sessions
   indefinitely until the user deletes the app. That is accurate as written, but
   if LP wants a stated retention window it is a product change, not a wording
   change.

**This draft has not been reviewed by counsel.**
