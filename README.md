# Einfaches CRM

Eine sehr einfache, responsive CRM-Web-App auf Basis von HTML, CSS und Vanilla JavaScript. Die Oberfläche ist vollständig auf Deutsch und speichert CRM-Daten nach Login vollständig in Supabase.

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


## Supabase einrichten

1. Neues Supabase-Projekt erstellen und im SQL Editor den Inhalt von `supabase/schema.sql` ausführen. Wenn die Datenbank ohne Row Level Security betrieben werden soll, stattdessen `supabase/schema-ohne-rls.sql` verwenden; diese Variante löscht keine Tabellen und deaktiviert RLS für die CRM-Tabellen.
2. In `config/supabase-config.json` `url` und `anonKey` mit der Projekt-URL und dem öffentlichen Anon-Key ersetzen.
3. In Supabase Auth E-Mail/Passwort aktivieren. Bei Bedarf E-Mail-Bestätigung ein- oder ausschalten.

Die App bietet Login und Registrierung mit E-Mail, Passwort, Vorname und Nachname. CRM-Daten werden benutzerbezogen in eigenen Supabase-Tabellen (`companies`, `contacts`, `followUps`, `products`, `sales`) gespeichert; Profile liegen in `public.profiles`.
