#!/usr/bin/env bash
# install-device.sh — check availability and install Bonhomme on LPhone / LP++
# See Docs/ON_DEVICE_INSTALL.md for full runbook.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# Lab devices (refresh via: xcrun devicectl list devices && xcrun xctrace list devices)
IPHONE_UDID="${IPHONE_UDID:-00008130-00121D5E22F8001C}"
IPHONE_CORE="${IPHONE_CORE:-3475A5F4-0090-5222-B033-C3C9AEB1B250}"
WATCH_UDID="${WATCH_UDID:-00008310-000671A11490E01E}"
WATCH_CORE="${WATCH_CORE:-3984BED7-ECA4-5196-B4A3-F7651AC4C5FE}"
TEAM_ID="${TEAM_ID:-ZJLX84G8QV}"
SCHEME_IOS="${SCHEME_IOS:-Bonhomme}"
SCHEME_WATCH="${SCHEME_WATCH:-BonhommeWatch}"
CONFIGURATION="${CONFIGURATION:-Debug}"
DERIVED="${DERIVED:-/tmp/NATURaL-device-dd}"
PROJECT="${PROJECT:-NATURaL.xcodeproj}"
BUNDLE_IOS="${BUNDLE_IOS:-com.natural.Bonhomme}"
BUNDLE_WATCH="${BUNDLE_WATCH:-com.natural.BonhommeWatch}"

usage() {
  cat <<'EOF'
Usage: scripts/install-device.sh <command>

Commands:
  check           List devices and report LPhone / LP++ availability
  install-ios     Build Bonhomme (Debug) and install on LPhone
  install-watch   Build BonhommeWatch and install on LP++ (best effort)
  install-all     check → install-ios → install-watch
  help            Show this help

Environment overrides:
  IPHONE_UDID IPHONE_CORE WATCH_UDID WATCH_CORE TEAM_ID
  SCHEME_IOS SCHEME_WATCH CONFIGURATION DERIVED PROJECT

Docs: Docs/ON_DEVICE_INSTALL.md
EOF
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

device_list_devicectl() {
  if have_cmd xcrun; then
    xcrun devicectl list devices 2>/dev/null || true
  fi
}

device_list_xctrace() {
  if have_cmd xcrun; then
    xcrun xctrace list devices 2>/dev/null || true
  fi
}

# Returns 0 if needle appears in device listings (case-insensitive for names).
device_mentioned() {
  local needle="$1"
  local blob
  blob="$(device_list_devicectl; device_list_xctrace)"
  printf '%s\n' "$blob" | grep -Fqi -- "$needle"
}

# True if a device table line looks ready (not unavailable / offline / shutdown).
_line_looks_ready() {
  local line="$1"
  # Explicit bad states first (substring "available" is inside "unavailable")
  if printf '%s' "$line" | grep -Eiq 'unavailable|offline|shutdown|disconnected'; then
    return 1
  fi
  # Ready / transitional states that can accept install shortly
  if printf '%s' "$line" | grep -Eiq '(^|[[:space:]])available([[:space:]]|\(|$)|available \(paired\)|connecting|connected'; then
    return 0
  fi
  return 1
}

iphone_available() {
  # Prefer CoreDevice line for LPhone
  local dc line
  dc="$(device_list_devicectl)"
  while IFS= read -r line; do
    if printf '%s' "$line" | grep -Fq "LPhone"; then
      if _line_looks_ready "$line"; then
        return 0
      fi
    fi
  done <<<"$dc"
  # xctrace: hardware UDID listed under == Devices == (not Offline)
  local xt
  xt="$(device_list_xctrace)"
  if printf '%s\n' "$xt" | awk '
    /^== Devices ==$/ { in_on=1; next }
    /^== Devices Offline ==$/ { in_on=0; next }
    /^== Simulators ==$/ { in_on=0; next }
    in_on && /LPhone|00008130-00121D5E22F8001C/ { found=1 }
    END { exit found ? 0 : 1 }
  '; then
    return 0
  fi
  return 1
}

watch_available() {
  local dc line
  dc="$(device_list_devicectl)"
  while IFS= read -r line; do
    if printf '%s' "$line" | grep -Eq 'LP\+\+|LP\+\+\.watchOS|3984BED7-ECA4-5196-B4A3-F7651AC4C5FE'; then
      if _line_looks_ready "$line"; then
        return 0
      fi
    fi
  done <<<"$dc"
  local xt
  xt="$(device_list_xctrace)"
  if printf '%s\n' "$xt" | awk '
    /^== Devices ==$/ { in_on=1; next }
    /^== Devices Offline ==$/ { in_on=0; next }
    /^== Simulators ==$/ { in_on=0; next }
    in_on && /LP\+\+|00008310-000671A11490E01E/ { found=1 }
    END { exit found ? 0 : 1 }
  '; then
    return 0
  fi
  return 1
}

cmd_check() {
  echo "=== CoreDevice (devicectl) ==="
  device_list_devicectl || echo "(devicectl unavailable)"
  echo
  echo "=== xctrace devices (snippet) ==="
  device_list_xctrace | grep -E 'LPhone|LP\+\+|LPad|00008130|00008310|00008120|== Devices' || true
  echo
  echo "=== Configured IDs ==="
  echo "  LPhone  UDID=$IPHONE_UDID  CORE=$IPHONE_CORE"
  echo "  LP++    UDID=$WATCH_UDID   CORE=$WATCH_CORE"
  echo "  TEAM_ID=$TEAM_ID  DERIVED=$DERIVED"
  echo
  local ok=0
  if device_mentioned "$IPHONE_UDID" || device_mentioned "LPhone"; then
    if iphone_available; then
      echo "[OK]   LPhone appears available for install"
    else
      echo "[WARN] LPhone is known but offline / unavailable (plug USB, unlock, fix tunnel — Docs/ON_DEVICE_INSTALL.md §4)"
      ok=1
    fi
  else
    echo "[MISS] LPhone not in device inventory"
    ok=1
  fi
  if device_mentioned "$WATCH_UDID" || device_mentioned "LP++"; then
    if watch_available; then
      echo "[OK]   LP++ Watch appears available (or paired-available)"
    else
      echo "[WARN] LP++ known but offline / unavailable"
      ok=1
    fi
  else
    echo "[MISS] LP++ Watch not in device inventory"
    ok=1
  fi
  if [[ ! -f "$ROOT/Bonhomme/Bonhomme.entitlements" ]]; then
    echo "[MISS] Bonhomme/Bonhomme.entitlements"
    ok=1
  else
    echo "[OK]   Entitlements present (will not strip; see Docs/ON_DEVICE_INSTALL.md §3)"
  fi
  return "$ok"
}

find_app() {
  local pattern="$1"
  find "$DERIVED/Build/Products" -path "$pattern" 2>/dev/null | head -1
}

build_scheme() {
  local scheme="$1"
  local destination="$2"
  echo "=== xcodebuild scheme=$scheme destination=$destination ==="
  xcodebuild \
    -project "$PROJECT" \
    -scheme "$scheme" \
    -configuration "$CONFIGURATION" \
    -destination "$destination" \
    -derivedDataPath "$DERIVED" \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_STYLE=Automatic \
    build
}

install_app() {
  local device_ref="$1"
  local app_path="$2"
  if [[ -z "$app_path" || ! -d "$app_path" ]]; then
    echo "error: app not found at '$app_path'" >&2
    return 1
  fi
  echo "=== devicectl install → $device_ref ==="
  echo "    $app_path"
  xcrun devicectl device install app --device "$device_ref" "$app_path"
}

cmd_install_ios() {
  if ! iphone_available; then
    echo "error: LPhone not available. Run: $0 check" >&2
    echo "Hint: USB unlock + Developer Mode; see Docs/ON_DEVICE_INSTALL.md" >&2
    return 1
  fi
  build_scheme "$SCHEME_IOS" "platform=iOS,id=$IPHONE_UDID"
  local app
  app="$(find_app '*/Debug-iphoneos/Bonhomme.app')"
  if [[ -z "$app" ]]; then
    app="$(find_app '*/Bonhomme.app')"
  fi
  install_app "$IPHONE_CORE" "$app"
  echo "=== launch $BUNDLE_IOS (best effort) ==="
  xcrun devicectl device process launch --device "$IPHONE_CORE" "$BUNDLE_IOS" || true
  echo "Done (iOS)."
}

cmd_install_watch() {
  if ! watch_available; then
    echo "error: LP++ Watch not available. Run: $0 check" >&2
    return 1
  fi
  # Watch destinations vary by Xcode; try hardware UDID first.
  if ! build_scheme "$SCHEME_WATCH" "platform=watchOS,id=$WATCH_UDID"; then
    echo "warn: direct Watch destination failed; try Xcode UI or install via Bonhomme→LPhone" >&2
    return 1
  fi
  local app
  app="$(find_app '*/Debug-watchos/BonhommeWatch.app')"
  if [[ -z "$app" ]]; then
    app="$(find_app '*/BonhommeWatch.app')"
  fi
  install_app "$WATCH_CORE" "$app"
  echo "Done (watchOS)."
}

cmd_install_all() {
  cmd_check || true
  cmd_install_ios
  cmd_install_watch || {
    echo "warn: Watch install failed; phone install may still be OK." >&2
    return 1
  }
}

main() {
  local cmd="${1:-help}"
  case "$cmd" in
    check) cmd_check ;;
    install-ios) cmd_install_ios ;;
    install-watch) cmd_install_watch ;;
    install-all) cmd_install_all ;;
    help|-h|--help) usage ;;
    *)
      echo "Unknown command: $cmd" >&2
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
