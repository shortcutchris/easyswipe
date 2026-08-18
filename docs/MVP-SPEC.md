# EasySwipe – MVP-Spezifikation

- Status: Implementierungsbasis 0.1.0
- Datum: 18. August 2026
- Produkttyp: native macOS-Menüleisten-App
- Vorläufiges Deployment-Ziel: macOS 14 oder neuer
- Architektur: Swift, AppKit mit kleinen SwiftUI-Oberflächen, Universal 2

## 1. Produktidee

EasySwipe ist ein bewusst reduzierter, gestenbasierter Fenstermanager für macOS. Die App macht die Titelbar eines Fensters zur Gestenfläche und unterstützt im MVP vier Aktionen: Fenster links anordnen, Fenster rechts anordnen, Fenster minimieren und Fenster im sichtbaren Bildschirmbereich maximieren.

Die Anwendung läuft als Menüleisten-App ohne reguläres Dock-Icon. Sie unterstützt:

- integrierte MacBook-Trackpads,
- Apple Magic Trackpad,
- Apple Magic Mouse.

Auf einem Trackpad entsteht die Eingabe durch die übliche Zwei-Finger-Scrollbewegung. Auf der Magic Mouse wird die entsprechende Oberflächen-Scrollbewegung verwendet. EasySwipe wertet die von macOS gelieferten kontinuierlichen Scrollereignisse aus und muss den Gerätetyp für die Kernfunktion nicht separat erkennen.

## 2. Produktziele

### 2.1 Primärziele

- Ein Fenster ohne Ziehen, Tastenkürzel oder Klick auf eine Bildschirmhälfte verschieben.
- Ein Fenster mit einer Abwärtsgeste minimieren.
- Ein Fenster mit einer Aufwärtsgeste auf den größten normalen Fensterrahmen maximieren.
- Jede erfolgreiche Aktion unmittelbar, aber unaufdringlich bestätigen.
- Nach der Ersteinrichtung ohne dauerhaft sichtbare Oberfläche arbeiten.
- Trackpad und Magic Mouse gleichwertig unterstützen.
- Alle sichtbaren Texte von Beginn an lokalisierbar halten.
- Sichere, signierte In-App-Updates über Sparkle anbieten.

### 2.2 Nicht-Ziele des MVP

- Drittel-, Viertel- oder frei konfigurierbare Fensterlayouts.
- macOS-Vollbild-, Schließen-, Verstecken- oder Wiederherstellen-Gesten.
- Verschieben auf andere Monitore oder Spaces.
- Tastaturkürzel.
- Live-Vorschau der späteren Fensterposition.
- Cloud-Synchronisation, Benutzerkonto oder Telemetrie.
- Eigene Update-Oberfläche anstelle der Sparkle-Standardoberfläche.
- Vertrieb über den Mac App Store.

## 3. Begriffe

- **Aktuelles Fenster:** Das Fenster, dessen gültige Titelbar beim Start der Geste unter dem Mauszeiger liegt.
- **Aktueller Bildschirm:** Der Bildschirm, der den Mauszeiger beim Start der Geste enthält.
- **Sichtbarer Bildschirmbereich:** Der von macOS gemeldete `NSScreen.visibleFrame`, also ohne den aktuell von Menüleiste, Dock und Kameraaussparung reservierten Bereich.
- **Physisches Gestenende:** Der Moment, in dem die Finger vom Trackpad oder von der Magic Mouse genommen werden; nachlaufendes Momentum zählt nicht dazu.
- **HUD:** Das nicht aktivierende visuelle Richtungsfeedback während einer erkannten Geste und kurz nach einer erfolgreichen Aktion.

## 4. Gesten und Aktionen

| Eingabe über einer gültigen Titelbar | Aktion beim physischen Gestenende | HUD-Symbol |
| --- | --- | --- |
| Nach links wischen | Fenster nimmt die linke Hälfte des aktuellen Bildschirms ein | links gefülltes Rechteck |
| Nach rechts wischen | Fenster nimmt die rechte Hälfte des aktuellen Bildschirms ein | rechts gefülltes Rechteck |
| Nach unten wischen | Fenster wird in den Dock minimiert | Minuszeichen |
| Nach oben wischen | Fenster füllt den sichtbaren Bildschirmbereich, ohne in den macOS-Vollbildmodus zu wechseln | diagonal auseinanderzeigende Pfeile |

### 4.1 Grundregeln

- Die Geste erfordert keinen Klick und kein Gedrückthalten.
- Das Zielfenster wird beim Beginn der Geste festgelegt und während derselben Geste nicht gewechselt.
- Nach Überschreiten der Totzone zeigt das HUD sofort die aktuell erkannte Richtung; bei einem Richtungswechsel wird das Symbol aktualisiert.
- Die Aktion wird ausschließlich beim physischen Gestenende ausgeführt.
- Nachlaufende Momentum-Ereignisse dürfen keine Aktion auslösen oder eine Aktion wiederholen.
- Ein Swipe in dieselbe Richtung ist idempotent: Ein bereits links angeordnetes Fenster bleibt bei einem erneuten Swipe nach links links angeordnet.
- Kurze, mehrdeutige, stark diagonale oder umgekehrte Bewegungen führen zu keiner Aktion. Eine bereits sichtbare Vorschau wird beim Abbruch ausgeblendet.
- EasySwipe unterdrückt normale Scrollereignisse nicht. Stattdessen wird nur in einer gültigen, nicht interaktiven Titelbarregion erkannt.

### 4.2 Vorläufige Erkennungsparameter

Diese Werte sind Startwerte für Hardwaretests und keine unveränderlichen Produktkonstanten:

- Totzone ab Gestenbeginn: 10 Punkte.
- Mindest-Nettoentfernung für eine Aktion: 44 Punkte.
- Achsendominanz: dominante Achse mindestens Faktor 1,35 gegenüber der anderen Achse.
- Zulässige Richtungen im MVP: links, rechts, unten und oben.
- Momentum: vollständig ignorieren.
- Kontinuierliche Scrollereignisse: erforderlich; klassische Mausräder lösen keine EasySwipe-Geste aus.

Die Bewegungsrichtung muss auf die physische Fingerbewegung normalisiert werden, unabhängig von der macOS-Einstellung „Scrollrichtung: Natürlich“.

## 5. Gesten-Zustandsmaschine

### 5.1 Zustände

1. **idle** – Keine relevante Geste aktiv.
2. **candidate** – Ein physischer Scroll beginnt; Mausposition, Bildschirm und mögliches Zielfenster werden ermittelt.
3. **tracking** – Das Ereignis begann über einer gültigen Titelbar; normalisierte Deltas werden gesammelt.
4. **previewing** – Totzone und Achsendominanz sind erreicht; das HUD zeigt die mögliche Richtung, ohne das Fenster zu verändern.
5. **qualified** – Die Mindestdistanz für die Aktion ist erreicht; die Zielaktion steht fest, wird aber noch nicht ausgeführt.
6. **committed** – Die Finger wurden abgehoben und die Aktion wurde erfolgreich ausgeführt.
7. **cancelled** – Die Geste war ungültig, mehrdeutig, nicht unterstützt oder das Fenster konnte nicht verändert werden.

### 5.2 Übergangsregeln

- `idle → candidate` nur bei Beginn einer physischen, kontinuierlichen Scrollsequenz.
- `candidate → tracking` nur bei gültigem Fenster und gültiger Titelbarregion.
- `candidate → cancelled` bei interaktivem Kontrollelement, nicht unterstütztem Fenster oder fehlender Berechtigung.
- `tracking → previewing`, sobald Totzone und Richtungsdominanz erfüllt sind.
- `previewing → qualified`, sobald die Mindestdistanz für eine Aktion erreicht ist.
- Die angezeigte Richtung darf sich vor dem Loslassen ändern, wenn der Nettovektor deutlich in eine andere unterstützte Richtung wechselt.
- `tracking/previewing/qualified → committed` nur beim physischen Gestenende und nur mit gültiger unterstützter Richtung und Mindestdistanz.
- `tracking/previewing/qualified → cancelled` bei Abbruch, Mehrdeutigkeit oder nicht mehr gültigem AX-Fensterobjekt.
- Momentum-Ereignisse nach `committed` oder `cancelled` werden verworfen, bis eine neue physische Geste beginnt.

## 6. Fensterauswahl und Titelbar-Erkennung

### 6.1 Zielfenster

EasySwipe fragt über die macOS Accessibility API das Element unter der Mausposition ab und steigt zu dessen zugehörigem Fenster auf. Es wird nicht pauschal das fokussierte oder vorderste Fenster verwendet. Dadurch kann ein sichtbares Hintergrundfenster direkt über seine Titelbar angeordnet werden.

### 6.2 Gültige Titelbarregion

Priorität der Erkennung:

1. Semantische Accessibility-Informationen für Titelbar oder Fensterrahmen verwenden.
2. Falls eine App keine ausreichenden semantischen Daten liefert, eine konservative obere Rahmenzone als Fallback verwenden.
3. Interaktive Accessibility-Rollen wie Button, Textfeld, Suchfeld, Tab, Slider oder Scrollbereich ausschließen.

Die Fallback-Zone darf nicht dazu führen, dass horizontales Scrollen in Safari-Tabs, Browser-Tabstrips oder anderen interaktiven Toolbars Fensterbewegungen auslöst.

Warp verwendet auf macOS eine eigene Titelleisten- und Tab-Oberfläche. Für Bundle-IDs unter `dev.warp.Warp…` darf deshalb der leere `AXToolbar`-Container als Titelbarregion gelten und die konservative obere Rahmenzone 56 Punkte hoch sein. Darin enthaltene Buttons, Tabs, Textfelder und andere interaktive Elemente bleiben ausgeschlossen. Für andere Apps bleibt die strengere Standardregel unverändert.

### 6.3 Nicht unterstützte Fenster

Folgende Fenster werden im MVP ohne Aktion und ohne HUD ignoriert:

- Vollbildfenster,
- borderless Fenster ohne belastbare Titelbar,
- Fenster ohne setzbare Positions- oder Größenattribute bei Links/Rechts,
- Fenster ohne setzbare Positions- oder Größenattribute bei Swipe nach oben,
- Fenster ohne setzbares Minimierungsattribut bei Swipe nach unten,
- Popovers, Menüs, Tooltips und temporäre Panels,
- Fenster, die während der Geste geschlossen oder ungültig werden,
- eigene EasySwipe-Fenster und HUDs.

## 7. Fenstergeometrie

### 7.1 Bildschirmwahl

- Maßgeblich ist der Bildschirm unter dem Mauszeiger beim Gestenbeginn.
- Die Aktion bleibt auf diesem Bildschirm.
- EasySwipe wechselt weder Monitor noch Space.

### 7.2 Halbierung

Ausgangspunkt ist der aktuelle `visibleFrame` des Bildschirms. Der Wert wird bei jeder Aktion neu gelesen und nicht dauerhaft gecacht.

- Linke Hälfte: linke Kante des `visibleFrame`, halbe sichtbare Breite, volle sichtbare Höhe.
- Rechte Hälfte: beginnt direkt nach der linken Hälfte und erhält die verbleibende Breite.
- Ungerade Pixel- oder Punktbreiten werden so aufgeteilt, dass keine Lücke und keine Überlappung entsteht.
- Dock-Position, automatisch ausgeblendetes Dock, Menüleiste und Kameraaussparung werden durch `visibleFrame` berücksichtigt.
- Es werden keine eigenen Ränder oder Lücken hinzugefügt.

### 7.3 Maximierung

Beim Swipe nach oben wird das Fenster auf den vollständigen aktuellen `visibleFrame` gesetzt. Das ist bewusst eine normale Fenstergrößenänderung: EasySwipe setzt weder `AXFullScreen` noch löst es den grünen Vollbildmodus aus, und es wird kein eigener Space angelegt. Menüleiste, Dock und Kameraaussparung bleiben berücksichtigt.

Die Accessibility API und AppKit verwenden unterschiedliche Bildschirmkoordinaten. Die Umrechnung wird zentral implementiert und mit Multi-Monitor-Anordnungen oberhalb, unterhalb, links und rechts des Hauptbildschirms getestet.

### 7.4 Größenbeschränkungen einer App

Falls eine Ziel-App eine Mindestgröße erzwingt, darf sie das angeforderte Rechteck begrenzen. EasySwipe liest den resultierenden Rahmen zurück. Die Vorschau erscheint während der Geste; als Bestätigung bleibt das HUD nur sichtbar, wenn eine erkennbare Positions-, Größen- oder Minimierungsänderung stattgefunden hat.

## 8. Visuelles Feedback

### 8.1 Darstellung

- Nicht aktivierendes, rahmenloses `NSPanel`.
- Kein Wechsel der aktiven App und kein Tastaturfokus.
- Größe: 36 × 36 Punkte.
- Hintergrund: macOS-Material mit 10 Punkten Eckenradius.
- Symbolgröße: 16 × 16 Punkte.
- Symbol: monochromes SF Symbol beziehungsweise systemnahes Symbol mit hohem Kontrast.
- Kein Text im normalen HUD.
- Position während der Geste und nach dem Loslassen: unmittelbar neben dem Mauszeiger, ohne ihn zu verdecken.
- An Bildschirmrändern weicht das HUD automatisch auf die gegenüberliegende Cursorseite aus und bleibt vollständig im sichtbaren Bildschirmbereich.

### 8.2 Timing

- Die HUD-Vorschau startet innerhalb von 100 ms nach Überschreiten der Totzone.
- Einblenden: ungefähr 60 ms; danach bleibt die Vorschau bis zum Gestenende sichtbar.
- Die Fensteraktion startet innerhalb von 100 ms nach dem physischen Gestenende.
- Erfolgsbestätigung nach dem Loslassen: ungefähr 380 ms, anschließend ungefähr 140 ms Ausblenden.
- Eine neue Richtung oder Aktion ersetzt ein noch sichtbares HUD, statt mehrere HUDs zu stapeln.

### 8.3 Bedienungshilfen

- Bei „Bewegung reduzieren“ wird nur über Deckkraft animiert.
- Bei „Transparenz reduzieren“ oder „Kontrast erhöhen“ wird ein deckenderer Systemhintergrund verwendet.
- Wenn VoiceOver aktiv ist, kann eine kurze lokalisierte Accessibility-Ankündigung wie „Fenster links angeordnet“ ausgegeben werden; diese darf den Fokus nicht verändern.

## 9. Menüleisten-App

### 9.1 App-Verhalten

- `LSUIElement = true`; kein reguläres Dock-Icon und kein dauerhaftes Hauptfenster.
- Monochromes Template-Icon in der Menüleiste.
- Ein Klick öffnet das Statusmenü.
- Beim Start wird kein Fenster geöffnet, sofern alle erforderlichen Berechtigungen vorhanden sind und das Onboarding abgeschlossen wurde.
- Bei fehlenden Berechtigungen zeigt das Menüleisten-Icon einen dezenten Warnzustand.

### 9.2 Menüstruktur

| Schlüssel | Deutsch | Englisch | Verhalten |
| --- | --- | --- | --- |
| `menu.enabled` | EasySwipe aktiv | EasySwipe Enabled | globaler Ein/Aus-Schalter |
| `menu.launchAtLogin` | Beim Anmelden starten | Launch at Login | Login-Item umschalten |
| `menu.gestureGuide` | Gestenübersicht… | Gesture Guide… | kompakte Anleitung öffnen |
| `menu.permissions` | Berechtigungen… | Permissions… | Status und Systemeinstellungen öffnen |
| `menu.checkForUpdates` | Nach Updates suchen… | Check for Updates… | manuelle Sparkle-Prüfung |
| `menu.about` | Über EasySwipe | About EasySwipe | Version, Build und Links |
| `menu.quit` | EasySwipe beenden | Quit EasySwipe | App beenden |

Zwischen Funktionsschaltern, Hilfe/Update und Beenden werden Trenner verwendet. Das Menü muss vollständig per Tastatur und VoiceOver bedienbar sein.

## 10. Ersteinrichtung und Berechtigungen

### 10.1 Onboarding

Beim ersten Start erscheint ein kleines lokalisiertes Setup-Fenster:

1. **Willkommen:** Nutzen und die vier Gesten erklären.
2. **Bedienungshilfen:** Accessibility-Zugriff anfordern und Status live prüfen.
3. **Eingabeüberwachung:** Nur anzeigen, wenn die gewählte Event-Tap-Implementierung diese Berechtigung auf dem laufenden macOS tatsächlich benötigt.
4. **Beim Anmelden starten:** standardmäßig angeboten, aber nicht ohne ausdrückliche Benutzeraktion aktivieren.
5. **Bereit:** kurze gerätespezifische Formulierung für Trackpad und Magic Mouse.

Das Fenster darf erst „Bereit“ melden, wenn die zwingenden Berechtigungen aktiv sind. Der Benutzer kann das Onboarding schließen; EasySwipe bleibt dann installiert, aber die Gestenerkennung deaktiviert und das Menü zeigt den fehlenden Status.

### 10.2 Berechtigungsprinzip

- Accessibility ist erforderlich, um Fenster anderer Apps zu identifizieren und zu verändern.
- Ein globaler, passiver `NSEvent`-Monitor beobachtet ausschließlich kontinuierliche Scrollereignisse und unterdrückt oder verändert sie nicht.
- Die Implementierung benötigt für den Listener keine separate Eingabeüberwachungs-Berechtigung. Accessibility bleibt für das Ermitteln und Verändern fremder Fenster erforderlich.
- Die App fordert nur tatsächlich benötigte Rechte an.
- Ein Entzug der Berechtigung wird während der Laufzeit erkannt; die Listener werden gestoppt und der Menüstatus aktualisiert.

## 11. Trackpad und Magic Mouse

### 11.1 Trackpad

- Unterstützt integriertes MacBook-Trackpad und Apple Magic Trackpad.
- Benutzerformulierung: Zwei Finger über der Titelbar nach links, rechts, unten oder oben bewegen.
- Force Click, Drei-Finger-Ziehen und andere macOS-Gesten dürfen nicht benötigt werden.

### 11.2 Magic Mouse

- Benutzerformulierung: Über der Titelbar auf der Touch-Oberfläche nach links, rechts, unten oder oben wischen.
- Die Kernlogik wertet kontinuierliche Scroll-Deltas aus und verlangt keine künstliche Zwei-Finger-Erkennung auf der Magic Mouse.
- Systemgesten zum Wechseln von Vollbild-Apps oder Spaces dürfen nicht bewusst abgefangen oder ersetzt werden.
- Die Schwellenwerte dürfen für Magic Mouse und Trackpad intern getrennt konfigurierbar sein, falls Hardwaretests deutliche Unterschiede zeigen. Im MVP gibt es dafür keine Benutzeroberfläche.

### 11.3 Klassische Mäuse

Diskrete Mausradereignisse sind nicht Teil des MVP. Eine klassische Scrollrad-Maus darf durch Drehen des Rads über einer Titelbar keine Aktion auslösen.

## 12. Lokalisierung und Internationalisierung

### 12.1 Sprachen zum MVP-Start

- Entwicklungs- und Fallback-Sprache: Englisch (USA), `en-US`.
- Vollständige Erstlokalisierung: Deutsch, `de`.
- Architektur bereit für weitere Sprach- und Regionsvarianten.
- Die App folgt der in macOS pro App oder systemweit gewählten Sprache; kein eigener Sprachumschalter im MVP.

### 12.2 Technische Regeln

- Alle benutzersichtbaren App-Texte liegen in Xcode String Catalogs (`.xcstrings`).
- Keine benutzersichtbaren String-Literale außerhalb lokalisierbarer APIs.
- Semantische, stabile Schlüssel statt englischer Sätze als Schlüssel.
- Kommentare für Übersetzer beschreiben Kontext, Gerät und Aktion.
- Keine zusammengesetzten Sätze aus mehreren übersetzten Fragmenten.
- Menü, Onboarding, Berechtigungsstatus, Fehler, Accessibility-Ankündigungen, About-Fenster und Update-Einstieg werden lokalisiert.
- `InfoPlist.xcstrings` enthält lokalisierbare Berechtigungs- und Anzeigenamen, sofern erforderlich.
- Layout verwendet leading/trailing und bleibt für spätere Rechts-nach-links-Sprachen geeignet.
- Beide Startsprachen werden automatisiert auf fehlende Übersetzungen geprüft.

Sparkles Standardoberfläche wird in der zum System passenden, von Sparkle angebotenen Lokalisierung angezeigt. EasySwipe-eigene Menüpunkte und Texte bleiben im eigenen String Catalog.

## 13. Start bei Anmeldung

- Implementierung mit `SMAppService.mainApp`.
- Aktivierung nur nach bewusster Benutzeraktion im Menü oder Onboarding.
- Status im Menü entspricht dem tatsächlichen `SMAppService`-Status, nicht nur einem gespeicherten Boolean.
- Fehler oder verweigerte Systemfreigabe werden lokalisiert erklärt.
- Beim Login startet EasySwipe im Hintergrund ohne Onboarding- oder About-Fenster.

## 14. Sparkle-Updates

### 14.1 Integration

- Sparkle 2 über Swift Package Manager.
- Beim Implementierungsbeginn aktuelle stabile Sparkle-2-Version verwenden und in `Package.resolved` festhalten.
- Standardintegration über `SPUStandardUpdaterController`.
- Menüpunkt „Nach Updates suchen…“ beziehungsweise „Check for Updates…“ ist mit `checkForUpdates(_:)` verbunden.
- Automatische Update-Prüfung folgt Sparkles Zustimmungs- und Einstellungsmodell; keine erzwungene Prüfung bei jedem App-Start.
- MVP verwendet ausschließlich einen stabilen Release-Kanal.

### 14.2 Appcast und Sicherheit

- Appcast wird über HTTPS von einem noch festzulegenden statischen Update-Host ausgeliefert.
- `SUFeedURL` wird in der App-Konfiguration gesetzt.
- Updates werden mit Sparkles EdDSA-Verfahren signiert; der öffentliche Schlüssel liegt als `SUPublicEDKey` in der App.
- Der private EdDSA-Schlüssel darf weder im Repository noch auf dem öffentlichen Update-Host liegen.
- Jede Veröffentlichung wird zusätzlich mit Developer ID signiert und von Apple notarisiert.
- `CFBundleVersion` steigt bei jedem veröffentlichten Build monoton.
- Appcast und Update-Archiv werden im Release-Prozess mit Sparkles Werkzeugen erzeugt und validiert.
- Update-Fehler dürfen die Gestenerkennung nicht beeinträchtigen.

### 14.3 Release-Ablauf

1. Release-Build als Universal-2-App erzeugen.
2. Mit Developer ID signieren und Hardened Runtime prüfen.
3. Notarisieren und Ticket anheften.
4. Archiv oder DMG erzeugen.
5. Update-Archiv mit Sparkle EdDSA signieren.
6. Appcast generieren und validieren.
7. Archiv und Appcast auf den HTTPS-Host laden.
8. Update von der zuletzt veröffentlichten Version auf einem sauberen Testsystem prüfen.
9. Erst danach den Release öffentlich ankündigen.

## 15. Architektur

### 15.1 Komponenten

- **AppCoordinator:** Lebenszyklus und Zusammenspiel der Dienste.
- **StatusMenuController:** Menüleisten-Icon, Menü und lokalisierte Zustände.
- **PermissionController:** Accessibility-Status und Live-Aktualisierung bei Änderungen.
- **GestureEventMonitor:** globaler `NSEvent`-Scrollmonitor und Ereignisfilterung.
- **GestureRecognizer:** geräteunabhängige Normalisierung und Zustandsmaschine.
- **WindowResolver:** AX-Element unter Maus, Fenster- und Titelbarprüfung.
- **WindowActionService:** Links/Rechts/Minimieren und Ergebnisprüfung.
- **ScreenGeometryService:** Bildschirmwahl, `visibleFrame` und Koordinatenumrechnung.
- **HUDPresenter:** nicht aktivierendes Feedback-Panel.
- **LoginItemController:** `SMAppService`.
- **UpdateController:** Sparkle-Lebenszyklus und Menüaktion.
- **OnboardingCoordinator:** Einrichtung und Berechtigungen.

### 15.2 Nebenläufigkeit

- Der globale Event-Monitor-Callback bleibt extrem kurz und reicht ausschließlich normalisierte, sendbare Scrollmetadaten weiter.
- Deltas werden aus dem Callback als sendbare Werte auf den seriell arbeitenden Main Actor übergeben.
- AppKit-, AX-Schreib- und HUD-Aktionen werden kontrolliert auf dem Main Actor beziehungsweise geeigneten seriellen Kontext ausgeführt.
- Langsame oder nicht antwortende AX-Ziel-Apps erhalten ein kurzes Timeout; EasySwipe blockiert nicht global.

### 15.3 Zustandsdaten

In `UserDefaults` gespeichert werden nur:

- Onboarding abgeschlossen,
- EasySwipe aktiviert/deaktiviert,
- optional intern kalibrierte Standardparameter beziehungsweise Feature Flags,
- Sparkle-eigene Einstellungen über Sparkles APIs.

Der tatsächliche Login-Item- und Berechtigungsstatus wird stets vom System gelesen.

## 16. Datenschutz und Sicherheit

- Keine Telemetrie oder Analyse im MVP.
- Keine Aufzeichnung von Mauspfaden, App-Namen, Fenstertiteln oder Gestenverlauf.
- Der Event Tap verarbeitet nur die für die Gestenerkennung notwendigen Scrollmetadaten im Arbeitsspeicher.
- Keine Tastaturereignisse beobachten.
- Keine Netzwerkkommunikation außer Sparkle-Appcast, Update-Download und vom Benutzer geöffneten Produkt-/Supportlinks.
- OSLog enthält keine Fenstertitel, Dateinamen oder personenbezogenen Inhalte.
- Release-Build: Developer ID, Hardened Runtime und Notarisierung.
- Da systemweite Fenstersteuerung und Sparkle-Selbstupdates benötigt werden, ist der MVP für direkte Distribution außerhalb des Mac App Store vorgesehen.

## 17. Fehlerverhalten

- Ungültige Geste: still abbrechen.
- Nicht unterstütztes Fenster: still abbrechen.
- Fehlende Berechtigung: keine Aktion; Warnzustand im Menü, optional einmalige lokale Hinweisanzeige.
- Globaler Event-Monitor nicht verfügbar: Listener stoppen und Warnzustand im Menü anzeigen.
- AX-Ziel antwortet nicht: Geste abbrechen, Event-Verarbeitung fortsetzen.
- Sparkle-Fehler: Sparkle-Standardmeldung bei manueller Prüfung; keine Auswirkung auf die Kernfunktion.
- Login-Item-Fehler: lokalisierte Erklärung direkt nach der Benutzeraktion.

## 18. Qualitätsziele

- Leerlauf-CPU im Normalbetrieb: im Mittel unter 0,5 % auf Apple Silicon.
- Keine merkbare Verschlechterung des normalen Trackpad- oder Magic-Mouse-Scrollens.
- Event-Tap-Callback: Zielwert unter 2 ms; keine AX-Abfragen direkt im Callback.
- HUD-Beginn: unter 100 ms nach Überschreiten der Totzone; erfolgreiche Aktion unter 100 ms nach Fingerfreigabe.
- Keine Aktivierung von EasySwipe und kein Verlust des Fokus der Ziel-App.
- Kein mehrfaches Auslösen durch Momentum.
- Speicherziel im Leerlauf: unter 60 MB.

## 19. Testmatrix

### 19.1 Hardware

- MacBook mit integriertem Force-Touch-Trackpad.
- Apple Magic Trackpad.
- Apple Magic Mouse.
- Mindestens ein Apple-Silicon-Mac und ein unterstützter Intel-Mac für Universal 2.

### 19.2 Systeme

- Niedrigste unterstützte macOS-Version.
- Aktuelle produktive macOS-Version.
- Neueste verfügbare macOS-Version vor jedem Release.
- Ein Bildschirm, zwei Bildschirme und unterschiedlich skalierte Bildschirme.
- Dock unten, links, rechts und automatisch ausgeblendet.
- Menüleiste auf unterschiedlichen Displays.
- Natürliche Scrollrichtung ein und aus.

### 19.3 Ziel-Apps

- Finder und andere native AppKit-/SwiftUI-Apps.
- Safari mit normaler und kompakter Tabdarstellung.
- Mail.
- Systemeinstellungen.
- Xcode.
- Chromium-basierte App wie Chrome.
- Electron-App wie Visual Studio Code.
- App mit Mindestfenstergröße.
- Dialog, Sheet und nicht veränderbares Fenster.

### 19.4 Automatisierte Tests

- Richtungsnormalisierung mit natürlicher Scrollrichtung ein/aus.
- Schwellenwert- und Achsendominanztests.
- Kurze, diagonale, umgekehrte und abgebrochene Gesten.
- Momentum-Sequenzen nach erfolgreicher und abgebrochener Geste.
- Geometrie für alle Monitoranordnungen und ungerade Breiten.
- Login-Item-Zustandsabbildung.
- Fehlende Übersetzungen in `en-US` und `de`.
- Sparkle-Appcast- und Signaturprüfung im Release-Workflow.

## 20. MVP-Akzeptanzkriterien

Der MVP gilt als funktionsfähig, wenn alle folgenden Kriterien erfüllt sind:

1. Ein Zwei-Finger-Swipe nach links über einer gültigen Titelbar auf einem Trackpad ordnet das Fenster nach dem Loslassen links an.
2. Ein entsprechender Swipe nach rechts ordnet es rechts an.
3. Ein Swipe nach unten minimiert genau dieses Fenster.
4. Ein Swipe nach oben maximiert genau dieses Fenster innerhalb des sichtbaren Bildschirmbereichs, ohne den macOS-Vollbildmodus zu aktivieren.
5. Dieselben vier Aktionen funktionieren über die Touch-Oberfläche einer Apple Magic Mouse.
6. Kurze und diagonale Bewegungen verändern kein Fenster.
7. Momentum löst keine zweite Aktion aus.
8. Scrollen in Fensterinhalten und interaktiven Toolbars bleibt unbeeinträchtigt.
9. Jede erkannte Richtung zeigt während der Geste ein nicht fokussierendes HUD; eine erfolgreiche Aktion bestätigt sie kurz nach dem Loslassen.
10. Snapping und Maximieren respektieren Menüleiste, Dock, Kameraaussparung und den aktuellen Bildschirm.
11. Die App arbeitet ausschließlich aus der Menüleiste und erscheint nicht regulär im Dock.
12. Das Menü ist vollständig auf Deutsch und Englisch verfügbar und folgt der macOS-App-Sprache.
13. „Beim Anmelden starten“ kann aus Menü und Onboarding aktiviert und deaktiviert werden.
14. Eine manuelle Update-Prüfung über Sparkle ist aus dem Menü möglich.
15. Ein signiertes, notarisiertes Testupdate kann über den Appcast installiert werden.
16. Ohne die nötigen Berechtigungen wird keine teilweise oder unvorhersehbare Fensteraktion ausgeführt.

## 21. Offene Entscheidungen vor öffentlicher Distribution

- Update-Host und öffentliche Produkt-/Support-URLs.
- Developer-ID-Team, Notarisierungsprofil und Sparkle-EdDSA-Schlüsselpaar.
- Exakte Titelbar-Fallback-Höhe nach breiten Hardware- und App-Kompatibilitätstests.
- Finale Erkennungsschwellen getrennt nach Trackpad und Magic Mouse, falls Hardwaretests einen relevanten Unterschied zeigen.
- HUD-Feintiming nach visuellem und praktischem Hardwaretest.

## 22. Referenzen

- Swish: <https://highlyopinionated.co/swish/>
- Apple – Quartz Event Services: <https://developer.apple.com/documentation/coregraphics/quartz-event-services>
- Apple – Trackpad Events: <https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/HandlingTouchEvents/HandlingTouchEvents.html>
- Apple – AXUIElement: <https://developer.apple.com/documentation/applicationservices/axuielement_h>
- Apple – `NSScreen.visibleFrame`: <https://developer.apple.com/documentation/appkit/nsscreen/visibleframe>
- Apple – `SMAppService.mainApp`: <https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp>
- Apple – String Catalogs: <https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog>
- Apple – Magic Mouse settings: <https://support.apple.com/guide/mac-help/mh29222/mac>
- Sparkle – Documentation: <https://sparkle-project.org/documentation/>
- Sparkle – Programmatic setup: <https://sparkle-project.org/documentation/programmatic-setup/>
