import assert from "node:assert/strict";
import { access } from "node:fs/promises";
import test from "node:test";
import { resolveRoute, routeFor, supportedLocales, translations } from "../src/i18n.js";
import { legalConfig, legalDraftIsComplete, siteConfig } from "../src/siteConfig.js";
import worker from "../worker/index.js";

test("uses the Swindoo transition brand and release metadata", () => {
  assert.equal(siteConfig.name, "Swindoo");
  assert.equal(siteConfig.previousName, "EasySwipe");
  assert.equal(siteConfig.version, "0.1.3");
  assert.match(siteConfig.downloadUrl, /\/releases\/latest\/download\/Swindoo\.zip$/);
  assert.match(siteConfig.sourceUrl, /shortcutchris\/easyswipe$/);
});

test("has complete public operator details before deployment", () => {
  assert.equal(legalDraftIsComplete, true);
  assert.equal(legalConfig.operatorName, "Christian Hubmann");
  assert.match(legalConfig.postalAddress, /90537 Feucht$/);
  assert.match(legalConfig.supervisoryAuthority, /BayLDA/);
});

test("serves existing static assets without a fallback", async () => {
  const calls = [];
  const response = await worker.fetch(new Request("https://example.test/assets/app.js"), {
    ASSETS: {
      fetch: async (request) => {
        calls.push(new URL(request.url).pathname);
        return new Response("asset", { status: 200 });
      },
    },
  });

  assert.equal(response.status, 200);
  assert.deepEqual(calls, ["/assets/app.js"]);
});

test("falls back to index.html for an unknown app route", async () => {
  const calls = [];
  const response = await worker.fetch(
    new Request("https://example.test/flow/step-two?source=share", {
      headers: { accept: "text/html" },
    }),
    {
      ASSETS: {
        fetch: async (request) => {
          const url = new URL(request.url);
          calls.push(url.pathname + url.search);
          return new Response(url.pathname === "/index.html" ? "app" : "missing", {
            status: url.pathname === "/index.html" ? 200 : 404,
          });
        },
      },
    },
  );

  assert.equal(response.status, 200);
  assert.deepEqual(calls, ["/flow/step-two?source=share", "/index.html"]);
});

test("serves the app shell for every prepared legal route", async () => {
  for (const pathname of [
    "/impressum",
    "/datenschutz",
    "/lizenzen",
    "/en/imprint",
    "/en/privacy",
    "/en/licenses",
    "/de/impressum",
    "/de/datenschutz",
    "/de/lizenzen",
    "/fr/mentions-legales",
    "/fr/confidentialite",
    "/fr/licences",
  ]) {
    const calls = [];
    const response = await worker.fetch(
      new Request(`https://example.test${pathname}`, {
        headers: { accept: "text/html" },
      }),
      {
        ASSETS: {
          fetch: async (request) => {
            const url = new URL(request.url);
            calls.push(url.pathname);
            return new Response(url.pathname === "/index.html" ? "app" : "missing", {
              status: url.pathname === "/index.html" ? 200 : 404,
            });
          },
        },
      },
    );

    assert.equal(response.status, 200);
    assert.deepEqual(calls, [pathname, "/index.html"]);
  }
});

test("maps every localized page without changing its page type", () => {
  assert.deepEqual(supportedLocales, ["de", "en"]);

  for (const locale of supportedLocales) {
    for (const page of ["landing", "imprint", "privacy", "licenses"]) {
      assert.deepEqual(resolveRoute(routeFor(locale, page)), { locale, page });
    }
  }
});

test("provides complete German and English landing-page translations", () => {
  for (const locale of supportedLocales) {
    const copy = translations[locale];
    assert.ok(copy.metaDescription);
    assert.ok(copy.navigation.gestures);
    assert.ok(copy.navigation.downloadLong);
    assert.ok(copy.hero.tagline);
    assert.ok(copy.hero.description);
    assert.ok(copy.gesture.title);
    assert.equal(copy.steps.length, 3);
    assert.equal(copy.trust.length, 3);
  }
});

test("does not turn missing API or write requests into the app shell", async () => {
  for (const request of [
    new Request("https://example.test/api/missing", { headers: { accept: "application/json" } }),
    new Request("https://example.test/flow", { method: "POST", headers: { accept: "text/html" } }),
  ]) {
    let calls = 0;
    const response = await worker.fetch(request, {
      ASSETS: {
        fetch: async () => {
          calls += 1;
          return new Response("missing", { status: 404 });
        },
      },
    });

    assert.equal(response.status, 404);
    assert.equal(calls, 1);
  }
});

test("emits the files required by Sites packaging", async () => {
  await access(new URL("../dist/client/index.html", import.meta.url));
  await access(new URL("../dist/server/index.js", import.meta.url));
  await access(new URL("../dist/.openai/hosting.json", import.meta.url));
});
