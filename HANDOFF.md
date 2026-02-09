# Handoff

## Goal / DoD Status
- Goal: Repo oeffentlichkeitsfaehig aufbereiten (Vision, Weg, Sicherheitsrahmen, Mitmachen) und als Public Repo veroeffentlichen.
- Status: Inhaltlich erledigt; Veroeffentlichung blockiert durch ungueltiges `gh` Login.

## Files touched
- .gitignore
- CONTRIBUTING.md
- HANDOFF.md
- LICENSE
- README.md
- ROADMAP.md
- RUNBOOK.md
- SECURITY.md
- VORBEREITUNG.md
- scripts/01-bootstrap.sh
- scripts/02-install-openclaw.sh
- scripts/03-systemd-setup.sh
- scripts/04-telegram-setup.sh
- scripts/99-checklist.sh

## Tests run
- `bash -n scripts/*.sh` (PASS)

## Open risks / decisions
- OpenClaw-Version bleibt bewusst verpflichtend via `OPENCLAW_VERSION` (Pinning).
- Fuer GitHub-Push ist einmal `gh auth login -h github.com` noetig (aktueller Token ungueltig).
