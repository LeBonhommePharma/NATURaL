# On-Device Install Runbook (LPhone + LP++)

Install **Bonhomme** (iOS) and **BonhommeWatch** (watchOS) onto the lab devices from this machine. Prefer USB for first install; use network after pairing is healthy.

| Field | Value |
|-------|--------|
| Repo root | `/Users/lp.more/Projects/NATURaL` |
| Project | `NATURaL.xcodeproj` |
| Primary scheme | `Bonhomme` (embeds Watch via WatchKit) |
| Watch scheme | `BonhommeWatch` |
| Development Team | **`ZJLX84G8QV`** |
| Bundle ID (iOS) | `com.natural.Bonhomme` |
| Bundle ID (Watch) | `com.natural.BonhommeWatch` |
| Entitlements (iOS) | `Bonhomme/Bonhomme.entitlements` |
| Entitlements (Watch) | `BonhommeWatch/BonhommeWatch.entitlements` |
| Min iOS / watchOS | 18.6 / 10.0 (as set on Bonhomme / BonhommeWatch targets) |

---

## 1. Known lab devices (session inventory)

Captured via `xcrun devicectl list devices` and `xcrun xctrace list devices` (2026-07-09). Refresh if a device is replaced.

| Name | Model | Hardware UDID (`xctrace` / Xcode) | CoreDevice Identifier (`devicectl`) | Notes |
|------|--------|-------------------------------------|--------------------------------------|--------|
| **LPhone** | iPhone 15 Pro (`iPhone16,1`) | `00008130-00121D5E22F8001C` | `3475A5F4-0090-5222-B033-C3C9AEB1B250` | Primary iOS target |
| **LP++** / `LP++.watchOS` | Apple Watch Series 11 (`Watch7,17`) | `00008310-000671A11490E01E` | `3984BED7-ECA4-5196-B4A3-F7651AC4C5FE` | Paired companion |
| LPad (optional) | iPad (A16) | `00008120-000450D40C04201E` | `FE91F397-CF7A-59C6-89BF-0878D65CEF95` | Not required for this runbook |

**Which ID to use**

- `xcodebuild -destination 'id=…'` → prefer **hardware UDID** (`00008…`).
- `xcrun devicectl … --device …` → prefer **CoreDevice Identifier** (UUID) or hardware UDID (both accepted when registered).

Shell shortcuts:

```bash
export IPHONE_UDID=00008130-00121D5E22F8001C
export IPHONE_CORE=3475A5F4-0090-5222-B033-C3C9AEB1B250
export WATCH_UDID=00008310-000671A11490E01E
export WATCH_CORE=3984BED7-ECA4-5196-B4A3-F7651AC4C5FE
export TEAM_ID=ZJLX84G8QV
```

Or run:

```bash
./scripts/install-device.sh check
```

---

## 2. One-time device prep

### 2.1 Trust + Developer Mode (required)

**iPhone (LPhone)**

1. Unlock phone. Connect USB-C cable to the Mac used for builds.
2. Tap **Trust This Computer** when prompted; enter passcode.
3. **Settings → Privacy & Security → Developer Mode → On** → restart when asked → confirm.
4. Confirm Developer Mode is enabled:

```bash
xcrun devicectl device info details --device "$IPHONE_CORE" 2>/dev/null | grep -i 'Developer Mode'
# Expected: Developer Mode Status: Enabled
```

**Apple Watch (LP++)**

1. Keep Watch paired to LPhone (Watch app on iPhone).
2. Unlock Watch; keep it on charger if the battery is low (installs fail when Watch sleeps aggressively).
3. On Watch: **Settings → Privacy & Security → Developer Mode → On** (watchOS 9+) → restart Watch → confirm.
4. Enable **Settings → Developer → Enable Internal Settings** only if Xcode asks for it after first failed deploy (not always present).

Without Developer Mode, installs fail with errors resembling:

- `Developer Mode disabled`
- `The device does not support developer mode`
- `AMDeviceSecureInstallApplicationBundle … 0xe8008015` / similar

### 2.2 Local network / wireless debugging

1. iPhone and Mac on the **same Wi‑Fi** (or personal hotspot from the same phone).
2. In Xcode: **Window → Devices and Simulators** → select **LPhone** → enable **Connect via network**.
3. First successful deploy should still be **USB**. After that, network is optional.

**Bonjour hostnames (CoreDevice)**

- `LPhone.coredevice.local`
- `LPwatchOS.coredevice.local` (Watch)

```bash
# Inventory
xcrun devicectl list devices
xcrun xctrace list devices

# Prefer USB when State is "unavailable" / tunnel stuck
```

### 2.3 Signing team on this Mac

```bash
# Xcode → Settings → Accounts → Apple ID that owns team ZJLX84G8QV
# Download Manual Profiles not required when CODE_SIGN_STYLE=Automatic

# Verify team is selected in project (Bonhomme Debug/Release already set):
grep -n 'DEVELOPMENT_TEAM' NATURaL.xcodeproj/project.pbxproj | head
# Expect ZJLX84G8QV on Bonhomme / Widgets / LiveActivity configs
```

CLI force (optional override; do not leave empty team on app targets):

```bash
xcodebuild … DEVELOPMENT_TEAM=ZJLX84G8QV CODE_SIGN_STYLE=Automatic
```

Register devices automatically on first Automatic sign, or add UDIDs in the Apple Developer portal if you use a paid team with manual profiles.

---

## 3. Entitlements (do not strip casually)

### 3.1 Production / default entitlements (keep these)

**iOS — `Bonhomme/Bonhomme.entitlements`**

| Key | Purpose |
|-----|---------|
| `com.apple.developer.healthkit` (+ background-delivery, health-records access) | HRV / workouts / CareKit bridge |
| `com.apple.developer.icloud-services` = CloudKit | SwiftData CloudKit sync |
| `com.apple.developer.icloud-container-identifiers` = `iCloud.com.natural.Bonhomme` | Container |
| `com.apple.developer.ubiquity-kvstore-identifier` | KVS |
| `com.apple.security.application-groups` = `group.com.natural.Bonhomme` | Widgets / Live Activity |
| `com.apple.developer.watchkit` | Companion Watch app |
| `com.apple.developer.siri` | App Intents / Siri shortcuts |
| `aps-environment` = `development` | Push / Live Activities (dev) |

**Watch — `BonhommeWatch/BonhommeWatch.entitlements`**

| Key | Purpose |
|-----|---------|
| HealthKit (+ background-delivery) | Wrist HR / workout session |
| App Group `group.com.natural.Bonhomme` | Shared container with phone |

### 3.2 Personal team / capability limits (team `ZJLX84G8QV`)

If this Apple ID is a **Personal Team** (free) rather than Apple Developer Program ($99):

| Capability | Typical free Personal Team behavior | Impact on Bonhomme |
|------------|-------------------------------------|--------------------|
| **HealthKit** | Allowed for development | Core path works |
| **App Groups** | Allowed | Widgets / Watch sharing OK if group is created for the team |
| **WatchKit companion** | Allowed for development | Phone+Watch install OK |
| **Siri** (`com.apple.developer.siri`) | Often **unavailable** or fails provisioning | Build error: *Personal development teams do not support the Siri capability* (or similar) |
| **Push Notifications** (`aps-environment`) | **Limited / not fully supported** on free teams | Live Activities / remote push may fail to provision |
| **iCloud / CloudKit** | Container may not provision; sync flaky or blocked | SwiftData CloudKit features may not activate |
| **App ID count / 7-day certs** | Profiles expire ~7 days | Re-sign and reinstall weekly |

**Do not remove entitlements from the main files to “make it build”** without a documented DEBUG alternate (below). Stripping Siri/Push/iCloud silently breaks product features and confuses CI/signing audits.

### 3.3 DEBUG alternate (only if Personal Team blocks signing)

Use this **only** when Automatic signing fails on Siri / Push / iCloud for team `ZJLX84G8QV`, and only for local on-device smoke tests.

1. Copy (do **not** edit production in place without restoring):

```bash
cp Bonhomme/Bonhomme.entitlements Bonhomme/Bonhomme.DebugPersonal.entitlements
```

2. In the **DEBUG-only** copy, temporarily remove **only** the keys that the error names (usually Siri and/or `aps-environment` and/or iCloud keys). Keep HealthKit, App Groups, and WatchKit.

3. Point **Debug** configuration only:

```text
CODE_SIGN_ENTITLEMENTS[config=Debug] = Bonhomme/Bonhomme.DebugPersonal.entitlements
# Release must keep: Bonhomme/Bonhomme.entitlements
```

4. Document in the commit message: which keys were dropped and why.

5. **Never** commit a permanent strip of production entitlements. Prefer upgrading to a paid Apple Developer Program membership so Siri + Push + CloudKit remain in the default entitlements.

**There is no checked-in stripped DEBUG entitlements file by default.** Create it only when blocked, and delete or gitignore it after paid-team signing works.

---

## 4. Connectivity & “tunnel stuck”

Symptoms:

- `devicectl` shows LPhone **unavailable**, Watch **available (paired)** or vice versa
- `tunnelState: unavailable` / install hangs at “Connecting to … via network”
- `xcodebuild` destination not found for `id=00008130-…`
- CoreDevice tunnel process wedged after sleep / VPN / Wi‑Fi roam

### 4.1 Quick recovery

```bash
# 1. Prefer cable
# Plug LPhone, unlock, dismiss “Trust” if needed

# 2. Kill stuck CoreDevice / remote tunnels
sudo pkill -9 -f remoted 2>/dev/null || true
sudo pkill -9 -f CoreDeviceService 2>/dev/null || true
# Then unplug/replug USB; wait ~10s

# 3. Restart usbmuxd if still dead (USB only)
sudo killall -9 usbmuxd 2>/dev/null || true
# usbmuxd relaunches automatically

# 4. Re-list
xcrun devicectl list devices
xcrun xctrace list devices | grep -E 'LPhone|LP\+\+|00008130|00008310'
```

### 4.2 Network-specific

1. Disable VPN on Mac and phone.
2. Forget “Connect via network”, reconnect USB, re-enable network only after USB deploy works.
3. Toggle airplane mode on phone 5s, then Wi‑Fi back on.
4. Reboot phone (and Watch if companion install is the one hanging).
5. Xcode → Devices → right-click device → **Unpair Device**, re-pair over USB (last resort).

### 4.3 Watch-specific

- Install **iPhone app first** (scheme `Bonhomme`), then Watch.
- Keep Watch unlocked and on wrist/charger during install.
- If Watch install stalls: open **Watch** app on iPhone → My Watch → ensure storage free; restart both devices.
- Destination for Watch builds usually uses the **phone** as host:

```bash
# Watch app build/install often via paired phone id:
xcodebuild … -scheme BonhommeWatch \
  -destination "platform=watchOS,id=$WATCH_UDID"
# If Xcode only resolves via phone:
xcodebuild … -scheme Bonhomme \
  -destination "platform=iOS,id=$IPHONE_UDID"
# (Watch product installs as embedded companion when the iOS target dependency is configured)
```

---

## 5. Exact build & install commands

Run from repo root. Use a DerivedData path under the repo or `/tmp` to avoid clobbering IDE caches if you prefer.

```bash
cd /Users/lp.more/Projects/NATURaL
export IPHONE_UDID=00008130-00121D5E22F8001C
export IPHONE_CORE=3475A5F4-0090-5222-B033-C3C9AEB1B250
export WATCH_UDID=00008310-000671A11490E01E
export TEAM_ID=ZJLX84G8QV
export DERIVED=/tmp/NATURaL-device-dd
```

### 5.1 Check availability

```bash
./scripts/install-device.sh check
# or:
xcrun devicectl list devices
xcrun xctrace list devices | grep -E 'LPhone|LP\+\+'
```

### 5.2 Build + install iOS (LPhone) via xcodebuild

```bash
xcodebuild \
  -project NATURaL.xcodeproj \
  -scheme Bonhomme \
  -configuration Debug \
  -destination "platform=iOS,id=$IPHONE_UDID" \
  -derivedDataPath "$DERIVED" \
  DEVELOPMENT_TEAM=$TEAM_ID \
  CODE_SIGN_STYLE=Automatic \
  build
```

Install the built `.app` with `devicectl` (when `xcodebuild` built but did not install, or after a clean build):

```bash
APP=$(find "$DERIVED/Build/Products" -path '*/Debug-iphoneos/Bonhomme.app' | head -1)
echo "Installing: $APP"
xcrun devicectl device install app --device "$IPHONE_CORE" "$APP"
```

Launch:

```bash
xcrun devicectl device process launch --device "$IPHONE_CORE" com.natural.Bonhomme
```

### 5.3 One-shot install with xcodebuild (destination = device)

Some Xcode versions install when destination is a physical device and you use `build` after enabling install in the scheme; reliable CLI path is **build then `devicectl device install app`**. Alternatively open Xcode UI: scheme **Bonhomme** → destination **LPhone** → Run (⌘R).

### 5.4 Watch (LP++)

**Preferred:** Run scheme **Bonhomme** to LPhone so the companion Watch app is pushed if the target dependency embeds Watch.

**Direct Watch scheme** (when Watch is available):

```bash
xcodebuild \
  -project NATURaL.xcodeproj \
  -scheme BonhommeWatch \
  -configuration Debug \
  -destination "platform=watchOS,id=$WATCH_UDID" \
  -derivedDataPath "$DERIVED" \
  DEVELOPMENT_TEAM=$TEAM_ID \
  CODE_SIGN_STYLE=Automatic \
  build

WATCH_APP=$(find "$DERIVED/Build/Products" -path '*/Debug-watchos/BonhommeWatch.app' | head -1)
xcrun devicectl device install app --device "$WATCH_CORE" "$WATCH_APP"
```

If destination resolution fails for the Watch UDID, install via Xcode: scheme **BonhommeWatch** → destination **LP++** (or LPhone + Watch combo).

### 5.5 Logs

```bash
# Stream device console (filter as needed)
xcrun devicectl device process launch --device "$IPHONE_CORE" --start-stopped com.natural.Bonhomme
# or Console.app → select LPhone

# Capture install failure details
xcodebuild … 2>&1 | tee /tmp/bonhomme-device-build.log
```

### 5.6 Helper script

```bash
./scripts/install-device.sh check          # availability only
./scripts/install-device.sh install-ios    # build + install phone
./scripts/install-device.sh install-watch  # build + install watch (best effort)
./scripts/install-device.sh install-all    # phone then watch
```

---

## 6. Post-install smoke checklist

On **LPhone**:

1. App launches; HealthKit permission sheet appears → Allow.
2. Workout flow opens (Home → style → start).
3. Widgets / Live Activity: optional; may require Push entitlement health (see §3.2).
4. Siri phrase / App Intent: optional; may require paid team Siri capability.
5. CloudKit sync: optional; confirm only if iCloud container is provisioned for the team.

On **LP++**:

1. BonhommeWatch appears on Watch home screen.
2. Start session from Watch or phone; HR stream / connectivity messages appear (see `Bonhomme/Services/WatchConnectivity/CONSOLE_MESSAGE_GUIDE.md`).

---

## 7. Common errors → fix

| Error / symptom | Fix |
|-----------------|-----|
| Developer Mode disabled | §2.1 |
| Destination not found `id=00008130-…` | Unlock phone, USB, §4; re-run `xctrace list devices` |
| Tunnel stuck / unavailable | §4.1–4.2 |
| Signing / provisioning Siri or Push | §3.2–3.3 — use DEBUG alternate only if documented |
| iCloud container not found | Paid team + create `iCloud.com.natural.Bonhomme` in developer portal |
| Watch install timeout | Unlock Watch, charger, install phone first, reboot pair |
| Profile expired (7-day) | Rebuild with Automatic signing; trust new developer app on device |
| `Could not launch … unverified` | Settings → General → VPN & Device Management → trust developer |
| Disk full / DerivedData corruption | `rm -rf /tmp/NATURaL-device-dd` and rebuild |

---

## 8. What not to do

- Do **not** set `CODE_SIGNING_ALLOWED=NO` for on-device installs (simulator-only Makefile path).
- Do **not** strip `Bonhomme.entitlements` / `BonhommeWatch.entitlements` in-place without a **DEBUG alternate** and a note in the PR/commit.
- Do **not** commit machine-local provisioning profiles or private keys.
- Do **not** assume simulators validate HealthKit/WatchConnectivity/Live Activities the same as LPhone + LP++.

---

## 9. Refresh device inventory

When devices change:

```bash
xcrun devicectl list devices
xcrun xctrace list devices
xcrun devicectl device info details --device <core-or-udid>
```

Update the table in §1 and the defaults in `scripts/install-device.sh`.
