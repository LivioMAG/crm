# Einfaches CRM

Eine sehr einfache, responsive CRM-Web-App auf Basis von HTML, CSS und Vanilla JavaScript. Die Oberfläche ist vollständig auf Deutsch und speichert Firmen, Kontakte und Follow-ups lokal im Browser per `localStorage`.

## Funktionen

- Übersicht mit Kennzahlen, offenen Follow-ups, heute fälligen Aufgaben und zuletzt aktualisierten Firmen
- Firmen anlegen, bearbeiten, löschen und im Detail öffnen
- Kontakte anlegen, bearbeiten, löschen und Firmen zuordnen
- Follow-ups anlegen, bearbeiten, löschen, erledigen und wieder öffnen
- Hervorhebung überfälliger Follow-ups
- Mobile Kartenansichten für schmale Bildschirme

## Lokal starten

```bash
python3 -m http.server 4174 --bind 127.0.0.1
```

Anschließend im Browser öffnen:

```text
http://127.0.0.1:4174/index.html
```
