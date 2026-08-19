# Brand migration: EasySwipe to Swindoo

Status: `Swindoo` is the selected product name. The practical screening in `docs/TRADEMARK_SCREENING.md` found no exact `SWINDOO` register result, but it did find similar marks that require professional interpretation. The source, app and website are prepared under the new visible name; public release remains a separate approval step.

## Why this is a staged migration

The installed app already has macOS Accessibility permission and receives signed Sparkle updates. Those two properties depend on continuity. A cosmetic rename is safe only if the technical identity of the existing app remains stable during the transition.

## Identities that stay unchanged for the transition release

- Bundle identifier: `com.shortcutchris.EasySwipe`
- Developer ID team and signing identity
- Executable and Swift module: `EasySwipe`
- Sparkle public key and Keychain account
- Existing appcast URL in `shortcutchris/easyswipe-releases`
- Existing preference keys and login-item registration

Keeping these identifiers avoids presenting the renamed app as a new privacy-sensitive application and preserves the update path from version 0.1.2.

## Identities that can change visibly

- App display name and menu text: `Swindoo`
- Website name, metadata and copy
- Release title and release notes
- App icon if a new icon is approved
- Source repository description and README

The first renamed archive continues to be called `EasySwipe-…zip` internally so the old appcast and release automation remain compatible. The visible app name is `Swindoo` through `CFBundleDisplayName` and `CFBundleName`.

## Recommended release sequence

1. Approve the final name and reserve the desired domain and social/repository names.
2. Have the documented EUIPO/DPMA/TMview screening reviewed professionally for the relevant software classes. The register, web, store and repository screening is not a legal clearance.
3. Fill and review the legal operator details in `website/src/siteConfig.js`.
4. Update visible app strings, `CFBundleDisplayName`, website copy and release notes.
5. Include the project and Sparkle license texts in the signed app bundle.
6. Build, sign and notarize a transition version with the unchanged bundle identifier and update key.
7. Test an in-place Sparkle update from public version 0.1.2 on a second Mac. Verify that Accessibility permission, login-at-start and preferences survive.
8. Publish the new app and appcast first, then publish the renamed website.
9. Keep the legacy release repository and appcast URL online. Rename public repositories only after the transition update is proven.

## Repository and website plan

- The source and release URLs stay on the existing GitHub repositories for the transition.
- A later GitHub repository rename is optional; every installed app must continue receiving a valid appcast from the old raw URL.
- The existing `easyswipe.shortcutchris.chatgpt.site` address should remain available until a replacement domain or Sites address has been tested. `swindoo.app` is the preferred branded domain if it is reserved successfully.
- The website brand is centralized in `website/src/siteConfig.js`, so the final name can be changed without searching through the page components.

## Rollback

If the name is not approved, set `siteConfig.name` back to `EasySwipe` and discard the visible-name changes. None of the stable app identifiers or public update infrastructure needs to change during the preparation phase.
