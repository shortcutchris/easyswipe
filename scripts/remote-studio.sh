#!/bin/zsh

set -euo pipefail

readonly SCRIPT_DIR="${0:A:h}"
readonly REPOSITORY_ROOT="${SCRIPT_DIR:h}"
readonly REMOTE_HOST="${EASYSWIPE_REMOTE_HOST:-chris@mac-studio-von-chris-56.tailf17cde.ts.net}"
readonly REMOTE_ROOT="${EASYSWIPE_REMOTE_ROOT:-/Users/chris/Developer/easyswipe}"
readonly DERIVED_DATA="${EASYSWIPE_DERIVED_DATA:-/Users/chris/Developer/DerivedData/EasySwipe}"
readonly RELEASE_DERIVED_DATA="${EASYSWIPE_RELEASE_DERIVED_DATA:-/Users/chris/Developer/DerivedData/EasySwipe-Release}"
readonly ARTIFACTS_ROOT="${EASYSWIPE_ARTIFACTS_ROOT:-/Users/chris/Developer/EasySwipeArtifacts}"
readonly RESULT_BUNDLE="${ARTIFACTS_ROOT}/EasySwipeTests.xcresult"
readonly SUMMARY_FILE="${ARTIFACTS_ROOT}/EasySwipeTests-summary.json"
readonly STAGED_APP="${ARTIFACTS_ROOT}/EasySwipe.app"
readonly STAGED_ZIP="${ARTIFACTS_ROOT}/EasySwipe-0.1.0-development.zip"
readonly LOCAL_APP="${REPOSITORY_ROOT}/artifacts/EasySwipe.app"
readonly LOCAL_SIGNING_MANIFEST="${REPOSITORY_ROOT}/artifacts/signing-verification.json"
readonly SSH_OPTIONS=(-o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=yes)

validate_remote_path() {
  if [[ "${REMOTE_ROOT}" != /Users/chris/Developer/* || "${REMOTE_ROOT}" == "/Users/chris/Developer/" ]]; then
    print -u2 "Refusing unsafe remote root: ${REMOTE_ROOT}"
    exit 2
  fi
}

remote() {
  ssh "${SSH_OPTIONS[@]}" "${REMOTE_HOST}" "$@"
}

doctor() {
  remote "set -eu
    /bin/hostname
    /usr/bin/xcodebuild -version
    /usr/bin/xcode-select -p
    /bin/test -x /opt/homebrew/bin/xcodegen
    /opt/homebrew/bin/xcodegen --version
    /bin/df -h /Users/chris/Developer
    /usr/bin/stat -f '%Su' /dev/console"
}

sync_sources() {
  validate_remote_path
  local revision
  revision="$(git -C "${REPOSITORY_ROOT}" rev-parse HEAD 2>/dev/null || print unknown)"

  remote "/bin/mkdir -p '${REMOTE_ROOT}' '${DERIVED_DATA}' '${RELEASE_DERIVED_DATA}' '${ARTIFACTS_ROOT}'
    /bin/rm -rf '${RESULT_BUNDLE}' '${STAGED_APP}'
    /bin/rm -f '${SUMMARY_FILE}' '${STAGED_ZIP}' '${ARTIFACTS_ROOT}/verification.json'"

  rsync -az --delete \
    --exclude '.git/' \
    --exclude '.DS_Store' \
    --exclude 'DerivedData/' \
    --exclude '.build/' \
    --exclude '.swiftpm/' \
    --exclude 'build/' \
    --exclude 'artifacts/' \
    --exclude '*.xcresult' \
    --exclude '*.profraw' \
    --exclude 'xcuserdata/' \
    --exclude '*.p8' \
    --exclude '*.p12' \
    --exclude '*.cer' \
    --exclude '.env' \
    --exclude '.env.*' \
    "${REPOSITORY_ROOT}/" "${REMOTE_HOST}:${REMOTE_ROOT}/"

  remote "/usr/bin/printf '%s\n' '${revision}' > '${REMOTE_ROOT}/.remote-source-revision'"
}

generate_project() {
  remote "cd '${REMOTE_ROOT}' && /opt/homebrew/bin/xcodegen generate"
}

build_project() {
  generate_project
  remote "cd '${REMOTE_ROOT}' && DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
    /usr/bin/caffeinate -dims \
    /usr/bin/xcodebuild build \
      -project EasySwipe.xcodeproj \
      -scheme EasySwipe \
      -configuration Debug \
      -destination 'platform=macOS' \
      -derivedDataPath '${DERIVED_DATA}'"
}

release_project() {
  generate_project
  remote "set -eu
    /bin/mkdir -p '${ARTIFACTS_ROOT}'
    /bin/rm -rf '${STAGED_APP}'
    /bin/rm -f '${STAGED_ZIP}'
    cd '${REMOTE_ROOT}'
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
      /usr/bin/caffeinate -dims \
      /usr/bin/xcodebuild clean build \
        -project EasySwipe.xcodeproj \
        -scheme EasySwipe \
        -configuration Release \
        -destination 'generic/platform=macOS' \
        -derivedDataPath '${RELEASE_DERIVED_DATA}' \
        ARCHS='arm64 x86_64' \
        ONLY_ACTIVE_ARCH=NO \
        CLANG_ENABLE_CODE_COVERAGE=NO \
        CODE_SIGN_ENTITLEMENTS=Config/EasySwipeDevelopment.entitlements
    /bin/cp -R '${RELEASE_DERIVED_DATA}/Build/Products/Release/EasySwipe.app' '${STAGED_APP}'
    /usr/bin/codesign --verify --deep --strict --verbose=2 '${STAGED_APP}'
    /usr/bin/codesign -d --verbose=4 '${STAGED_APP}' 2>&1 | /usr/bin/grep -q 'flags=.*runtime'
    if /usr/bin/nm -a '${STAGED_APP}/Contents/MacOS/EasySwipe' | /usr/bin/grep -q llvm_profile; then
      /usr/bin/printf 'Release executable contains coverage instrumentation\\n' >&2
      exit 4
    fi
    architectures=\"\$(/usr/bin/lipo -archs '${STAGED_APP}/Contents/MacOS/EasySwipe')\"
    case \" \${architectures} \" in
      *' arm64 '*) ;;
      *) /usr/bin/printf 'Missing arm64 architecture: %s\\n' \"\${architectures}\" >&2; exit 3 ;;
    esac
    case \" \${architectures} \" in
      *' x86_64 '*) ;;
      *) /usr/bin/printf 'Missing x86_64 architecture: %s\\n' \"\${architectures}\" >&2; exit 3 ;;
    esac
    /bin/test \"\$(/usr/bin/plutil -extract LSUIElement raw -o - '${STAGED_APP}/Contents/Info.plist')\" = true
    /bin/test \"\$(/usr/bin/plutil -extract CFBundleShortVersionString raw -o - '${STAGED_APP}/Contents/Info.plist')\" = 0.1.0
    /bin/test \"\$(/usr/bin/plutil -extract CFBundleVersion raw -o - '${STAGED_APP}/Contents/Info.plist')\" = 7
    /bin/test \"\$(/usr/bin/plutil -extract CFBundleIconFile raw -o - '${STAGED_APP}/Contents/Info.plist')\" = AppIcon
    /bin/test -f '${STAGED_APP}/Contents/Resources/AppIcon.icns'
    EASYSWIPE_STARTUP_PROBE=1 '${STAGED_APP}/Contents/MacOS/EasySwipe'
    /usr/bin/ditto -c -k --sequesterRsrc --keepParent '${STAGED_APP}' '${STAGED_ZIP}'
    /usr/bin/printf 'Release architectures: %s; startup probe: passed\\n' \"\${architectures}\""
}

test_project() {
  generate_project
  remote "/bin/mkdir -p '${ARTIFACTS_ROOT}'
    /bin/rm -rf '${RESULT_BUNDLE}'
    cd '${REMOTE_ROOT}'
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
      /usr/bin/caffeinate -dims \
      /usr/bin/xcodebuild test \
        -project EasySwipe.xcodeproj \
        -scheme EasySwipe \
        -configuration Debug \
        -destination 'platform=macOS' \
        -derivedDataPath '${DERIVED_DATA}' \
        -enableCodeCoverage YES \
        -resultBundlePath '${RESULT_BUNDLE}'
    DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
      /usr/bin/xcrun xcresulttool get test-results summary \
        --path '${RESULT_BUNDLE}' \
        --format json > '${SUMMARY_FILE}'
    /usr/bin/python3 - '${SUMMARY_FILE}' <<'PY'
import json
import sys

with open(sys.argv[1], encoding='utf-8') as handle:
    summary = json.load(handle)

result = summary.get('result')
failed = int(summary.get('failedTests', 0))
if result != 'Passed' or failed != 0:
    raise SystemExit(f'Test validation failed: result={result!r}, failedTests={failed}')

print(json.dumps({
    'result': result,
    'passedTests': int(summary.get('passedTests', 0)),
    'skippedTests': int(summary.get('skippedTests', 0)),
    'failedTests': failed,
    'totalTestCount': int(summary.get('totalTestCount', 0)),
}, sort_keys=True))
PY"
}

verify_project() {
  test_project
  release_project
  remote "/usr/bin/python3 - '${SUMMARY_FILE}' '${REMOTE_ROOT}/.remote-source-revision' '${STAGED_APP}' '${ARTIFACTS_ROOT}/verification.json' <<'PY'
import datetime
import json
import plistlib
import subprocess
import sys

with open(sys.argv[1], encoding='utf-8') as handle:
    summary = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    revision = handle.read().strip()
app_path = sys.argv[3]
with open(f'{app_path}/Contents/Info.plist', 'rb') as handle:
    info = plistlib.load(handle)
architectures = subprocess.check_output(
    ['/usr/bin/lipo', '-archs', f'{app_path}/Contents/MacOS/EasySwipe'],
    text=True,
).split()

manifest = {
    'sourceRevision': revision,
    'verifiedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'configuration': 'Release',
    'architectures': architectures,
    'bundleIdentifier': info['CFBundleIdentifier'],
    'version': info['CFBundleShortVersionString'],
    'build': info['CFBundleVersion'],
    'appIcon': info.get('CFBundleIconFile') == 'AppIcon',
    'menuBarOnly': bool(info['LSUIElement']),
    'hardenedRuntime': True,
    'libraryValidationDisabledForAdHocBuild': True,
    'coverageInstrumented': False,
    'startupProbe': 'Passed',
    'codeSigning': 'ad-hoc development',
    'result': summary.get('result'),
    'passedTests': int(summary.get('passedTests', 0)),
    'skippedTests': int(summary.get('skippedTests', 0)),
    'failedTests': int(summary.get('failedTests', 0)),
    'totalTestCount': int(summary.get('totalTestCount', 0)),
}

with open(sys.argv[4], 'w', encoding='utf-8') as handle:
    json.dump(manifest, handle, indent=2, sort_keys=True)
    handle.write('\n')
print(json.dumps(manifest, sort_keys=True))
PY"
}

fetch_artifact() {
  mkdir -p "${REPOSITORY_ROOT}/artifacts"
  rsync -az "${REMOTE_HOST}:${STAGED_APP}" "${REPOSITORY_ROOT}/artifacts/"
  rsync -az "${REMOTE_HOST}:${STAGED_ZIP}" "${REPOSITORY_ROOT}/artifacts/"
  rsync -az "${REMOTE_HOST}:${ARTIFACTS_ROOT}/verification.json" "${REPOSITORY_ROOT}/artifacts/"
}

sign_local_artifact() {
  local identity="${EASYSWIPE_CODE_SIGN_IDENTITY:-}"
  if [[ -z "${identity}" ]]; then
    print -u2 "Set EASYSWIPE_CODE_SIGN_IDENTITY to a Developer ID Application identity."
    exit 2
  fi
  if [[ ! -d "${LOCAL_APP}" ]]; then
    print -u2 "Fetch a verified artifact before local signing: ${LOCAL_APP}"
    exit 2
  fi
  if [[ ! -f "${REPOSITORY_ROOT}/artifacts/verification.json" ]]; then
    print -u2 "Missing verification manifest; fetch the current artifact first."
    exit 2
  fi

  local source_revision artifact_revision
  source_revision="$(git -C "${REPOSITORY_ROOT}" rev-parse HEAD)"
  artifact_revision="$(/usr/bin/python3 -c \
    'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["sourceRevision"])' \
    "${REPOSITORY_ROOT}/artifacts/verification.json")"
  if [[ "${artifact_revision}" != "${source_revision}" ]]; then
    print -u2 "Refusing stale artifact: expected ${source_revision}, found ${artifact_revision}."
    exit 3
  fi

  local sparkle="${LOCAL_APP}/Contents/Frameworks/Sparkle.framework/Versions/B"
  /usr/bin/codesign --force --sign "${identity}" --options runtime --timestamp \
    "${sparkle}/XPCServices/Installer.xpc"
  /usr/bin/codesign --force --sign "${identity}" --options runtime --timestamp \
    --preserve-metadata=entitlements "${sparkle}/XPCServices/Downloader.xpc"
  /usr/bin/codesign --force --sign "${identity}" --options runtime --timestamp \
    "${sparkle}/Autoupdate"
  /usr/bin/codesign --force --sign "${identity}" --options runtime --timestamp \
    "${sparkle}/Updater.app"
  /usr/bin/codesign --force --sign "${identity}" --options runtime --timestamp \
    "${LOCAL_APP}/Contents/Frameworks/Sparkle.framework"
  /usr/bin/codesign --force --sign "${identity}" --options runtime --timestamp \
    --entitlements "${REPOSITORY_ROOT}/Config/EasySwipe.entitlements" "${LOCAL_APP}"

  /usr/bin/codesign --verify --deep --strict --verbose=2 "${LOCAL_APP}"
  local team_identifier
  team_identifier="$(/usr/bin/codesign -d --verbose=4 "${LOCAL_APP}" 2>&1 \
    | /usr/bin/sed -n 's/^TeamIdentifier=//p')"
  if [[ -z "${team_identifier}" || "${team_identifier}" == "not set" ]]; then
    print -u2 "Local signature has no stable TeamIdentifier."
    exit 3
  fi
  if /usr/bin/codesign -d --entitlements - "${LOCAL_APP}" 2>&1 \
    | /usr/bin/grep -q 'disable-library-validation\|get-task-allow'; then
    print -u2 "Local signed app retained development-only entitlements."
    exit 3
  fi

  EASYSWIPE_STARTUP_PROBE=1 "${LOCAL_APP}/Contents/MacOS/EasySwipe"
  /usr/bin/python3 - "${REPOSITORY_ROOT}/artifacts/verification.json" \
    "${LOCAL_SIGNING_MANIFEST}" "${identity}" "${team_identifier}" <<'PY'
import datetime
import json
import sys

with open(sys.argv[1], encoding='utf-8') as handle:
    remote = json.load(handle)

manifest = {
    'sourceRevision': remote['sourceRevision'],
    'build': remote['build'],
    'signedAt': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'identity': sys.argv[3],
    'teamIdentifier': sys.argv[4],
    'stablePrivacyIdentity': True,
    'nestedCodeSignatures': 'Passed',
    'startupProbe': 'Passed',
    'notarized': False,
}
with open(sys.argv[2], 'w', encoding='utf-8') as handle:
    json.dump(manifest, handle, indent=2, sort_keys=True)
    handle.write('\n')
print(json.dumps(manifest, sort_keys=True))
PY
}

usage() {
  print "Usage: $0 doctor|sync|build|test|release|verify|fetch|local-sign"
}

case "${1:-}" in
  doctor) doctor ;;
  sync) sync_sources ;;
  build) sync_sources; build_project ;;
  test) sync_sources; test_project ;;
  release) sync_sources; release_project ;;
  verify) sync_sources; verify_project ;;
  fetch) fetch_artifact ;;
  local-sign) sign_local_artifact ;;
  *) usage; exit 2 ;;
esac
