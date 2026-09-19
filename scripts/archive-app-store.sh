#!/bin/bash
# Creates a local archive only. Does not upload or submit to Apple.
set -euo pipefail
cd "$(dirname "$0")/.."
build_number="${BUILD_NUMBER:?Set BUILD_NUMBER to a new App Store build number}"
[[ "$build_number" =~ ^[1-9][0-9]*$ ]] || { echo 'BUILD_NUMBER must be a positive integer' >&2; exit 1; }
platform="${PLATFORM:-ios}"
case "$platform" in
  ios) scheme=Bonhomme; destination='generic/platform=iOS'; preflight=() ;;
  macos) scheme=BonhommeMac; destination='generic/platform=macOS'; preflight=(--include-macos) ;;
  *) echo 'PLATFORM must be ios or macos' >&2; exit 1 ;;
esac
if ! xcode_version="$(xcodebuild -version 2>&1)" || [[ "$xcode_version" != Xcode* ]]; then
  echo 'Full Xcode is required to archive. Install Xcode and select it in Xcode > Settings > Locations > Command Line Tools (or set DEVELOPER_DIR).' >&2
  echo "$xcode_version" >&2
  exit 1
fi
python3 scripts/validate-submission.py "${preflight[@]}"
archive_name="NATURaL-$build_number"
[[ "$platform" == ios ]] || archive_name="NATURaL-macOS-$build_number"
archive_path="$PWD/build/AppStore/$archive_name.xcarchive"
[[ ! -e "$archive_path" ]] || { echo "Archive already exists: $archive_path" >&2; exit 1; }
mkdir -p "$PWD/build/AppStore"
receipt_dir="$(mktemp -d "$PWD/build/AppStore/$archive_name-attempt.XXXXXX")"
printf '%s\n' "$xcode_version" > "$receipt_dir/xcode-version.txt"
echo "Archive log and result bundle: $receipt_dir"
xcodebuild archive \
  -project NATURaL.xcodeproj -scheme "$scheme" \
  -configuration Release -destination "$destination" \
  -archivePath "$archive_path" \
  -resultBundlePath "$receipt_dir/archive.xcresult" \
  -derivedDataPath "$PWD/build/submission/DerivedData-$platform" \
  DEVELOPMENT_TEAM=ZJLX84G8QV CURRENT_PROJECT_VERSION="$build_number" 2>&1 \
  | tee "$receipt_dir/archive.log"
python3 scripts/validate-archive.py "$archive_path" --platform "$platform" --build-number "$build_number" 2>&1 \
  | tee "$receipt_dir/validation.log"
echo "Archive created: $archive_path"
echo 'Use Xcode Organizer to Validate App, then Distribute App when ready.'
