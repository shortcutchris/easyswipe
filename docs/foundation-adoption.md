# Übernommene macOS Product Foundation

- **Foundation-Revision:** `fd6b05b`
- **Übernommen am:** 29. August 2026
- **Entscheidung:** `0007 – Ruhiges, barrierefreies Motion-System`

Swindoo übernimmt die zentrale Feedback-Stufe mit 130 ms und hält Fensterbewegungen vollständig von visuellen Übergängen getrennt. Das HUD verwendet 90 ms für sein dezentes Erscheinen, 130 ms für die richtungsabhängige Aktionsbestätigung und 140 ms für das Ausblenden.

Da das HUD als AppKit-`NSPanel` umgesetzt ist, verwendet Swindoo eine AppKit- und Core-Animation-Definition namens `SwindooMotion` statt der SwiftUI-Vorlage. Die Menüoption „Animationen anzeigen“ ist standardmäßig aktiv und dauerhaft gespeichert. Sowohl eine deaktivierte Option als auch die macOS-Bedienungshilfe „Bewegung reduzieren“ schalten die räumlichen HUD-Animationen vollständig aus.
