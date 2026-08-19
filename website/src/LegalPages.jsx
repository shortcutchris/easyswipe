import { ArrowLeft, ArrowSquareOut } from "@phosphor-icons/react";
import { routeFor } from "./i18n.js";
import { legalConfig, legalDraftIsComplete, siteConfig } from "./siteConfig.js";

const OPENAI_SITES_TERMS = "https://openai.com/policies/chatgpt-sites-terms/";
const OPENAI_SITES_DPA = "https://openai.com/policies/chatgpt-sites-data-processing-addendum/";
const CLOUDFLARE_COOKIES =
  "https://developers.cloudflare.com/fundamentals/reference/policies-compliances/cloudflare-cookies/";
const GITHUB_PRIVACY = "https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement";

const shellCopy = {
  en: {
    legal: "Legal",
    openSource: "Open source",
    back: "Back to the home page",
    email: "Email",
    draftTitle: "Do not publish yet",
    draftCopy:
      "This local draft is prepared, but the marked name, address, email and supervisory-authority details must be confirmed first.",
    translation:
      "This English translation is provided for convenience. If wording differs, the German version is authoritative.",
  },
  de: {
    legal: "Rechtliches",
    openSource: "Open Source",
    back: "Zurück zur Startseite",
    email: "E-Mail",
    draftTitle: "Noch nicht veröffentlichen",
    draftCopy:
      "Dieser lokale Entwurf ist inhaltlich vorbereitet. Die markierten Angaben zu Name, Anschrift, E-Mail-Adresse und Aufsichtsbehörde müssen vorher bestätigt werden.",
  },
  fr: {
    legal: "Informations juridiques",
    openSource: "Open source",
    back: "Retour à l’accueil",
    email: "E-mail",
    draftTitle: "Ne pas encore publier",
    draftCopy:
      "Ce brouillon local est préparé, mais le nom, l’adresse, l’e-mail et l’autorité de contrôle indiqués doivent d’abord être confirmés.",
    translation:
      "Cette traduction française est fournie à titre informatif. En cas de divergence, la version allemande fait foi.",
  },
};

function ExternalLink({ href, children }) {
  return (
    <a href={href} target="_blank" rel="noreferrer">
      {children}
      <ArrowSquareOut weight="bold" aria-hidden="true" />
    </a>
  );
}

function DraftNotice({ locale }) {
  if (legalDraftIsComplete) return null;
  const copy = shellCopy[locale];

  return (
    <aside className="legal-draft" aria-label={copy.draftTitle}>
      <strong>{copy.draftTitle}</strong>
      <p>{copy.draftCopy}</p>
    </aside>
  );
}

function TranslationNotice({ locale }) {
  const notice = shellCopy[locale].translation;
  if (!notice) return null;
  return <p className="legal-translation">{notice}</p>;
}

function ContactAddress({ locale }) {
  return (
    <address>
      {legalConfig.operatorName}
      <br />
      {legalConfig.streetAddress}
      <br />
      {legalConfig.postalAddress}
      <br />
      {legalConfig.country}
      <br />
      {shellCopy[locale].email}: {legalConfig.email}
    </address>
  );
}

export function ImprintPage({ locale }) {
  if (locale === "de") return <GermanImprint />;
  if (locale === "fr") return <FrenchImprint />;
  return <EnglishImprint />;
}

function GermanImprint() {
  return (
    <LegalArticle locale="de" eyebrow="Rechtliches" title="Impressum">
      <DraftNotice locale="de" />
      <section>
        <h2>Angaben gemäß § 5 DDG</h2>
        <ContactAddress locale="de" />
      </section>
      <section>
        <h2>Projekt und Kontakt</h2>
        <p>
          Diese Website informiert über {siteConfig.name}, eine quelloffene macOS-Anwendung.
          Für Fragen zur Website, zur App oder zum Datenschutz erreichen Sie die oben genannte
          Person unter der angegebenen E-Mail-Adresse.
        </p>
      </section>
      <section>
        <h2>Hinweis zu externen Links</h2>
        <p>
          Die Website verlinkt insbesondere auf GitHub. Für die Inhalte externer Seiten sind
          deren jeweilige Betreiber verantwortlich. Rechtswidrige Inhalte werden nach einem
          konkreten Hinweis geprüft und Links erforderlichenfalls entfernt.
        </p>
      </section>
      <section>
        <h2>Markenhinweis</h2>
        <p>
          Apple, Mac, macOS, Finder, Magic Mouse und Magic Trackpad sind Marken von Apple Inc.
          {` ${siteConfig.name}`} ist ein unabhängiges Open-Source-Projekt und steht nicht in
          Verbindung mit Apple Inc. Windows ist eine Marke der Microsoft-Unternehmensgruppe;
          das Projekt steht auch mit Microsoft in keiner Verbindung.
        </p>
      </section>
    </LegalArticle>
  );
}

function EnglishImprint() {
  return (
    <LegalArticle locale="en" eyebrow="Legal" title="Imprint">
      <DraftNotice locale="en" />
      <TranslationNotice locale="en" />
      <section>
        <h2>Information under section 5 DDG (German Digital Services Act)</h2>
        <ContactAddress locale="en" />
      </section>
      <section>
        <h2>Project and contact</h2>
        <p>
          This website provides information about {siteConfig.name}, an open-source macOS app.
          Questions about the website, app or privacy can be sent to the person and email address
          listed above.
        </p>
      </section>
      <section>
        <h2>External links</h2>
        <p>
          This website links to external services, particularly GitHub. Their respective
          operators are responsible for external content. Specific reports of unlawful content
          will be reviewed and links removed where necessary.
        </p>
      </section>
      <section>
        <h2>Trade marks</h2>
        <p>
          Apple, Mac, macOS, Finder, Magic Mouse and Magic Trackpad are trade marks of Apple Inc.
          {` ${siteConfig.name}`} is an independent open-source project and is not affiliated with
          Apple Inc. Windows is a trade mark of the Microsoft group of companies; this project is
          not affiliated with Microsoft either.
        </p>
      </section>
    </LegalArticle>
  );
}

function FrenchImprint() {
  return (
    <LegalArticle locale="fr" eyebrow="Informations juridiques" title="Mentions légales">
      <DraftNotice locale="fr" />
      <TranslationNotice locale="fr" />
      <section>
        <h2>Informations selon l’article 5 de la loi allemande DDG</h2>
        <ContactAddress locale="fr" />
      </section>
      <section>
        <h2>Projet et contact</h2>
        <p>
          Ce site présente {siteConfig.name}, une application macOS open source. Les questions
          concernant le site, l’application ou la protection des données peuvent être adressées
          à la personne et à l’adresse e-mail indiquées ci-dessus.
        </p>
      </section>
      <section>
        <h2>Liens externes</h2>
        <p>
          Ce site renvoie notamment vers GitHub. Les exploitants de ces services sont responsables
          de leur contenu. Tout signalement précis de contenu illicite sera examiné et le lien sera
          supprimé si nécessaire.
        </p>
      </section>
      <section>
        <h2>Marques</h2>
        <p>
          Apple, Mac, macOS, Finder, Magic Mouse et Magic Trackpad sont des marques d’Apple Inc.
          {` ${siteConfig.name}`} est un projet open source indépendant, sans lien avec Apple Inc.
          Windows est une marque du groupe Microsoft ; ce projet n’est pas non plus affilié à
          Microsoft.
        </p>
      </section>
    </LegalArticle>
  );
}

export function PrivacyPage({ locale }) {
  if (locale === "de") return <GermanPrivacy />;
  if (locale === "fr") return <FrenchPrivacy />;
  return <EnglishPrivacy />;
}

function GermanPrivacy() {
  return (
    <LegalArticle locale="de" eyebrow="Rechtliches" title="Datenschutzerklärung">
      <DraftNotice locale="de" />
      <section>
        <h2>1. Verantwortliche Stelle</h2>
        <p>
          Verantwortlich für die Verarbeitung personenbezogener Daten auf dieser Website und
          im Zusammenhang mit {siteConfig.name} ist:
        </p>
        <ContactAddress locale="de" />
      </section>
      <HostingSection locale="de" />
      <CookieSection locale="de" />
      <section>
        <h2>4. Keine Analyse, Werbung oder Benutzerkonten</h2>
        <p>
          Diese Website verwendet keine eigene Reichweitenanalyse, keine Werbetracker, keine
          Formulare und keine Benutzerkonten. Der Betreiber führt keine eigene Besucherdatenbank.
        </p>
      </section>
      <GithubSection locale="de" />
      <AppPrivacySection locale="de" />
      <section>
        <h2>7. Speicherdauer</h2>
        <p>
          Der Betreiber speichert keine eigenen Serverprotokolle oder Nutzerprofile. Technische
          Daten bei Hosting- und Download-Anbietern werden nur so lange verarbeitet, wie dies für
          Bereitstellung, Sicherheit und gesetzliche Pflichten erforderlich ist. Lokal gespeicherte
          App-Einstellungen verbleiben bis zur Löschung auf Ihrem Gerät.
        </p>
      </section>
      <section>
        <h2>8. Ihre Rechte</h2>
        <p>
          Sie haben nach Maßgabe der DSGVO insbesondere das Recht auf Auskunft, Berichtigung,
          Löschung, Einschränkung der Verarbeitung und Datenübertragbarkeit. Sie können einer
          Verarbeitung auf Grundlage berechtigter Interessen aus Gründen widersprechen, die sich
          aus Ihrer besonderen Situation ergeben. Außerdem besteht ein Beschwerderecht bei einer
          Datenschutzaufsichtsbehörde.
        </p>
        <p>Zuständige Aufsichtsbehörde: {legalConfig.supervisoryAuthority}</p>
      </section>
      <section>
        <h2>9. Stand und Änderungen</h2>
        <p>
          Stand: 19. August 2026. Diese Erklärung wird angepasst, wenn sich Hosting,
          App-Funktionen oder eingesetzte Dienste ändern.
        </p>
      </section>
    </LegalArticle>
  );
}

function EnglishPrivacy() {
  return (
    <LegalArticle locale="en" eyebrow="Legal" title="Privacy policy">
      <DraftNotice locale="en" />
      <TranslationNotice locale="en" />
      <section>
        <h2>1. Controller</h2>
        <p>
          The controller responsible for personal data processed through this website and in
          connection with {siteConfig.name} is:
        </p>
        <ContactAddress locale="en" />
      </section>
      <HostingSection locale="en" />
      <CookieSection locale="en" />
      <section>
        <h2>4. No analytics, advertising or user accounts</h2>
        <p>
          This website has no first-party analytics, advertising trackers, forms or user accounts.
          The operator does not maintain a visitor database.
        </p>
      </section>
      <GithubSection locale="en" />
      <AppPrivacySection locale="en" />
      <section>
        <h2>7. Retention</h2>
        <p>
          The operator stores no server logs or user profiles. Hosting and download providers keep
          technical data only as required for delivery, security and legal obligations. Local app
          settings remain on the device until they are deleted.
        </p>
      </section>
      <section>
        <h2>8. Your rights</h2>
        <p>
          Subject to the GDPR, you have rights of access, rectification, erasure, restriction and
          data portability. You may object to processing based on legitimate interests for reasons
          relating to your particular situation and may lodge a complaint with a supervisory authority.
        </p>
        <p>Competent supervisory authority: {legalConfig.supervisoryAuthority}</p>
      </section>
      <section>
        <h2>9. Date and changes</h2>
        <p>
          Effective 19 August 2026. This policy will be updated if the hosting, app features or
          services used change.
        </p>
      </section>
    </LegalArticle>
  );
}

function FrenchPrivacy() {
  return (
    <LegalArticle locale="fr" eyebrow="Informations juridiques" title="Confidentialité">
      <DraftNotice locale="fr" />
      <TranslationNotice locale="fr" />
      <section>
        <h2>1. Responsable du traitement</h2>
        <p>
          Le responsable du traitement des données personnelles sur ce site et en lien avec
          {` ${siteConfig.name}`} est :
        </p>
        <ContactAddress locale="fr" />
      </section>
      <HostingSection locale="fr" />
      <CookieSection locale="fr" />
      <section>
        <h2>4. Aucun outil d’analyse, publicité ou compte utilisateur</h2>
        <p>
          Ce site n’utilise ni outil d’analyse propre, ni traceur publicitaire, ni formulaire,
          ni compte utilisateur. L’exploitant ne tient aucune base de données de visiteurs.
        </p>
      </section>
      <GithubSection locale="fr" />
      <AppPrivacySection locale="fr" />
      <section>
        <h2>7. Durée de conservation</h2>
        <p>
          L’exploitant ne conserve ni journaux serveur propres ni profils d’utilisateurs. Les
          prestataires d’hébergement et de téléchargement ne traitent les données techniques que
          pendant la durée requise pour la fourniture, la sécurité et les obligations légales. Les
          réglages locaux restent sur l’appareil jusqu’à leur suppression.
        </p>
      </section>
      <section>
        <h2>8. Vos droits</h2>
        <p>
          Conformément au RGPD, vous disposez notamment de droits d’accès, de rectification,
          d’effacement, de limitation et de portabilité. Vous pouvez vous opposer à un traitement
          fondé sur l’intérêt légitime pour des raisons tenant à votre situation particulière et
          introduire une réclamation auprès d’une autorité de contrôle.
        </p>
        <p>Autorité de contrôle compétente : {legalConfig.supervisoryAuthority}</p>
      </section>
      <section>
        <h2>9. Date et modifications</h2>
        <p>
          Version du 19 août 2026. Cette déclaration sera adaptée si l’hébergement, les fonctions
          de l’app ou les services utilisés changent.
        </p>
      </section>
    </LegalArticle>
  );
}

function HostingSection({ locale }) {
  const content = {
    de: {
      title: "2. Hosting dieser Website",
      first:
        "Diese Website wird über ChatGPT Sites bereitgestellt. OpenAI Ireland Limited verarbeitet dabei als Auftragsverarbeiter technische Daten, die beim Aufruf entstehen können. Dazu gehören insbesondere Protokoll-, Nutzungs- und Geräteinformationen sowie Daten aus technisch notwendigen Cookies. Die Verarbeitung dient der Auslieferung, Stabilität und Sicherheit der Website.",
      second:
        "Rechtsgrundlage ist Art. 6 Abs. 1 lit. f DSGVO. Das berechtigte Interesse liegt im sicheren, zuverlässigen und missbrauchsgeschützten Betrieb dieses Webangebots. OpenAI kann Unterauftragsverarbeiter einsetzen. Übermittlungen außerhalb des EWR erfolgen laut Datenverarbeitungsvereinbarung auf Grundlage eines Angemessenheitsbeschlusses oder der EU-Standardvertragsklauseln.",
      terms: "Bedingungen für ChatGPT Sites",
      dpa: "Datenverarbeitungsvereinbarung",
    },
    en: {
      title: "2. Website hosting",
      first:
        "This website is provided through ChatGPT Sites. Acting as processor, OpenAI Ireland Limited may process technical data generated when the site is accessed, including log, usage and device information and data from strictly necessary cookies. This processing delivers, stabilises and secures the site.",
      second:
        "The legal basis is Article 6(1)(f) GDPR. The legitimate interest is the secure, reliable and abuse-resistant operation of this website. OpenAI may use subprocessors. According to its data processing addendum, transfers outside the EEA rely on an adequacy decision or the EU Standard Contractual Clauses.",
      terms: "ChatGPT Sites terms",
      dpa: "Data processing addendum",
    },
    fr: {
      title: "2. Hébergement du site",
      first:
        "Ce site est fourni par ChatGPT Sites. En qualité de sous-traitant, OpenAI Ireland Limited peut traiter les données techniques générées lors de la consultation, notamment les journaux, les informations d’utilisation et d’appareil ainsi que les données de cookies strictement nécessaires. Ce traitement sert à fournir, stabiliser et sécuriser le site.",
      second:
        "La base juridique est l’article 6, paragraphe 1, point f) du RGPD. L’intérêt légitime réside dans l’exploitation sûre, fiable et protégée contre les abus. OpenAI peut recourir à des sous-traitants ultérieurs. Selon son accord de traitement, les transferts hors EEE reposent sur une décision d’adéquation ou sur les clauses contractuelles types de l’UE.",
      terms: "Conditions de ChatGPT Sites",
      dpa: "Accord de traitement des données",
    },
  }[locale];

  return (
    <section>
      <h2>{content.title}</h2>
      <p>{content.first}</p>
      <p>{content.second}</p>
      <p className="legal-links">
        <ExternalLink href={OPENAI_SITES_TERMS}>{content.terms}</ExternalLink>
        <ExternalLink href={OPENAI_SITES_DPA}>{content.dpa}</ExternalLink>
      </p>
    </section>
  );
}

function CookieSection({ locale }) {
  const content = {
    de: {
      title: "3. Technisch notwendiger Sicherheits-Cookie",
      first:
        "Zum Schutz vor automatisierten und missbräuchlichen Zugriffen kann Cloudflare den Cookie __cf_bm setzen. Er enthält verschlüsselte Informationen zur Ermittlung eines Bot-Scores, ist keiner Benutzer-ID der App zugeordnet und läuft nach 30 Minuten fortlaufender Inaktivität ab. Er dient weder Werbung noch Reichweitenmessung.",
      second:
        "Die Speicherung ist für die sichere Bereitstellung des ausdrücklich angeforderten Webangebots erforderlich. Sie erfolgt auf Grundlage von § 25 Abs. 2 Nr. 2 TDDDG; die anschließende Verarbeitung auf Grundlage von Art. 6 Abs. 1 lit. f DSGVO. Da ausschließlich technisch notwendige Funktionen eingesetzt werden, wird derzeit kein Einwilligungsbanner verwendet.",
      link: "Cloudflare-Cookie-Dokumentation",
    },
    en: {
      title: "3. Strictly necessary security cookie",
      first:
        "Cloudflare may set the __cf_bm cookie to protect the site against automated and abusive access. It contains encrypted information used to calculate a bot score, is not linked to an app user ID and expires after 30 minutes of continuous inactivity. It is not used for advertising or audience measurement.",
      second:
        "Storage is necessary to securely provide the website expressly requested by the user. It is based on section 25(2)(2) TDDDG; subsequent processing is based on Article 6(1)(f) GDPR. Because only strictly necessary functions are used, no consent banner is currently displayed.",
      link: "Cloudflare cookie documentation",
    },
    fr: {
      title: "3. Cookie de sécurité strictement nécessaire",
      first:
        "Cloudflare peut déposer le cookie __cf_bm afin de protéger le site contre les accès automatisés ou abusifs. Il contient des informations chiffrées servant à calculer un score de robot, n’est lié à aucun identifiant utilisateur de l’app et expire après 30 minutes d’inactivité continue. Il ne sert ni à la publicité ni à la mesure d’audience.",
      second:
        "Ce stockage est nécessaire pour fournir en toute sécurité le service expressément demandé. Il repose sur l’article 25, paragraphe 2, point 2 de la loi allemande TDDDG ; le traitement ultérieur repose sur l’article 6, paragraphe 1, point f) du RGPD. Seules des fonctions strictement nécessaires étant utilisées, aucune bannière de consentement n’est actuellement affichée.",
      link: "Documentation des cookies Cloudflare",
    },
  }[locale];
  const [beforeCookie, afterCookie] = content.first.split("__cf_bm");

  return (
    <section>
      <h2>{content.title}</h2>
      <p>
        {beforeCookie}
        <code>__cf_bm</code>
        {afterCookie}
      </p>
      <p>{content.second}</p>
      <p className="legal-links"><ExternalLink href={CLOUDFLARE_COOKIES}>{content.link}</ExternalLink></p>
    </section>
  );
}

function GithubSection({ locale }) {
  const content = {
    de: {
      title: "5. GitHub, Downloads und Updates",
      first:
        "Quellcode, Versionshinweise und Installationsdateien liegen bei GitHub. Beim Anklicken eines GitHub- oder Download-Links stellt Ihr Browser eine direkte Verbindung zu GitHub her. Dabei verarbeitet GitHub insbesondere technische Verbindungsdaten nach seiner eigenen Datenschutzerklärung.",
      second:
        `Die in ${siteConfig.name} integrierte Update-Funktion ruft in regelmäßigen Abständen eine signierte Update-Information von GitHub ab. Dabei können GitHub die IP-Adresse, der Zeitpunkt des Abrufs und technische Angaben des verwendeten Clients bekannt werden.`,
      link: "Datenschutzerklärung von GitHub",
    },
    en: {
      title: "5. GitHub, downloads and updates",
      first:
        "Source code, release notes and installation files are hosted on GitHub. When a GitHub or download link is opened, the browser connects directly to GitHub, which processes technical connection data under its own privacy statement.",
      second:
        `${siteConfig.name} periodically retrieves signed update information from GitHub. GitHub may receive the IP address, request time and technical information about the client used.`,
      link: "GitHub privacy statement",
    },
    fr: {
      title: "5. GitHub, téléchargements et mises à jour",
      first:
        "Le code source, les notes de version et les fichiers d’installation sont hébergés sur GitHub. Lorsque vous ouvrez un lien GitHub ou de téléchargement, votre navigateur se connecte directement à GitHub, qui traite les données techniques de connexion conformément à sa propre déclaration de confidentialité.",
      second:
        `${siteConfig.name} récupère périodiquement auprès de GitHub des informations de mise à jour signées. GitHub peut alors recevoir l’adresse IP, l’heure de la requête et des informations techniques sur le client utilisé.`,
      link: "Déclaration de confidentialité de GitHub",
    },
  }[locale];

  return (
    <section>
      <h2>{content.title}</h2>
      <p>{content.first}</p>
      <p>{content.second}</p>
      <p className="legal-links"><ExternalLink href={GITHUB_PRIVACY}>{content.link}</ExternalLink></p>
    </section>
  );
}

function AppPrivacySection({ locale }) {
  const content = {
    de: {
      title: "6. Datenverarbeitung in der App",
      first:
        "Die App benötigt die macOS-Bedienungshilfen-Berechtigung, um das Fenster unter dem Mauszeiger zu erkennen und dessen Position oder Größe zu ändern. Fensterrollen, Positionen und Abmessungen werden lokal und nur zur Ausführung der gewählten Geste verarbeitet. Fenstertitel, App-Namen, Zeigerwege und Gestenverläufe werden weder gespeichert noch an den Betreiber übertragen. Die App enthält keine Telemetrie.",
      second:
        "Einstellungen wie Einführungsstatus, Aktivierungszustand, Start bei Anmeldung und Update-Einstellungen werden lokal auf dem Mac gespeichert. Sie bleiben dort, bis die Einstellungen zurückgesetzt oder die zugehörigen App-Daten entfernt werden.",
    },
    en: {
      title: "6. Data processing in the app",
      first:
        "The app needs macOS Accessibility permission to identify the window under the pointer and change its position or size. Window roles, positions and dimensions are processed locally and only to perform the selected gesture. Window titles, app names, pointer paths and gesture histories are neither stored nor sent to the operator. The app contains no telemetry.",
      second:
        "Settings such as onboarding status, enabled state, launch at login and update preferences are stored locally on the Mac until they are reset or the associated app data is removed.",
    },
    fr: {
      title: "6. Traitement des données dans l’app",
      first:
        "L’app nécessite l’autorisation Accessibilité de macOS pour identifier la fenêtre sous le pointeur et modifier sa position ou sa taille. Les rôles, positions et dimensions des fenêtres sont traités localement et uniquement pour exécuter le geste choisi. Les titres de fenêtres, noms d’apps, trajets du pointeur et historiques de gestes ne sont ni conservés ni transmis à l’exploitant. L’app ne contient aucune télémétrie.",
      second:
        "Les réglages tels que l’état de l’introduction, l’activation, le lancement à l’ouverture de session et les préférences de mise à jour sont enregistrés localement sur le Mac jusqu’à leur réinitialisation ou la suppression des données associées.",
    },
  }[locale];

  return (
    <section>
      <h2>{content.title}</h2>
      <p>{content.first}</p>
      <p>{content.second}</p>
    </section>
  );
}

const licenseMeta = [
  { name: siteConfig.name, copyright: "Copyright © 2026 Christian Hubmann", href: "/licenses/swindoo.txt" },
  { name: "Sparkle", copyright: "Copyright © 2006–2017 Sparkle contributors", href: "/licenses/sparkle.txt" },
  { name: "React & React DOM", copyright: "Copyright © Meta Platforms, Inc. and affiliates", href: "/licenses/react.txt" },
  { name: "Phosphor Icons", copyright: "Copyright © 2020 Phosphor Icons", href: "/licenses/phosphor-icons.txt" },
];

const licensesCopy = {
  en: {
    title: "Licenses",
    lead: `${siteConfig.name} is free software. These are the license notices for the project and the open-source components shipped directly with it.`,
    descriptions: [
      "The application and its source code are available under the MIT License.",
      "Sparkle provides signed updates for the macOS app.",
      "React powers this website’s user interface.",
      "Phosphor Icons provides this website’s interface icons.",
    ],
    open: "Open full license text",
  },
  de: {
    title: "Lizenzen",
    lead: `${siteConfig.name} ist freie Software. Hier stehen die Lizenzhinweise des Projekts und der direkt ausgelieferten Open-Source-Komponenten bereit.`,
    descriptions: [
      "Die Anwendung und ihr Quellcode stehen unter der MIT-Lizenz.",
      "Sparkle stellt die signierte Update-Funktion der macOS-App bereit.",
      "React bildet die Benutzeroberfläche dieser Website.",
      "Phosphor Icons stellt die Oberflächen-Icons dieser Website bereit.",
    ],
    open: "Vollständigen Lizenztext öffnen",
  },
  fr: {
    title: "Licences",
    lead: `${siteConfig.name} est un logiciel libre. Voici les mentions de licence du projet et des composants open source directement distribués.`,
    descriptions: [
      "L’application et son code source sont disponibles sous licence MIT.",
      "Sparkle fournit les mises à jour signées de l’app macOS.",
      "React fournit l’interface utilisateur de ce site.",
      "Phosphor Icons fournit les icônes d’interface de ce site.",
    ],
    open: "Ouvrir le texte intégral de la licence",
  },
};

export function LicensesPage({ locale }) {
  const copy = licensesCopy[locale];
  return (
    <LegalArticle locale={locale} eyebrow={shellCopy[locale].openSource} title={copy.title}>
      <p className="legal-lead">{copy.lead}</p>
      <div className="license-grid">
        {licenseMeta.map(({ name, copyright, href }, index) => (
          <section className="license-card" key={name}>
            <h2>{name}</h2>
            <p className="license-card__copyright">{copyright}</p>
            <p>{copy.descriptions[index]}</p>
            <a href={href}>
              {copy.open}
              <ArrowSquareOut weight="bold" aria-hidden="true" />
            </a>
          </section>
        ))}
      </div>
    </LegalArticle>
  );
}

function LegalArticle({ locale, eyebrow, title, children }) {
  return (
    <main className="legal-main">
      <article className="legal-article">
        <a className="legal-back" href={routeFor(locale, "landing")}>
          <ArrowLeft weight="bold" aria-hidden="true" />
          {shellCopy[locale].back}
        </a>
        <header className="legal-heading">
          <p>{eyebrow}</p>
          <h1>{title}</h1>
        </header>
        <div className="legal-content">{children}</div>
      </article>
    </main>
  );
}
