# Übernommene macOS Product Foundation

- **Foundation-Revision:** `fd6b05b`
- **Übernommen am:** 29. August 2026
- **Entscheidung:** `0007 – Ruhiges, barrierefreies Motion-System`

Swindoo übernimmt die zentrale Feedback-Stufe mit 130 ms und hält Fensterbewegungen vollständig von visuellen Übergängen getrennt. Das HUD verwendet 90 ms für sein dezentes Erscheinen, 130 ms für die richtungsabhängige Aktionsbestätigung und 140 ms für das Ausblenden.

Da das HUD als AppKit-`NSPanel` umgesetzt ist, verwendet Swindoo eine AppKit- und Core-Animation-Definition namens `SwindooMotion` statt der SwiftUI-Vorlage. Die Menüoption „Animationen anzeigen“ ist standardmäßig aktiv und dauerhaft gespeichert. Sowohl eine deaktivierte Option als auch die macOS-Bedienungshilfe „Bewegung reduzieren“ schalten die räumlichen HUD-Animationen vollständig aus.

## H1 – Sprache, Darstellung und Updates (0.1.10 / 18)

- Basis: Foundation `a7b8abd`, gemeinsamer I/U-Standard und H0/H1-Plan vom 03.11.2026; Zielstandard-Ergänzung vom 04.11.2026.
- Kompakte native Allgemein-/Updates-Ansicht, Menüzugang, ⌘, und gemeinsamer Update-Einstieg im Über-Fenster.
- Neue Keys `interface.language` und `interface.appearance`; fehlende/unbekannte Werte werden als System aufgelöst. Vorhandene Aktivierung, Animationen und Onboarding werden nicht zurückgesetzt. Sparkle bleibt Owner seiner bisherigen Updatepräferenzen.
- Eigene DE/EN-Texte werden dynamisch aus dem String Catalog gelesen. Regionale Formate bleiben systemgeführt; keine Änderung von `AppleLanguages` oder globalen macOS-Präferenzen im Produkt.
- AppKit-Window-Appearance und SwiftUI-Inhalte folgen derselben Auswahl. System entfernt bestehende Overrides. Fremde Fenster bleiben unberührt; das kurzlebige HUD bleibt bewusst ein kontrastreiches Overlay.
- Update-Owner: Sparkle 2.9.6, bestehender öffentlicher HTTPS-Kanal und EdDSA-Schlüssel. Installationsaufschub ist an konkrete Gesten-/Fensteroperationen gebunden, nicht an offene Einstellungen.
- Ausnahme I03: Sparkle und systemverwaltete Dialoge folgen der macOS-App-Sprache. Das ist in Updates und den Neuerungen erklärt. Kein erzwungener System-Sprachwechsel.
- Nicht anwendbar: Modelle, Konten, KI-Ausgabesprache; Swindoo besitzt diese Funktionen nicht.
- Abnahme: `docs/qa/0.1.10.md`; Ergebnisse werden nur nach tatsächlichem Lauf eingetragen. macOS 14/15 und macOS 27 bleiben ohne passenden Host ausdrücklich ungetestet.
