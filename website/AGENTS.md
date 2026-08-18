# Prototype Instructions

Run the local server yourself and open the preview in the browser available to this environment. Do not give the user server-start instructions when you can run it.

Before making substantial visual changes, use the Product Design plugin's `get-context` skill when the visual source is unclear or no longer matches the current goal. When the user gives durable prototype-specific design feedback, preferences, or decisions, record them in `AGENTS.md`.

When implementing from a selected generated mock, treat that image as the source of truth for layout, component anatomy, density, spacing, color, typography, visible content, and hierarchy.

## EasySwipe design decisions

- The selected visual target is `public/assets/design-reference.png`.
- Keep the warm off-white editorial page, centered hero, oversized “Swipe. Snap. Done.” headline, cobalt primary actions, and four-direction gesture map.
- The four-direction gesture map is an interactive HTML/CSS component, not a static raster image. Hover, focus, and tap update the status, contact points, and Finder-window motion.
- Left and right gesture regions stay exact visual mirrors representing equal 50% window halves.
- The centered Finder-like window keeps two round blue finger-contact dots fully inside its title bar; the dots visibly demonstrate the selected two-finger swipe, pause at the directional endpoint, then reset for a repeat.
- Desktop and mobile preserve the same hierarchy; mobile may stack supporting rows but cannot hide the primary download or gesture explanation.
- Primary “Source Code” links point to the public `shortcutchris/easyswipe` repository; release and download links remain separate and point to `shortcutchris/easyswipe-releases`.

Build app UI in `src/`. Keep `.openai/hosting.json`, `worker/index.js`, `scripts/prepare-sites-build.mjs`, and `tests/sites-worker.test.mjs` intact so the same local prototype can be handed to Sites. Before a Sites handoff, run `npm run build` and `npm run test:sites`; the build must leave `dist/client/index.html`, `dist/server/index.js`, and `dist/.openai/hosting.json`.
