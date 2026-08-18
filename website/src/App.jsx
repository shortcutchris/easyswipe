import { useState } from "react";
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
} from "@phosphor-icons/react";

const DOWNLOAD_URL =
  "https://github.com/shortcutchris/easyswipe-releases/releases/latest/download/EasySwipe.zip";
const SOURCE_URL = "https://github.com/shortcutchris/easyswipe";
const RELEASES_URL = "https://github.com/shortcutchris/easyswipe-releases/releases";

const gestureDirections = [
  { id: "up", eyebrow: "Up", label: "Maximize", icon: ArrowUp },
  { id: "left", eyebrow: "Left", label: "Half screen", icon: ArrowLeft },
  { id: "right", eyebrow: "Right", label: "Half screen", icon: ArrowRight },
  { id: "down", eyebrow: "Down", label: "Minimize", icon: ArrowDown },
];

const finderLocations = [
  { label: "Desktop", icon: Desktop },
  { label: "Documents", icon: File },
  { label: "Downloads", icon: DownloadSimple },
  { label: "Projects", icon: FolderSimple },
];

const steps = [
  { number: "1", icon: HandTap, title: "Place two fingers on the title bar.", copy: "Anywhere on the bar." },
  { number: "2", icon: ArrowsOutCardinal, title: "Swipe in a direction.", copy: "Up, down, left, or right." },
  { number: "3", icon: Browsers, title: "Done.", copy: "Your window snaps instantly." },
];

const trustItems = [
  {
    icon: LockSimple,
    tone: "mint",
    title: "Free · Native · No telemetry",
    copy: "Built for macOS using native APIs. No analytics. No data collection.",
  },
  {
    icon: Cube,
    tone: "coral",
    title: "Open source · MIT",
    copy: "Source code, issues, and contributions are public on GitHub under the MIT License.",
  },
  {
    icon: CheckCircle,
    tone: "blue",
    title: "Always up to date",
    copy: "The latest signed release is always one click away, with Sparkle updates built in.",
  },
];

function Brand() {
  return (
    <a className="brand" href="#top" aria-label="EasySwipe home">
      <img src="/assets/easyswipe-icon.png" alt="" />
      <span>EasySwipe</span>
    </a>
  );
}

function DownloadButton({ variant = "primary", compact = false }) {
  return (
    <a
      className={`button button--${variant}${compact ? " button--compact" : ""}`}
      href={DOWNLOAD_URL}
      aria-label="Download the latest EasySwipe release for macOS"
    >
      <DownloadSimple weight="bold" aria-hidden="true" />
      <span>{compact ? "Download" : "Download for macOS"}</span>
    </a>
  );
}

function GestureDemo() {
  const [activeGesture, setActiveGesture] = useState("right");
  const active = gestureDirections.find(({ id }) => id === activeGesture);

  return (
    <div className={`gesture-demo gesture-demo--${activeGesture}`}>
      <div className="gesture-demo__label">
        <span aria-hidden="true" />
        Interactive preview
      </div>

      {gestureDirections.map(({ id, eyebrow, label, icon: Icon }) => (
        <button
          className={`gesture-target gesture-target--${id}`}
          type="button"
          key={id}
          aria-label={`${eyebrow}: ${label}`}
          aria-pressed={activeGesture === id}
          onClick={() => setActiveGesture(id)}
          onFocus={() => setActiveGesture(id)}
          onMouseEnter={() => setActiveGesture(id)}
        >
          <Icon weight="bold" aria-hidden="true" />
          <span className="gesture-target__copy">
            <strong>{eyebrow}</strong>
            <span>{label}</span>
          </span>
        </button>
      ))}

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
            {finderLocations.map(({ label, icon: Icon }) => (
              <div key={label}>
                <Icon weight="regular" />
                <span>{label}</span>
              </div>
            ))}
          </div>
          <div className="finder-demo__content">
            <div className="finder-demo__folders">
              {["Desktop", "Documents", "Downloads", "Projects"].map((label) => (
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
        Previewing swipe {active.eyebrow.toLowerCase()}: {active.label}.
      </p>
    </div>
  );
}

export function App() {
  return (
    <div className="site-shell" id="top">
      <header className="site-header" data-testid="site-header">
        <Brand />
        <nav aria-label="Primary navigation">
          <a className="nav-link nav-link--desktop" href="#gestures">Gestures</a>
          <a className="nav-link nav-link--desktop" href={SOURCE_URL}>Source Code</a>
          <DownloadButton compact />
        </nav>
      </header>

      <main>
        <section className="hero" aria-labelledby="hero-title">
          <img className="hero__icon" src="/assets/easyswipe-icon.png" alt="EasySwipe app icon" />
          <h1 id="hero-title">Swipe. Snap. Done.</h1>
          <p>Window management for people who hate window managers.</p>
          <DownloadButton />
          <a className="text-link" href={SOURCE_URL}>
            Source Code <ArrowRight weight="bold" aria-hidden="true" />
          </a>
        </section>

        <section className="gestures" id="gestures" data-testid="gesture-section">
          <h2 className="sr-only">Four title-bar gestures</h2>
          <GestureDemo />
          <h3>Title bar + two fingers</h3>
          <div className="device-row" aria-label="Supported input devices">
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

        <section className="steps" aria-label="How EasySwipe works">
          {steps.map(({ number, icon: Icon, title, copy }) => (
            <article className="step" key={number}>
              <span className="step__number" aria-hidden="true">{number}</span>
              <div className="step__icon"><Icon weight="light" aria-hidden="true" /></div>
              <h2>{title}</h2>
              <p>{copy}</p>
            </article>
          ))}
        </section>

        <section className="trust" aria-label="EasySwipe product details">
          {trustItems.map(({ icon: Icon, tone, title, copy }) => (
            <article className="trust-item" key={title}>
              <div className={`trust-item__icon trust-item__icon--${tone}`}>
                <Icon weight="bold" aria-hidden="true" />
              </div>
              <div>
                <h2>{title}</h2>
                <p>{copy}</p>
              </div>
            </article>
          ))}
        </section>

        <section className="download-panel" aria-labelledby="download-title">
          <div>
            <h2 id="download-title">EasySwipe</h2>
            <p className="download-panel__tagline">Swipe. Snap. Done.</p>
            <p>Window management for people who hate window managers.</p>
          </div>
          <div className="download-panel__actions">
            <DownloadButton variant="light" />
            <a className="download-panel__github" href={RELEASES_URL}>
              <GithubLogo weight="fill" aria-hidden="true" />
              GitHub Releases
              <ArrowRight weight="bold" aria-hidden="true" />
            </a>
          </div>
        </section>
      </main>

      <footer className="footer">
        <Brand />
        <p>© 2026 EasySwipe</p>
        <div>
          <a href="#gestures">Gestures</a>
          <a href={SOURCE_URL}>Source Code</a>
          <a href={RELEASES_URL}>Releases</a>
          <a href={DOWNLOAD_URL}>Download</a>
        </div>
      </footer>
    </div>
  );
}
