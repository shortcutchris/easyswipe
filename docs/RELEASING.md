# Releasing EasySwipe

The repository can produce a verified Universal 2 development build without secrets. Public releases require release-owner credentials and an HTTPS update host.

## Required private configuration

- an Apple Developer team with a `Developer ID Application` certificate;
- notarization credentials stored in a Keychain profile;
- a Sparkle EdDSA private key stored outside the repository;
- an HTTPS location for the appcast and update archive.

Only the Sparkle public key and appcast URL belong in the compiled app. Never commit private keys, certificate exports, Apple API keys, passwords, or notarization profiles.

The remote development artifact overrides `CODE_SIGN_ENTITLEMENTS` with `Config/EasySwipeDevelopment.entitlements` because an ad-hoc host cannot pass Library Validation for Sparkle's separately signed framework. Do not use that entitlement for production. The production `Release` configuration uses `Config/EasySwipe.entitlements` and a Developer ID signature.

## Versioning

Update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`, then regenerate `EasySwipe.xcodeproj`. The build number must increase for every published build.

## Production archive

Pass production values as command-line build settings or through a private Xcode configuration:

```sh
xcodebuild archive \
  -project EasySwipe.xcodeproj \
  -scheme EasySwipe \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath artifacts/EasySwipe.xcarchive \
  ARCHS='arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_STYLE=Manual \
  CODE_SIGN_IDENTITY='Developer ID Application: YOUR NAME (TEAMID)' \
  DEVELOPMENT_TEAM=TEAMID \
  EASYSWIPE_FEED_URL='https://updates.example.com/easyswipe/appcast.xml' \
  EASYSWIPE_SPARKLE_PUBLIC_KEY='YOUR_SPARKLE_PUBLIC_KEY'
```

Before distribution, verify the archive product:

```sh
codesign --verify --deep --strict --verbose=2 \
  artifacts/EasySwipe.xcarchive/Products/Applications/EasySwipe.app
lipo -archs \
  artifacts/EasySwipe.xcarchive/Products/Applications/EasySwipe.app/Contents/MacOS/EasySwipe
```

The architecture output must contain both `arm64` and `x86_64`.

## Notarization

Create the final ZIP or DMG, submit it with `xcrun notarytool` using a Keychain profile, wait for an accepted result, and staple the notarization ticket to the app or disk image. Validate the result with `spctl --assess` on a clean Mac.

## Sparkle appcast

Use the tools bundled with the pinned Sparkle release to sign the archive and generate or update the appcast. Publish the signed archive and appcast over HTTPS, then test an update from the immediately preceding public version before publishing the release.

The in-app update controller starts only when both the HTTPS feed URL and public key are valid. A build without them shows a localized configuration notice when the user manually checks for updates.

## Release checklist

1. Run `scripts/remote-studio.sh verify` on the exact release commit.
2. Build with production Sparkle and Developer ID settings.
3. Verify signatures, Hardened Runtime, version, build number, and both architectures.
4. Notarize, staple, and run Gatekeeper assessment.
5. Generate and validate the signed Sparkle appcast.
6. Test first launch, Accessibility onboarding, login item, all three gestures, both languages, and update installation on clean supported Macs.
7. Publish the archive and appcast, then create the GitHub release.
