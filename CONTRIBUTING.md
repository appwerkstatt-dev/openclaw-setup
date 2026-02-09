# Contributing

Danke fuer jeden Beitrag.
Ziel ist ein robustes, nachvollziehbares Setup mit realem Praxisnutzen.

## Wie du helfen kannst

- Sicherheitsluecken oder harte Kanten melden
- Setup fuer andere Linux-Varianten verbessern
- Skripte idempotenter machen
- Doku klarer und fehlertoleranter machen

## Issue-Workflow

Bitte die passenden Templates nutzen:
- `Bug report` fuer reproduzierbare Fehler
- `Hardening idea` fuer Security-/Betriebsvorschlaege
- `Docs feedback` fuer Doku-Luecken

## Bevor du einen PR oeffnest

1. Fuehre `bash -n scripts/*.sh` aus.
2. Lies `README.md`, `VORBEREITUNG.md` und `RUNBOOK.md` gegen.
3. Beschreibe im PR:
   Was sich aendert, warum es besser ist und wie man es prueft.

## PR-Richtlinien

- Kleine, fokussierte Aenderungen
- Keine Secrets, keine `.env`-Werte
- Kompatibel zu Ubuntu 24.04 und Debian 12 (wenn moeglich)

## Commit-Stil

Empfohlen:
- `feat(scope): ...`
- `fix(scope): ...`
- `docs(scope): ...`
- `chore(scope): ...`

## Diskussion

Wenn du unsicher bist, erst ein Issue eroefnen und kurz Ziel + Ansatz skizzieren.
