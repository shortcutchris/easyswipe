# Swindoo Repository Instructions

## Automatic release policy

When the user approves or requests a functional Swindoo fix, carry it through the complete release workflow by default unless the user explicitly asks for source-only work, a preview, or no publication:

1. Increase the patch version and build number.
2. Update release notes, app metadata, tests, README, and website version copy.
3. Run the repository-required complete Mac Studio test and verification gate.
4. Commit and push the exact verified source to `main`.
5. Developer-ID sign, Apple-notarize, staple, Gatekeeper-check, and publish the Sparkle update through the guarded release script.
6. Update and publicly deploy the existing Sites website.
7. Verify the Sparkle feed, versioned release, stable logged-out download, localized website routes, and legal pages before reporting completion.

Never expose signing, notarization, Sparkle, Sites, or source-repository credentials. Ask the user only for the smallest missing authentication step when an existing credential requires renewal. Do not replace or launch the user's installed production app unless they explicitly request installation or a hands-on local check.
