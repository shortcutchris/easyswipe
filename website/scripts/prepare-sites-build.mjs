#!/usr/bin/env node
import { copyFileSync, existsSync, mkdirSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const dist = path.join(root, "dist");
const index = path.join(dist, "client", "index.html");
const worker = path.join(root, "worker", "index.js");
const hosting = path.join(root, ".openai", "hosting.json");
const appRoutes = [
  "de",
  "de/impressum",
  "de/datenschutz",
  "de/lizenzen",
  "en",
  "en/imprint",
  "en/privacy",
  "en/licenses",
];

for (const file of [index, worker, hosting]) {
  if (!existsSync(file)) throw new Error("Missing Sites build input: " + file);
}

mkdirSync(path.join(dist, "server"), { recursive: true });
mkdirSync(path.join(dist, ".openai"), { recursive: true });
copyFileSync(worker, path.join(dist, "server", "index.js"));
copyFileSync(hosting, path.join(dist, ".openai", "hosting.json"));

// Sites serves static files before the Worker. Materialize every public SPA
// route so direct links and browser refreshes resolve before React takes over.
for (const route of appRoutes) {
  const routeDirectory = path.join(dist, "client", route);
  mkdirSync(routeDirectory, { recursive: true });
  copyFileSync(index, path.join(routeDirectory, "index.html"));
}

console.log("Prepared Sites build with Worker and localized route shells");
