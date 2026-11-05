#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Native verification requires macOS with Xcode 26 or later. No iOS build was run."
  exit 2
fi
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Install XcodeGen, then rerun: brew install xcodegen"
  exit 2
fi
XCODE_MAJOR="$(xcodebuild -version | head -n 1 | awk '{print $2}' | cut -d. -f1)"
if [[ "$XCODE_MAJOR" -lt 26 ]]; then
  echo "Use Xcode 26 or later for current iOS upload requirements."
  exit 2
fi
xcodegen generate --spec project.yml
plutil -lint WishExplorer/Info.plist WishExplorer/PrivacyInfo.xcprivacy
DESTINATION="${WISH_TEST_DESTINATION:-}"
if [[ -z "$DESTINATION" ]]; then
  IPAD_UDID="$(xcrun simctl list devices available --json | python3 -c '
import json, re, sys
devices = json.load(sys.stdin).get("devices", {})
candidates = []
for runtime, entries in devices.items():
    if ".iOS-" not in runtime:
        continue
    version = tuple(int(part) for part in re.findall(r"\d+", runtime))
    for device in entries:
        if device.get("isAvailable", True) and device.get("name", "").startswith("iPad"):
            candidates.append((version, device["name"], device["udid"]))
if not candidates:
    raise SystemExit("No available iPad simulator. Install an iPad simulator runtime in Xcode, or set WISH_TEST_DESTINATION.")
version, name, udid = max(candidates)
print("Testing on " + name + " (iOS " + ".".join(map(str, version)) + ")", file=sys.stderr)
print(udid)
')"
  DESTINATION="platform=iOS Simulator,id=$IPAD_UDID"
fi
xcodebuild test \
  -project WishExplorer.xcodeproj \
  -scheme WishExplorer \
  -destination "$DESTINATION" \
  -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO
