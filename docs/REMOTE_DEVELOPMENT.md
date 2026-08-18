# Remote development

EasySwipe builds and tests on Chris's Mac Studio so local editing can remain responsive and Dropbox is never used as compiler input.

The repository-owned runner is `scripts/remote-studio.sh`.

```sh
scripts/remote-studio.sh doctor
scripts/remote-studio.sh build
scripts/remote-studio.sh test
scripts/remote-studio.sh release
scripts/remote-studio.sh verify
scripts/remote-studio.sh fetch
```

The runner mirrors the repository to `/Users/chris/Developer/easyswipe`, keeps test and release build products in separate Derived Data directories under `/Users/chris/Developer/DerivedData`, and stages verified artifacts under `/Users/chris/Developer/EasySwipeArtifacts`.

It intentionally excludes Git metadata, credentials, signing material, Sparkle private keys, Derived Data, result bundles, local artifacts, environment files, and user data. It never installs or launches the app on either Mac.

`release` creates an optimized, hardened-runtime, ad-hoc-signed development Release build and asserts that the executable contains both `arm64` and `x86_64` slices.

`verify` requires both a successful `xcodebuild test` process and an independently parsed `.xcresult` summary with `result == Passed` and zero failures. It then runs the Release pipeline, validates nested code signatures and menu-bar-only metadata, creates a ZIP, and writes a non-secret verification manifest.

The staged build is a development artifact. Public distribution additionally requires a Developer ID signature, notarization, and production Sparkle configuration as described in `docs/RELEASING.md`.
