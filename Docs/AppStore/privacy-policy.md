# NATURaL privacy policy source and release review

Public policy URL: [thebonhomme.com/NATURaL/privacy/](https://thebonhomme.com/NATURaL/privacy/). This internal review does not verify the currently deployed page.

The English page source is [site/NATURaL/privacy/index.html](site/NATURaL/privacy/index.html). All 11 language pages are generated from [site-locales.json](site-locales.json) by `scripts/build-app-site.py`. Change that locale source and regenerate when policy text changes.

## Source findings — 19 September 2026

Inspected app-owned Release paths process health/workout/medication records locally. SwiftData disables CloudKit, CareKit uses local `OCKStore`, and no developer analytics or upload endpoint was found. `InsightEngine` explicitly selects on-device `SystemLanguageModel.default`. Paired Watch, Apple services, sharing destinations and local display output are separate flows in [privacy-dataflow-review.md](privacy-dataflow-review.md).

**Data Not Collected is the proposed App Privacy answer**, subject to final archive/dependency/network verification. Local processing does not mean Health access, medication handling or inter-device communication never occurs. Privacy manifests do not independently establish the answer.

## Retention, consent and deletion limits

- Revocation invalidates pending clinical access tokens, prevents stale query results from repopulating imported profiles, and stops later sync stages. Regranting does not revive work from an earlier grant.
- Revocation does not erase previously saved schedules, CareKit records, Apple Health data, exports or older development CloudKit records. A CareKit write already submitted while consent was valid may finish; subsequent operations and stale completion publication are blocked. Do not promise retroactive deletion or transaction rollback.
- Persistence attempts to exclude health-storage directories from backups and apply file protection. Verify actual SQLite/WAL, CareKit, preferences and App Group files on hardware, including existing installations. Directory attribute calls do not prove every previously created file has the required protection.
- Removing the app, revoking Health permissions and deleting Health records are different actions. Shared App Group storage may survive while another group member remains installed. The policy distinguishes shared storage and older development cloud records.
- Support email is processed by mail providers and received by the developer when a user sends it. The app's no-collection claim must not deny this separate voluntary contact flow.

## Remaining proof

The source review and fixes are recorded in [privacy-dataflow-review.md](privacy-dataflow-review.md). Still required: final archive privacy report, linked dependencies and release traffic, consent withdrawal during imports on hardware, retention/deletion behavior, and comparison of the deployed policy/translations to the same build. These device and portal actions are not represented as completed.

Contact: lp@thebonhomme.com.
