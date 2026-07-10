#!/usr/bin/env bash
# Cross-compile BonhommeAccel static libraries for Apple device SDKs.
#
# Produces:
#   BonhommeAccel/dist/iphoneos/libBonhommeAccel.a          (device arm64)
#   BonhommeAccel/dist/iphonesimulator/libBonhommeAccel.a   (sim arm64)
#   BonhommeAccel/dist/macos/libBonhommeAccel.a             (host, optional)
#   BonhommeAccel/dist/BonhommeAccel.xcframework            (device + sim)
#   BonhommeAccel/dist/manifest.txt
#
# Usage:
#   ./scripts/build-accel-apple.sh              # ios + iossim + xcframework
#   ./scripts/build-accel-apple.sh --with-macos
#   ./scripts/build-accel-apple.sh --with-watchos
#   ./scripts/build-accel-apple.sh --clean
#
# Link into apps: see BonhommeAccel/TESTING.md § Path C.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ACCEL="$ROOT/BonhommeAccel"
DIST="$ACCEL/dist"
JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"
WITH_MACOS=0
WITH_WATCHOS=0
WITH_TVOS=0
CLEAN=0
DEPLOYMENT_TARGET_IOS=17.0
DEPLOYMENT_TARGET_WATCH=10.0
DEPLOYMENT_TARGET_TV=17.0

for arg in "$@"; do
  case "$arg" in
    --with-macos) WITH_MACOS=1 ;;
    --with-watchos) WITH_WATCHOS=1 ;;
    --with-tvos) WITH_TVOS=1 ;;
    --clean) CLEAN=1 ;;
    -h|--help)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

if [[ "$CLEAN" -eq 1 ]]; then
  rm -rf \
    "$ACCEL/build-iphoneos" \
    "$ACCEL/build-iphonesimulator" \
    "$ACCEL/build-macos-ship" \
    "$ACCEL/build-watchos" \
    "$ACCEL/build-appletvos" \
    "$DIST"
  echo "Cleaned Accel Apple build trees and dist/"
  exit 0
fi

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "error: required command not found: $1" >&2
    exit 1
  }
}

need_cmd cmake
need_cmd xcrun
need_cmd lipo
need_cmd xcodebuild

# Prefer Ninja when available (faster); fall back to Unix Makefiles.
GENERATOR=()
if command -v ninja >/dev/null 2>&1; then
  GENERATOR=(-G Ninja)
fi

configure_and_build() {
  local name="$1"
  local system_name="$2"
  local sysroot="$3"
  local arch="$4"
  local deploy="$5"
  local metal="$6" # ON|OFF
  local build_dir="$ACCEL/build-${name}"
  local out_dir="$DIST/${name}"

  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo " Building BonhommeAccel → ${name} (${sysroot}, ${arch})"
  echo "═══════════════════════════════════════════════════════════"

  # shellcheck disable=SC2086
  cmake -B "$build_dir" -S "$ACCEL" \
    "${GENERATOR[@]}" \
    -DCMAKE_SYSTEM_NAME="$system_name" \
    -DCMAKE_OSX_SYSROOT="$sysroot" \
    -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$deploy" \
    -DCMAKE_SYSTEM_PROCESSOR=arm64 \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DBA_BUILD_TESTS=OFF \
    -DBA_ENABLE_OPENMP=OFF \
    -DBA_ENABLE_CUDA=OFF \
    -DBA_ENABLE_ROCM=OFF \
    -DBA_ENABLE_AVX2=OFF \
    -DBA_ENABLE_AVX512=OFF \
    -DBA_ENABLE_NEON=ON \
    -DBA_ENABLE_METAL="$metal"

  cmake --build "$build_dir" -j "$JOBS"

  local lib="$build_dir/libBonhommeAccel.a"
  if [[ ! -f "$lib" ]]; then
    echo "error: missing $lib" >&2
    exit 1
  fi

  mkdir -p "$out_dir"
  cp -f "$lib" "$out_dir/libBonhommeAccel.a"
  # Convenience copy of public header next to the archive.
  mkdir -p "$out_dir/include"
  cp -f "$ACCEL/include/BonhommeAccel.h" "$out_dir/include/"

  echo "→ $out_dir/libBonhommeAccel.a"
  file "$out_dir/libBonhommeAccel.a" || true
  lipo -info "$out_dir/libBonhommeAccel.a" 2>/dev/null || true
  # Sanity: C API symbols must exist for Swift import.
  # (nm may exit non-zero on multi-member archives; rely on grep only.)
  if ! nm "$out_dir/libBonhommeAccel.a" 2>/dev/null | grep -E 'ba_shannon_entropy' >/dev/null 2>&1; then
    echo "error: ba_shannon_entropy not found in $out_dir/libBonhommeAccel.a" >&2
    exit 1
  fi
  echo "  symbols: ba_shannon_entropy OK"
}

mkdir -p "$DIST"

# --- Required slices for shipping iOS apps ---
configure_and_build iphoneos iOS iphoneos arm64 "$DEPLOYMENT_TARGET_IOS" ON
configure_and_build iphonesimulator iOS iphonesimulator arm64 "$DEPLOYMENT_TARGET_IOS" ON

if [[ "$WITH_MACOS" -eq 1 ]]; then
  # Host macOS (not cross) — useful for BONHOMME_ACCEL=1 swift build on Mac.
  echo ""
  echo "═══════════════════════════════════════════════════════════"
  echo " Building BonhommeAccel → macos (host)"
  echo "═══════════════════════════════════════════════════════════"
  cmake -B "$ACCEL/build-macos-ship" -S "$ACCEL" \
    "${GENERATOR[@]}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBA_BUILD_TESTS=OFF \
    -DBA_ENABLE_OPENMP=OFF \
    -DBA_ENABLE_CUDA=OFF \
    -DBA_ENABLE_ROCM=OFF \
    -DBA_ENABLE_METAL=ON
  cmake --build "$ACCEL/build-macos-ship" -j "$JOBS"
  mkdir -p "$DIST/macos/include"
  cp -f "$ACCEL/build-macos-ship/libBonhommeAccel.a" "$DIST/macos/"
  cp -f "$ACCEL/include/BonhommeAccel.h" "$DIST/macos/include/"
  echo "→ $DIST/macos/libBonhommeAccel.a"
fi

if [[ "$WITH_WATCHOS" -eq 1 ]]; then
  # Metal on watchOS is limited; still enable if available (NEON is primary).
  configure_and_build watchos watchOS watchos arm64 "$DEPLOYMENT_TARGET_WATCH" OFF
fi

if [[ "$WITH_TVOS" -eq 1 ]]; then
  configure_and_build appletvos tvOS appletvos arm64 "$DEPLOYMENT_TARGET_TV" ON
fi

# --- XCFramework (device + simulator) for Xcode Link Binary With Libraries ---
echo ""
echo "═══════════════════════════════════════════════════════════"
echo " Creating BonhommeAccel.xcframework"
echo "═══════════════════════════════════════════════════════════"
rm -rf "$DIST/BonhommeAccel.xcframework"
xcodebuild -create-xcframework \
  -library "$DIST/iphoneos/libBonhommeAccel.a" \
  -headers "$DIST/iphoneos/include" \
  -library "$DIST/iphonesimulator/libBonhommeAccel.a" \
  -headers "$DIST/iphonesimulator/include" \
  -output "$DIST/BonhommeAccel.xcframework"

# Manifest for tooling / CI
{
  echo "BonhommeAccel Apple dist"
  echo "built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "ios_deployment_target=$DEPLOYMENT_TARGET_IOS"
  echo "iphoneos=$(lipo -info "$DIST/iphoneos/libBonhommeAccel.a" 2>/dev/null | sed 's/.*: //')"
  echo "iphonesimulator=$(lipo -info "$DIST/iphonesimulator/libBonhommeAccel.a" 2>/dev/null | sed 's/.*: //')"
  echo "xcframework=$DIST/BonhommeAccel.xcframework"
  echo "cmake_version=$(cmake --version | head -1)"
  echo "sdk_iphoneos=$(xcrun --sdk iphoneos --show-sdk-path)"
  echo "sdk_iphonesimulator=$(xcrun --sdk iphonesimulator --show-sdk-path)"
} >"$DIST/manifest.txt"

echo ""
echo "DONE. Shipping artifacts:"
echo "  $DIST/iphoneos/libBonhommeAccel.a"
echo "  $DIST/iphonesimulator/libBonhommeAccel.a"
echo "  $DIST/BonhommeAccel.xcframework"
echo "  $DIST/manifest.txt"
echo ""
echo "Enable Accel in BonhommeCore (device SDK must match lib):"
echo "  export BONHOMME_ACCEL=1"
echo "  export BONHOMME_ACCEL_LIB=\"$DIST/iphoneos\"   # or iphonesimulator / macos"
echo "See BonhommeAccel/TESTING.md § Path C."
