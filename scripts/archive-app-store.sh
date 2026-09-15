#!/bin/bash
# Creates a local archive only. Does not upload or submit to Apple.
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/validate-submission.py
build_number="${BUILD_NUMBER:?Set BUILD_NUMBER to a new App Store build number}"
[[ "$build_number" =~ ^[1-9][0-9]*$ ]] || { echo 'BUILD_NUMBER must be a positive integer' >&2; exit 1; }
archive_path="$PWD/build/AppStore/NATURaL-$build_number.xcarchive"
[[ ! -e "$archive_path" ]] || { echo "Archive already exists: $archive_path" >&2; exit 1; }
xcodebuild archive \
  -project NATURaL.xcodeproj -scheme Bonhomme \
  -configuration Release -destination 'generic/platform=iOS' \
  -archivePath "$archive_path" \
  -derivedDataPath "$PWD/build/submission/DerivedData" \
  DEVELOPMENT_TEAM=ZJLX84G8QV CURRENT_PROJECT_VERSION="$build_number"
echo "Archive created: $archive_path"
echo 'Use Xcode Organizer to Validate App, then Distribute App when ready.'
