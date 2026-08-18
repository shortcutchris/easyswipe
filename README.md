# EasySwipe

EasySwipe is a small native macOS menu bar app for arranging a window directly from its title bar.

[Website](https://easyswipe.shortcutchris.chatgpt.site) · [Download the latest release](https://github.com/shortcutchris/easyswipe-releases/releases/latest) · [Release repository](https://github.com/shortcutchris/easyswipe-releases)

- Swipe left to fill the left half of the current display.
- Swipe right to fill the right half.
- Swipe down to minimize.
- Swipe up to maximize within the usable desktop area.

The gesture uses two fingers on a MacBook or Magic Trackpad and the continuous touch surface of an Apple Magic Mouse. EasySwipe normalizes the physical direction independently of the macOS natural-scrolling setting, ignores momentum, and leaves ordinary scrolling untouched.

## Current release

Version `0.1.0` implements the complete source-level MVP:

- title-bar targeting through the macOS Accessibility API;
- left/right window snapping and normal-window maximization based on `NSScreen.visibleFrame`;
- window minimization;
- immediate cursor-adjacent HUD direction previews with brief action confirmation;
- compatibility handling for Warp's custom macOS title-bar toolbar;
- a dedicated macOS application icon;
- menu bar controls and first-run permission onboarding;
- launch-at-login support through `SMAppService`;
- English and German String Catalog localizations;
- Sparkle 2.9.6 update integration with a public signed update feed;
- Universal 2 release builds for Apple Silicon and Intel.

EasySwipe requires macOS 14 or newer and Accessibility permission. It has no telemetry and does not store window titles, app names, pointer paths, or gesture history.

## Build

Requirements:

- Xcode 26 or newer;
- [XcodeGen](https://github.com/yonaskolb/XcodeGen).

Generate the project and open it in Xcode:

```sh
xcodegen generate
open EasySwipe.xcodeproj
```

The checked-in project is generated from `project.yml`; edit the specification and regenerate instead of hand-editing the project file.

## Test and verify

The repository includes a remote Mac Studio runner:

```sh
scripts/remote-studio.sh doctor
scripts/remote-studio.sh test
scripts/remote-studio.sh verify
scripts/remote-studio.sh fetch
EASYSWIPE_CODE_SIGN_IDENTITY='Developer ID Application: NAME (TEAMID)' \
  scripts/remote-studio.sh local-sign
```

`verify` runs all unit tests, produces an ad-hoc-signed Release app, verifies its nested code signatures, launches a short-lived startup probe, asserts `LSUIElement`, and requires both `arm64` and `x86_64` architectures. The ad-hoc artifact uses a development-only entitlement so Hardened Runtime can load the separately signed Sparkle framework. Production archives retain Library Validation and use Developer ID signing. `fetch` copies the app, development ZIP, and verification manifest into the ignored local `artifacts/` directory.

`local-sign` re-signs the fetched app and all embedded Sparkle helpers with a Developer ID identity from the local Keychain. This gives successive hands-on builds a stable macOS code identity so Accessibility permission can persist. It removes the development-only entitlements and writes `artifacts/signing-verification.json`. This local candidate is not notarized and is not a public release.

## Updates and distribution

Sparkle is integrated and every current build contains these public update settings:

- Feed: `https://raw.githubusercontent.com/shortcutchris/easyswipe-releases/main/appcast.xml`
- Releases: `https://github.com/shortcutchris/easyswipe-releases/releases`
- Sparkle EdDSA public key in `SUPublicEDKey`

The matching private Sparkle key remains in the local macOS Keychain. Developer ID and notarization credentials are also kept outside both repositories. See [docs/RELEASING.md](docs/RELEASING.md) for the guarded publication workflow.

After storing Apple notarization credentials in a local `notarytool` Keychain profile, the complete verified release is published with `EASYSWIPE_NOTARY_PROFILE='EasySwipe' scripts/release.sh`.

## Documentation

- [MVP product and technical specification](docs/MVP-SPEC.md)
- [Remote development workflow](docs/REMOTE_DEVELOPMENT.md)
- [Release and Sparkle setup](docs/RELEASING.md)

## License

EasySwipe is open source under the [MIT License](LICENSE).
