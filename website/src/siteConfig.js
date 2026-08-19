export const siteConfig = {
  name: "Swindoo",
  previousName: "EasySwipe",
  version: "0.1.3",
  tagline: "Swipe. Snap. Done.",
  description: "Window management for people who hate window managers.",
  downloadUrl:
    "https://github.com/shortcutchris/easyswipe-releases/releases/latest/download/Swindoo.zip",
  sourceUrl: "https://github.com/shortcutchris/easyswipe",
  releasesUrl: "https://github.com/shortcutchris/easyswipe-releases/releases",
};

// Public operator details verified against https://chhubmann.de on 19 August 2026.
export const legalConfig = {
  operatorName: "Christian Hubmann",
  streetAddress: "c/o BIK GmbH",
  postalAddress: "Schwabacher Str. 34, 90537 Feucht",
  country: "Deutschland",
  email: "agentmorpheus(at)agentmail.to",
  supervisoryAuthority:
    "Bayerisches Landesamt für Datenschutzaufsicht (BayLDA), Promenade 18, 91522 Ansbach",
};

export const legalDraftIsComplete = Object.values(legalConfig).every(
  (value) => !value.includes("[") && !value.includes("]"),
);
