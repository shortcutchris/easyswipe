#!/bin/zsh

set -euo pipefail

readonly SCRIPT_DIR="${0:A:h}"
readonly REPOSITORY_ROOT="${SCRIPT_DIR:h}"
readonly PROJECT_FILE="${REPOSITORY_ROOT}/project.yml"
readonly VERSION="$(/usr/bin/awk '$1 == "MARKETING_VERSION:" { gsub(/"/, "", $2); print $2; exit }' "${PROJECT_FILE}")"
readonly BUILD="$(/usr/bin/awk '$1 == "CURRENT_PROJECT_VERSION:" { gsub(/"/, "", $2); print $2; exit }' "${PROJECT_FILE}")"
readonly TAG="v${VERSION}"
readonly RELEASE_REPOSITORY="${EASYSWIPE_RELEASE_REPOSITORY:-shortcutchris/easyswipe-releases}"
readonly RELEASE_CHECKOUT="${EASYSWIPE_RELEASE_CHECKOUT:-${REPOSITORY_ROOT:h}/easyswipe-releases}"
readonly NOTARY_PROFILE="${EASYSWIPE_NOTARY_PROFILE:-}"
readonly SPARKLE_ACCOUNT="${EASYSWIPE_SPARKLE_ACCOUNT:-com.shortcutchris.EasySwipe.updates}"
readonly FEED_URL="https://raw.githubusercontent.com/${RELEASE_REPOSITORY}/main/appcast.xml"
readonly RELEASE_URL_PREFIX="https://github.com/${RELEASE_REPOSITORY}/releases/download/${TAG}/"
readonly RELEASE_NOTES="${REPOSITORY_ROOT}/docs/releases/${VERSION}.md"
readonly LOCAL_APP="${REPOSITORY_ROOT}/artifacts/EasySwipe.app"
readonly SPARKLE_TOOLS="${REPOSITORY_ROOT}/artifacts/sparkle-tools"
readonly ARCHIVE_NAME="EasySwipe-${VERSION}-${BUILD}.zip"
readonly LATEST_ARCHIVE_NAME="EasySwipe.zip"
readonly RELEASES_ROOT="${REPOSITORY_ROOT}/artifacts/releases"
readonly RELEASE_RUN_ID="$(/bin/date -u +%Y%m%dT%H%M%SZ)"
readonly RELEASE_WORKSPACE="${RELEASES_ROOT}/${VERSION}-${BUILD}-${RELEASE_RUN_ID}"
readonly RELEASE_APP="${RELEASE_WORKSPACE}/EasySwipe.app"
readonly RELEASE_ARCHIVE="${RELEASE_WORKSPACE}/${ARCHIVE_NAME}"
readonly LATEST_ARCHIVE="${RELEASE_WORKSPACE}/${LATEST_ARCHIVE_NAME}"
readonly LATEST_DOWNLOAD_URL="https://github.com/${RELEASE_REPOSITORY}/releases/latest/download/${LATEST_ARCHIVE_NAME}"
readonly NOTARY_ARCHIVE="${RELEASES_ROOT}/EasySwipe-${VERSION}-${BUILD}-${RELEASE_RUN_ID}-notarization.zip"
readonly NOTARY_RESULT="${RELEASE_WORKSPACE}/notarization.json"
readonly GENERATED_FEED="${RELEASE_WORKSPACE}/appcast.xml"
readonly GENERATED_NOTES="${RELEASE_WORKSPACE}/${ARCHIVE_NAME:r}.md"
typeset SIGNING_IDENTITY=""

fail() {
  print -u2 "Release stopped: $*"
  exit 2
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Required command is unavailable: $1"
}

require_clean_repository() {
  local repository="$1"
  local label="$2"

  [[ -d "${repository}/.git" ]] || fail "${label} repository is missing: ${repository}"
  [[ -z "$(git -C "${repository}" status --porcelain)" ]] \
    || fail "${label} repository has uncommitted changes: ${repository}"
  [[ "$(git -C "${repository}" branch --show-current)" == main ]] \
    || fail "${label} repository must be on main."

  git -C "${repository}" fetch --quiet origin main
  [[ "$(git -C "${repository}" rev-parse HEAD)" == "$(git -C "${repository}" rev-parse origin/main)" ]] \
    || fail "${label} main must exactly match origin/main."
}

resolve_signing_identity() {
  local configured_identity="${EASYSWIPE_CODE_SIGN_IDENTITY:-}"
  local identities=()

  if [[ -n "${configured_identity}" ]]; then
    /usr/bin/security find-identity -v -p codesigning \
      | /usr/bin/grep -Fq "\"${configured_identity}\"" \
      || fail "Configured Developer ID identity is unavailable: ${configured_identity}"
    print -r -- "${configured_identity}"
    return
  fi

  identities=("${(@f)$(/usr/bin/security find-identity -v -p codesigning \
    | /usr/bin/sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p')}")
  if (( ${#identities[@]} != 1 )); then
    fail "Set EASYSWIPE_CODE_SIGN_IDENTITY; found ${#identities[@]} Developer ID Application identities."
  fi
  print -r -- "${identities[1]}"
}

validate_release_metadata() {
  [[ -n "${VERSION}" && -n "${BUILD}" ]] || fail "Version metadata is missing from project.yml."
  [[ "${VERSION}" == <->.<->.<-> ]] || fail "MARKETING_VERSION must use semantic versioning."
  [[ "${BUILD}" == <-> ]] || fail "CURRENT_PROJECT_VERSION must be numeric."
  [[ -f "${RELEASE_NOTES}" ]] || fail "Release notes are missing: ${RELEASE_NOTES}"
}

preflight() {
  require_command git
  require_command gh
  require_command rsync
  require_command xcrun
  validate_release_metadata
  require_clean_repository "${REPOSITORY_ROOT}" "Source"
  require_clean_repository "${RELEASE_CHECKOUT}" "Release"

  [[ -n "${NOTARY_PROFILE}" ]] \
    || fail "Set EASYSWIPE_NOTARY_PROFILE to a notarytool Keychain profile. Create one with: xcrun notarytool store-credentials EasySwipe"
  gh auth status >/dev/null 2>&1 || fail "GitHub CLI authentication is unavailable."
  [[ "$(gh repo view "${RELEASE_REPOSITORY}" --json visibility --jq .visibility)" == PUBLIC ]] \
    || fail "Release repository must be public: ${RELEASE_REPOSITORY}"
  gh release view "${TAG}" --repo "${RELEASE_REPOSITORY}" >/dev/null 2>&1 \
    && fail "GitHub release already exists: ${TAG}"
  git -C "${RELEASE_CHECKOUT}" show-ref --verify --quiet "refs/tags/${TAG}" \
    && fail "Release tag already exists locally: ${TAG}"

  /usr/bin/security find-generic-password -a "${SPARKLE_ACCOUNT}" >/dev/null 2>&1 \
    || fail "Sparkle private key is unavailable in the login Keychain for account ${SPARKLE_ACCOUNT}."
  xcrun notarytool history \
    --keychain-profile "${NOTARY_PROFILE}" \
    --output-format json >/dev/null \
    || fail "Notarization profile could not authenticate: ${NOTARY_PROFILE}"

  SIGNING_IDENTITY="$(resolve_signing_identity)"
  print "Preflight passed for EasySwipe ${VERSION} (${BUILD})."
  print "Developer ID: ${SIGNING_IDENTITY}"
}

verify_and_sign() {
  "${SCRIPT_DIR}/remote-studio.sh" verify
  "${SCRIPT_DIR}/remote-studio.sh" fetch
  [[ -x "${SPARKLE_TOOLS}/generate_appcast" ]] \
    || fail "Pinned Sparkle generate_appcast tool was not fetched."
  [[ -x "${SPARKLE_TOOLS}/sign_update" ]] \
    || fail "Pinned Sparkle sign_update tool was not fetched."

  EASYSWIPE_CODE_SIGN_IDENTITY="${SIGNING_IDENTITY}" \
    "${SCRIPT_DIR}/remote-studio.sh" local-sign
}

stage_and_notarize() {
  /bin/mkdir -p "${RELEASE_WORKSPACE}"
  [[ -z "$(/usr/bin/find "${RELEASE_WORKSPACE}" -mindepth 1 -maxdepth 1 -print -quit)" ]] \
    || fail "Release workspace is not empty: ${RELEASE_WORKSPACE}"

  /usr/bin/ditto "${LOCAL_APP}" "${RELEASE_APP}"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "${RELEASE_APP}"
  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "${RELEASE_APP}" "${NOTARY_ARCHIVE}"

  xcrun notarytool submit "${NOTARY_ARCHIVE}" \
    --keychain-profile "${NOTARY_PROFILE}" \
    --wait \
    --output-format json > "${NOTARY_RESULT}"
  /usr/bin/python3 - "${NOTARY_RESULT}" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as handle:
    result = json.load(handle)

if result.get("status") != "Accepted":
    raise SystemExit(f"Notarization was not accepted: {result}")
print(f"Notarization accepted: {result.get('id', 'unknown submission')}")
PY

  xcrun stapler staple "${RELEASE_APP}"
  xcrun stapler validate "${RELEASE_APP}"
  /usr/sbin/spctl --assess --type execute --verbose=2 "${RELEASE_APP}"

  /usr/bin/ditto -c -k --sequesterRsrc --keepParent "${RELEASE_APP}" "${RELEASE_ARCHIVE}"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "${RELEASE_APP}"
}

generate_and_validate_feed() {
  /bin/cp "${RELEASE_CHECKOUT}/appcast.xml" "${GENERATED_FEED}"
  /bin/cp "${RELEASE_NOTES}" "${GENERATED_NOTES}"
  "${SPARKLE_TOOLS}/generate_appcast" \
    --account "${SPARKLE_ACCOUNT}" \
    --download-url-prefix "${RELEASE_URL_PREFIX}" \
    --embed-release-notes \
    --maximum-versions 10 \
    "${RELEASE_WORKSPACE}"

  /usr/bin/xmllint --noout "${GENERATED_FEED}"
  local signature
  signature="$(/usr/bin/python3 - "${GENERATED_FEED}" "${VERSION}" "${BUILD}" "${RELEASE_URL_PREFIX}${ARCHIVE_NAME}" <<'PY'
import sys
import xml.etree.ElementTree as ET

feed_path, version, build, expected_url = sys.argv[1:]
sparkle = "http://www.andymatuschak.org/xml-namespaces/sparkle"
root = ET.parse(feed_path).getroot()

for item in root.findall("./channel/item"):
    enclosure = item.find("enclosure")
    if enclosure is None:
        continue
    item_version = item.findtext(f"{{{sparkle}}}version") or enclosure.get(
        f"{{{sparkle}}}version"
    )
    short_version = item.findtext(
        f"{{{sparkle}}}shortVersionString"
    ) or enclosure.get(f"{{{sparkle}}}shortVersionString")
    if item_version != build:
        continue
    if short_version != version:
        raise SystemExit("Generated appcast has the wrong short version.")
    if enclosure.get("url") != expected_url:
        raise SystemExit("Generated appcast has the wrong archive URL.")
    signature = enclosure.get(f"{{{sparkle}}}edSignature")
    if not signature:
        raise SystemExit("Generated appcast has no EdDSA signature.")
    print(signature)
    break
else:
    raise SystemExit("Generated appcast has no matching release item.")
PY
)"
  "${SPARKLE_TOOLS}/sign_update" \
    --account "${SPARKLE_ACCOUNT}" \
    --verify "${RELEASE_ARCHIVE}" "${signature}"
  /usr/bin/shasum -a 256 "${RELEASE_ARCHIVE}" > "${RELEASE_ARCHIVE}.sha256"
}

publish_release() {
  /bin/cp "${RELEASE_ARCHIVE}" "${LATEST_ARCHIVE}"
  /usr/bin/cmp "${RELEASE_ARCHIVE}" "${LATEST_ARCHIVE}"

  gh release create "${TAG}" \
    "${RELEASE_ARCHIVE}" \
    "${RELEASE_ARCHIVE}.sha256" \
    "${LATEST_ARCHIVE}" \
    --repo "${RELEASE_REPOSITORY}" \
    --title "EasySwipe ${VERSION}" \
    --notes-file "${RELEASE_NOTES}"

  /bin/cp "${GENERATED_FEED}" "${RELEASE_CHECKOUT}/appcast.xml"
  /bin/mkdir -p "${RELEASE_CHECKOUT}/release-notes"
  /bin/cp "${RELEASE_NOTES}" "${RELEASE_CHECKOUT}/release-notes/${VERSION}.md"
  git -C "${RELEASE_CHECKOUT}" add appcast.xml "release-notes/${VERSION}.md"
  git -C "${RELEASE_CHECKOUT}" commit -m "Publish EasySwipe ${VERSION} (${BUILD})"
  git -C "${RELEASE_CHECKOUT}" push origin main

  /usr/bin/curl --fail --silent --show-error --location \
    "${RELEASE_URL_PREFIX}${ARCHIVE_NAME}" >/dev/null
  /usr/bin/curl --fail --silent --show-error --location \
    --retry 5 --retry-all-errors --retry-delay 2 \
    "${LATEST_DOWNLOAD_URL}" >/dev/null
  gh api -H "Accept: application/vnd.github.raw+json" \
    "repos/${RELEASE_REPOSITORY}/contents/appcast.xml?ref=main" \
    | /usr/bin/grep -Fq "${RELEASE_URL_PREFIX}${ARCHIVE_NAME}" \
    || fail "Published feed does not reference the release archive."
}

main() {
  preflight
  if [[ "${1:-}" == "--check" ]]; then
    print "Release prerequisites are ready. No build or publication was performed."
    return
  fi
  [[ $# == 0 ]] || fail "Usage: scripts/release.sh [--check]"

  verify_and_sign
  stage_and_notarize
  generate_and_validate_feed
  publish_release
  print "EasySwipe ${VERSION} (${BUILD}) is published and live in the Sparkle feed."
}

main "$@"
