import { useEffect, useState } from "react";
import {
  ArrowDown,
  ArrowLeft,
  ArrowRight,
  ArrowUp,
  ArrowsOutCardinal,
  Browsers,
  CheckCircle,
  Cube,
  Desktop,
  DownloadSimple,
  File,
  FolderSimple,
  GithubLogo,
  HandTap,
  LockSimple,
  Monitor,
  Mouse,
  Rectangle,
  Translate,
} from "@phosphor-icons/react";
import { ImprintPage, LicensesPage, PrivacyPage } from "./LegalPages.jsx";
import {
  copyFor,
  localeNames,
  resolveRoute,
  routeFor,
  supportedLocales,
} from "./i18n.js";
import { siteConfig } from "./siteConfig.js";

const directionMeta = [
  { id: "up", icon: ArrowUp },
  { id: "left", icon: ArrowLeft },
  { id: "right", icon: ArrowRight },
  { id: "down", icon: ArrowDown },
];

const finderIcons = [Desktop, File, DownloadSimple, FolderSimple];
const stepIcons = [HandTap, ArrowsOutCardinal, Browsers];
const trustMeta = [
  { icon: LockSimple, tone: "mint" },
  { icon: Cube, tone: "coral" },
  { icon: CheckCircle, tone: "blue" },
];

function Brand({ href, copy }) {
  return (
    <a className="brand" href={href} aria-label={`${siteConfig.name} ${copy.navigation.home}`}>
      <img src="/assets/swindoo-icon.png" alt="" />
      <span>{siteConfig.name}</span>
    </a>
  );
}

function DownloadButton({ copy, variant = "primary", compact = false }) {
  return (
    <a
      className={`button button--${variant}${compact ? " button--compact" : ""}`}
      href={siteConfig.downloadUrl}
      aria-label={`${copy.navigation.downloadLong}: ${siteConfig.name} ${siteConfig.version}`}
    >
      <DownloadSimple weight="bold" aria-hidden="true" />
      <span>{compact ? copy.navigation.download : copy.navigation.downloadLong}</span>
    </a>
  );
}

function LanguageSwitcher({ locale, page, copy }) {
  return (
    <nav className="language-switcher" aria-label={copy.navigation.language}>
      <Translate className="language-switcher__icon" weight="bold" aria-hidden="true" />
      {supportedLocales.map((candidate) => (
        <a
          key={candidate}
          href={routeFor(candidate, page)}
          hrefLang={candidate}
          lang={candidate}
          aria-current={candidate === locale ? "page" : undefined}
          aria-label={localeNames[candidate]}
        >
          <span>{candidate.toUpperCase()}</span>
        </a>
      ))}
    </nav>
  );
}

function GestureDemo({ copy }) {
  const [activeGesture, setActiveGesture] = useState("right");
  const active = copy.gesture.directions[activeGesture];

  return (
    <div className={`gesture-demo gesture-demo--${activeGesture}`}>
      <div className="gesture-demo__label">
        <span aria-hidden="true" />
        {copy.gesture.preview}
      </div>

      {directionMeta.map(({ id, icon: Icon }) => {
        const direction = copy.gesture.directions[id];
        return (
          <button
            className={`gesture-target gesture-target--${id}`}
            type="button"
            key={id}
            aria-label={`${direction.eyebrow}: ${direction.label}`}
            aria-pressed={activeGesture === id}
            onClick={() => setActiveGesture(id)}
            onFocus={() => setActiveGesture(id)}
            onMouseEnter={() => setActiveGesture(id)}
          >
            <Icon weight="bold" aria-hidden="true" />
            <span className="gesture-target__copy">
              <strong>{direction.eyebrow}</strong>
              <span>{direction.label}</span>
            </span>
          </button>
        );
      })}

      <div className="finder-demo" aria-hidden="true">
        <div className="finder-demo__titlebar">
          <div className="finder-demo__traffic">
            <span />
            <span />
            <span />
          </div>
          <div className="finder-demo__fingers">
            <span />
            <span />
          </div>
        </div>
        <div className="finder-demo__body">
          <div className="finder-demo__sidebar">
            {copy.finder.map((label, index) => {
              const Icon = finderIcons[index];
              return (
                <div key={label}>
                  <Icon weight="regular" />
                  <span>{label}</span>
                </div>
              );
            })}
          </div>
          <div className="finder-demo__content">
            <div className="finder-demo__folders">
              {copy.finder.map((label) => (
                <div key={label}>
                  <FolderSimple weight="fill" />
                  <span>{label}</span>
                </div>
              ))}
            </div>
            <div className="finder-demo__rows">
              <div><File weight="fill" /><span /><span /></div>
              <div><File weight="fill" /><span /><span /></div>
            </div>
          </div>
        </div>
      </div>

      <div className="gesture-demo__status" aria-hidden="true">
        <Monitor weight="fill" />
        <span>{active.eyebrow} · {active.label}</span>
      </div>
      <p className="sr-only" aria-live="polite">
        {copy.gesture.live(active.eyebrow, active.label)}
      </p>
    </div>
  );
}

function SiteHeader({ locale, page, copy }) {
  const isHome = page === "landing";
  const landing = routeFor(locale, "landing");
  const gestureHref = isHome ? "#gestures" : `${landing}#gestures`;

  return (
    <header className="site-header" data-testid="site-header">
      <Brand href={isHome ? "#top" : landing} copy={copy} />
      <div className="site-header__actions">
        <nav className="primary-nav" aria-label={copy.navigation.primary}>
          <a className="nav-link nav-link--desktop" href={gestureHref}>{copy.navigation.gestures}</a>
          <a className="nav-link nav-link--desktop" href={siteConfig.sourceUrl}>{copy.navigation.source}</a>
        </nav>
        <LanguageSwitcher locale={locale} page={page} copy={copy} />
        <DownloadButton compact copy={copy} />
      </div>
    </header>
  );
}

function SiteFooter({ locale, page, copy }) {
  const isHome = page === "landing";
  const landing = routeFor(locale, "landing");

  return (
    <footer className="footer">
      <Brand href={isHome ? "#top" : landing} copy={copy} />
      <p>© 2026 {siteConfig.name}</p>
      <div>
        <a href={isHome ? "#gestures" : `${landing}#gestures`}>{copy.navigation.gestures}</a>
        <a href={siteConfig.sourceUrl}>{copy.navigation.source}</a>
        <a href={routeFor(locale, "imprint")}>{copy.navigation.imprint}</a>
        <a href={routeFor(locale, "privacy")}>{copy.navigation.privacy}</a>
        <a href={routeFor(locale, "licenses")}>{copy.navigation.licenses}</a>
      </div>
    </footer>
  );
}

function LandingPage({ locale, copy }) {
  return (
    <div className="site-shell" id="top">
      <SiteHeader locale={locale} page="landing" copy={copy} />

      <main>
        <section className="hero" aria-labelledby="hero-title">
          <img className="hero__icon" src="/assets/swindoo-icon.png" alt={copy.hero.iconAlt} />
          <h1 id="hero-title">{copy.hero.tagline}</h1>
          <p>{copy.hero.description}</p>
          <DownloadButton copy={copy} />
          <a className="text-link" href={siteConfig.sourceUrl}>
            {copy.navigation.source} <ArrowRight weight="bold" aria-hidden="true" />
          </a>
        </section>

        <section className="gestures" id="gestures" data-testid="gesture-section">
          <h2 className="sr-only">{copy.gesture.sectionLabel}</h2>
          <GestureDemo copy={copy} />
          <h3>{copy.gesture.title}</h3>
          <div className="device-row" aria-label={copy.gesture.devices}>
            <div className="device-pill">
              <Rectangle weight="light" aria-hidden="true" />
              <span>Magic Trackpad</span>
            </div>
            <div className="device-pill">
              <Mouse weight="light" aria-hidden="true" />
              <span>Magic Mouse</span>
            </div>
          </div>
        </section>

        <section className="steps" aria-label={copy.stepsLabel}>
          {copy.steps.map(({ title, copy: stepCopy }, index) => {
            const Icon = stepIcons[index];
            return (
              <article className="step" key={title}>
                <span className="step__number" aria-hidden="true">{index + 1}</span>
                <div className="step__icon"><Icon weight="light" aria-hidden="true" /></div>
                <h2>{title}</h2>
                <p>{stepCopy}</p>
              </article>
            );
          })}
        </section>

        <section className="trust" aria-label={copy.productDetails}>
          {copy.trust.map(({ title, copy: trustCopy }, index) => {
            const { icon: Icon, tone } = trustMeta[index];
            return (
              <article className="trust-item" key={title}>
                <div className={`trust-item__icon trust-item__icon--${tone}`}>
                  <Icon weight="bold" aria-hidden="true" />
                </div>
                <div>
                  <h2>{title}</h2>
                  <p>{trustCopy}</p>
                </div>
              </article>
            );
          })}
        </section>

        <section className="download-panel" aria-labelledby="download-title">
          <div>
            <h2 id="download-title">{siteConfig.name}</h2>
            <p className="download-panel__tagline">{copy.hero.tagline}</p>
            <p>{copy.hero.description}</p>
          </div>
          <div className="download-panel__actions">
            <DownloadButton variant="light" copy={copy} />
            <a className="download-panel__github" href={siteConfig.releasesUrl}>
              <GithubLogo weight="fill" aria-hidden="true" />
              {copy.navigation.releases}
              <ArrowRight weight="bold" aria-hidden="true" />
            </a>
          </div>
        </section>
      </main>

      <SiteFooter locale={locale} page="landing" copy={copy} />
    </div>
  );
}

const legalComponents = {
  imprint: ImprintPage,
  privacy: PrivacyPage,
  licenses: LicensesPage,
};

export function App() {
  const { locale, page } = resolveRoute(window.location.pathname);
  const copy = copyFor(locale);
  const LegalPage = legalComponents[page];

  useEffect(() => {
    const pageTitle = page === "landing" ? copy.hero.tagline : copy.navigation[page];
    const socialTitle = `${siteConfig.name} — ${pageTitle}`;
    const socialImage = new URL("/og.png", window.location.origin).href;
    document.documentElement.lang = locale;
    document.title = socialTitle;
    document.querySelector('meta[name="description"]')?.setAttribute("content", copy.metaDescription);
    document.querySelector('meta[property="og:title"]')?.setAttribute("content", socialTitle);
    document.querySelector('meta[property="og:description"]')?.setAttribute("content", copy.metaDescription);
    document.querySelector('meta[property="og:image"]')?.setAttribute("content", socialImage);
    document.querySelector('meta[name="twitter:title"]')?.setAttribute("content", socialTitle);
    document.querySelector('meta[name="twitter:description"]')?.setAttribute("content", copy.metaDescription);
    document.querySelector('meta[name="twitter:image"]')?.setAttribute("content", socialImage);
  }, [copy, locale, page]);

  if (!LegalPage) return <LandingPage locale={locale} copy={copy} />;

  return (
    <div className="site-shell">
      <SiteHeader locale={locale} page={page} copy={copy} />
      <LegalPage locale={locale} />
      <SiteFooter locale={locale} page={page} copy={copy} />
    </div>
  );
}
