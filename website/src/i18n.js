export const supportedLocales = ["de", "en"];

export const localeNames = {
  de: "Deutsch",
  en: "English",
};

export const routes = {
  en: {
    landing: "/",
    imprint: "/en/imprint",
    privacy: "/en/privacy",
    licenses: "/en/licenses",
  },
  de: {
    landing: "/de",
    imprint: "/de/impressum",
    privacy: "/de/datenschutz",
    licenses: "/de/lizenzen",
  },
  fr: {
    landing: "/fr",
    imprint: "/fr/mentions-legales",
    privacy: "/fr/confidentialite",
    licenses: "/fr/licences",
  },
};

const routeAliases = {
  "/impressum": { locale: "de", page: "imprint" },
  "/datenschutz": { locale: "de", page: "privacy" },
  "/lizenzen": { locale: "de", page: "licenses" },
  "/en": { locale: "en", page: "landing" },
};

export function resolveRoute(pathname) {
  const normalized = pathname.replace(/\/+$/, "") || "/";

  if (routeAliases[normalized]) return routeAliases[normalized];

  for (const locale of supportedLocales) {
    for (const [page, path] of Object.entries(routes[locale])) {
      if (path === normalized) return { locale, page };
    }
  }

  return { locale: "en", page: "landing" };
}

export function routeFor(locale, page = "landing") {
  return routes[locale]?.[page] ?? routes.en.landing;
}

export const translations = {
  en: {
    metaDescription:
      "Swindoo is a tiny native macOS menu bar app for arranging windows with two-finger title-bar gestures.",
    navigation: {
      primary: "Primary navigation",
      gestures: "Gestures",
      source: "Source Code",
      download: "Download",
      downloadLong: "Download for macOS",
      releases: "GitHub Releases",
      language: "Language",
      home: "home",
      imprint: "Imprint",
      privacy: "Privacy",
      licenses: "Licenses",
    },
    hero: {
      tagline: "Swipe. Snap. Done.",
      description: "Window management for people who hate window managers.",
      iconAlt: "Swindoo app icon",
    },
    gesture: {
      preview: "Interactive preview",
      sectionLabel: "Four title-bar gestures",
      title: "Title bar + two fingers",
      devices: "Supported input devices",
      directions: {
        up: { eyebrow: "Up", label: "Maximize" },
        left: { eyebrow: "Left", label: "Half screen" },
        right: { eyebrow: "Right", label: "Half screen" },
        down: { eyebrow: "Down", label: "Minimize" },
      },
      live: (direction, action) => `Previewing swipe ${direction.toLowerCase()}: ${action}.`,
    },
    finder: ["Desktop", "Documents", "Downloads", "Projects"],
    stepsLabel: "How Swindoo works",
    steps: [
      { title: "Place two fingers on the title bar.", copy: "Anywhere on the bar." },
      { title: "Swipe in a direction.", copy: "Up, down, left, or right." },
      { title: "Done.", copy: "Your window snaps instantly." },
    ],
    productDetails: "Swindoo product details",
    trust: [
      {
        title: "Free · Native · No telemetry",
        copy: "Built for macOS using native APIs. No analytics. No data collection.",
      },
      {
        title: "Open source · MIT",
        copy: "Source code, issues, and contributions are public on GitHub under the MIT License.",
      },
      {
        title: "Version 0.1.3",
        copy: "Broader title-bar compatibility for Notion and other custom macOS windows.",
      },
    ],
  },
  de: {
    metaDescription:
      "Swindoo ist eine kleine native macOS-Menüleisten-App, die Fenster mit Zwei-Finger-Gesten auf der Titelbar anordnet.",
    navigation: {
      primary: "Hauptnavigation",
      gestures: "Gesten",
      source: "Quellcode",
      download: "Download",
      downloadLong: "Für macOS laden",
      releases: "GitHub-Releases",
      language: "Sprache",
      home: "Startseite",
      imprint: "Impressum",
      privacy: "Datenschutz",
      licenses: "Lizenzen",
    },
    hero: {
      tagline: "Wischen. Einrasten. Fertig.",
      description: "Fenstermanagement für Menschen, die keine Fenstermanager mögen.",
      iconAlt: "Swindoo-App-Symbol",
    },
    gesture: {
      preview: "Interaktive Vorschau",
      sectionLabel: "Vier Gesten auf der Fenstertitelbar",
      title: "Titelbar + zwei Finger",
      devices: "Unterstützte Eingabegeräte",
      directions: {
        up: { eyebrow: "Oben", label: "Maximieren" },
        left: { eyebrow: "Links", label: "Halber Bildschirm" },
        right: { eyebrow: "Rechts", label: "Halber Bildschirm" },
        down: { eyebrow: "Unten", label: "Minimieren" },
      },
      live: (direction, action) => `Vorschau für Wischen nach ${direction.toLowerCase()}: ${action}.`,
    },
    finder: ["Schreibtisch", "Dokumente", "Downloads", "Projekte"],
    stepsLabel: "So funktioniert Swindoo",
    steps: [
      { title: "Lege zwei Finger auf die Titelbar.", copy: "An einer beliebigen Stelle der Leiste." },
      { title: "Wische in eine Richtung.", copy: "Nach oben, unten, links oder rechts." },
      { title: "Fertig.", copy: "Das Fenster rastet sofort ein." },
    ],
    productDetails: "Produktdetails zu Swindoo",
    trust: [
      {
        title: "Kostenlos · Nativ · Keine Telemetrie",
        copy: "Mit nativen macOS-APIs gebaut. Keine Analyse. Keine Datensammlung.",
      },
      {
        title: "Open Source · MIT",
        copy: "Quellcode, Fehlerberichte und Beiträge sind unter der MIT-Lizenz auf GitHub öffentlich.",
      },
      {
        title: "Version 0.1.3",
        copy: "Bessere Titelbar-Kompatibilität für Notion und andere eigene macOS-Fenster.",
      },
    ],
  },
  fr: {
    metaDescription:
      "Swindoo est une petite app macOS native dans la barre des menus pour organiser les fenêtres avec deux doigts sur leur barre de titre.",
    navigation: {
      primary: "Navigation principale",
      gestures: "Gestes",
      source: "Code source",
      download: "Télécharger",
      downloadLong: "Télécharger pour macOS",
      releases: "Versions GitHub",
      language: "Langue",
      home: "accueil",
      imprint: "Mentions légales",
      privacy: "Confidentialité",
      licenses: "Licences",
    },
    hero: {
      tagline: "Glissez. Placez. Terminé.",
      description: "La gestion des fenêtres pour ceux qui détestent les gestionnaires de fenêtres.",
      iconAlt: "Icône de l’app Swindoo",
    },
    gesture: {
      preview: "Aperçu interactif",
      sectionLabel: "Quatre gestes sur la barre de titre",
      title: "Barre de titre + deux doigts",
      devices: "Périphériques compatibles",
      directions: {
        up: { eyebrow: "Haut", label: "Agrandir" },
        left: { eyebrow: "Gauche", label: "Demi-écran" },
        right: { eyebrow: "Droite", label: "Demi-écran" },
        down: { eyebrow: "Bas", label: "Réduire" },
      },
      live: (direction, action) => `Aperçu du geste vers ${direction.toLowerCase()} : ${action}.`,
    },
    finder: ["Bureau", "Documents", "Téléchargements", "Projets"],
    stepsLabel: "Comment fonctionne Swindoo",
    steps: [
      { title: "Posez deux doigts sur la barre de titre.", copy: "N’importe où sur la barre." },
      { title: "Glissez dans une direction.", copy: "Vers le haut, le bas, la gauche ou la droite." },
      { title: "Terminé.", copy: "La fenêtre se place instantanément." },
    ],
    productDetails: "Détails du produit Swindoo",
    trust: [
      {
        title: "Gratuit · Natif · Sans télémétrie",
        copy: "Conçu avec les API natives de macOS. Aucune analyse. Aucune collecte de données.",
      },
      {
        title: "Open source · MIT",
        copy: "Le code source, les problèmes et les contributions sont publics sur GitHub sous licence MIT.",
      },
      {
        title: "Version 0.1.3",
        copy: "Meilleure compatibilité avec Notion et les fenêtres macOS personnalisées.",
      },
    ],
  },
};

export function copyFor(locale) {
  return translations[locale] ?? translations.en;
}
