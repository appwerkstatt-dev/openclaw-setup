# Handoff

## Goal / DoD Status
- Goal: Repo oeffentlichkeitsfaehig aufbereiten (Vision, Weg, Sicherheitsrahmen, Mitmachen), public veroeffentlichen und Community-Feedback erleichtern.
- Status: Erreicht. Repo ist public, Templates und Topics sind aktiv.

## Files touched
- .github/ISSUE_TEMPLATE/bug_report.yml
- .github/ISSUE_TEMPLATE/config.yml
- .github/ISSUE_TEMPLATE/docs_feedback.yml
- .github/ISSUE_TEMPLATE/hardening_idea.yml
- .github/pull_request_template.md
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
- `gh repo view appwerkstatt-dev/openclaw-setup --json name,url,visibility,repositoryTopics` (PASS)

## Open risks / decisions
- OpenClaw-Version bleibt bewusst verpflichtend via `OPENCLAW_VERSION` (Pinning).
- Security-Meldungen laufen bewusst per privatem Kanal (`mwiedmer@appwerkstatt.dev`) statt oeffentlichem Issue.
