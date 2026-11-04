#!/bin/zsh
set -euo pipefail
ROOT="${0:A:h:h}"
STAGE="${1:?Pass the prepared release workspace}"
[[ "$STAGE" == "$ROOT/artifacts/releases/"* ]] || exit 2
HOST=chris@mac-studio-von-chris-56.tailf17cde.ts.net
REMOTE=/Users/chris/Developer/EasySwipeUpdateQA
SSH=(ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=yes "$HOST")
BUILD=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$STAGE/EasySwipe.app/Contents/Info.plist")
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$STAGE/EasySwipe.app/Contents/Info.plist")
ARCHIVE="$STAGE/EasySwipe-$VERSION-$BUILD.zip"
mkdir -p "$ROOT/artifacts/update-qa"
curl --fail --silent --show-error --location https://github.com/shortcutchris/easyswipe-releases/releases/latest/download/Swindoo.zip -o "$ROOT/artifacts/update-qa/previous.zip"
"${SSH[@]}" "set -eu; ! pgrep -f '/MacOS/EasySwipe$'; mkdir -p '$REMOTE/server'; rm -rf '$REMOTE/installed' '$REMOTE/roundtrip.xcresult'; mkdir -p '$REMOTE/installed'"
rsync -az "$ROOT/artifacts/update-qa/previous.zip" "$HOST:$REMOTE/previous.zip"
rsync -az "$ARCHIVE" "$HOST:$REMOTE/server/candidate.zip"
"${SSH[@]}" "ditto -x -k '$REMOTE/previous.zip' '$REMOTE/installed'; codesign --verify --deep --strict '$REMOTE/installed/EasySwipe.app'"
PREVIOUS_BUILD=$("${SSH[@]}" "/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' '$REMOTE/installed/EasySwipe.app/Contents/Info.plist'")
python3 "$ROOT/scripts/prepare-update-qa.py" "$STAGE" "$ROOT/artifacts/update-qa" "$PREVIOUS_BUILD" "$BUILD"
rsync -az "$ROOT/artifacts/update-qa/appcast.xml" "$HOST:$REMOTE/server/appcast.xml"
rsync -az "$ROOT/artifacts/update-qa/test-config.json" "$HOST:$REMOTE/test-config.json"
# Only this test-owned server is stopped. No existing process is killed to claim its port.
"${SSH[@]}" "set -eu; if lsof -tiTCP:18746 -sTCP:LISTEN; then exit 2; fi; nohup /usr/bin/python3 -m http.server 18746 --bind 127.0.0.1 --directory '$REMOTE/server' >'$REMOTE/server.log' 2>&1 </dev/null & echo \$! >'$REMOTE/server.pid'"
cleanup() { "${SSH[@]}" "kill \$(cat '$REMOTE/server.pid')" >/dev/null 2>&1 || true }
trap cleanup EXIT
"${SSH[@]}" "set -eu; cd /Users/chris/Developer/easyswipe; /opt/homebrew/bin/xcodegen generate; sudo -n launchctl asuser 501 sudo -n -u chris env HOME=/Users/chris USER=chris LOGNAME=chris DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer /usr/bin/xcodebuild test -project EasySwipe.xcodeproj -scheme EasySwipeUpdateTests -destination 'platform=macOS' -derivedDataPath /Users/chris/Developer/DerivedData/EasySwipe -resultBundlePath '$REMOTE/roundtrip.xcresult'; xcrun xcresulttool get test-results summary --path '$REMOTE/roundtrip.xcresult' --format json >'$REMOTE/summary.json'; codesign --verify --deep --strict '$REMOTE/installed/EasySwipe.app'; spctl --assess --type execute '$REMOTE/installed/EasySwipe.app'"
rsync -az "$HOST:$REMOTE/summary.json" "$ROOT/artifacts/update-qa/summary.json"
python3 - "$ROOT/artifacts/update-qa/summary.json" "$ARCHIVE" "$STAGE/update-roundtrip.json" "$(git -C "$ROOT" rev-parse HEAD)" "$BUILD" <<'PY'
import hashlib, json, sys
with open(sys.argv[1]) as handle: result = json.load(handle)
assert result['result'] == 'Passed' and result['failedTests'] == 0 and result['passedTests'] > 0
with open(sys.argv[2], 'rb') as handle: digest = hashlib.sha256(handle.read()).hexdigest()
with open(sys.argv[3], 'w') as handle:
    json.dump({'result': 'Passed', 'archiveSHA256': digest, 'sourceRevision': sys.argv[4], 'installedBuild': sys.argv[5], 'transport': 'isolated loopback fixture, production EdDSA signature', 'testSummary': result}, handle, indent=2)
PY
