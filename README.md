# EasySwipe

EasySwipe is a small native macOS menu bar app for arranging a window directly from its title bar.

- Swipe left to fill the left half of the current display.
- Swipe right to fill the right half.
- Swipe down to minimize.

The gesture uses two fingers on a MacBook or Magic Trackpad and the continuous touch surface of an Apple Magic Mouse. EasySwipe normalizes the physical direction independently of the macOS natural-scrolling setting, ignores momentum, and leaves ordinary scrolling untouched.

## Current release

Version `0.1.0` implements the complete source-level MVP:

- title-bar targeting through the macOS Accessibility API;
- left/right window snapping based on `NSScreen.visibleFrame`;
- window minimization;
- immediate nonactivating HUD direction previews with brief action confirmation;
- a dedicated macOS application icon;
- menu bar controls and first-run permission onboarding;
- launch-at-login support through `SMAppService`;
- English and German String Catalog localizations;
- Sparkle 2.9.6 update integration with release-time feed/key configuration;
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
```

`verify` runs all unit tests, produces an ad-hoc-signed Release app, verifies its nested code signatures, launches a short-lived startup probe, asserts `LSUIElement`, and requires both `arm64` and `x86_64` architectures. The ad-hoc artifact uses a development-only entitlement so Hardened Runtime can load the separately signed Sparkle framework. Production archives retain Library Validation and use Developer ID signing. `fetch` copies the app, development ZIP, and verification manifest into the ignored local `artifacts/` directory.

## Updates and distribution

Sparkle is integrated but development builds deliberately contain no update host or signing key. A production build must provide both build settings:

- `EASYSWIPE_FEED_URL` — an HTTPS appcast URL;
- `EASYSWIPE_SPARKLE_PUBLIC_KEY` — the Sparkle EdDSA public key.

The private Sparkle key, Developer ID credentials, and notarization credentials must never be committed. See [docs/RELEASING.md](docs/RELEASING.md) for the production signing and update workflow.

## Documentation

- [MVP product and technical specification](docs/MVP-SPEC.md)
- [Remote development workflow](docs/REMOTE_DEVELOPMENT.md)
- [Release and Sparkle setup](docs/RELEASING.md)
