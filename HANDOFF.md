# Handoff

## Goal / DoD Status

- Goal: Repo oeffentlichkeitsfaehig aufbereiten (Vision, Weg, Sicherheitsrahmen, Mitmachen), public veroeffentlichen und Community-Feedback erleichtern.
- Status: Erreicht. Zusaetzlich Security-Feinschliff: kein `cp -r /root/.ssh`-Hinweis mehr, kein `sudo -E` im Setup-Flow.

## Files touched

- .github/ISSUE_TEMPLATE/bug_report.yml
- .github/ISSUE_TEMPLATE/config.yml
- .github/ISSUE_TEMPLATE/docs_feedback.yml
- .github/ISSUE_TEMPLATE/hardening_idea.yml
- .github/pull_request_template.md
- .github/workflows/quality-gates.yml
- .gitignore
- .lychee.toml
- .markdownlint.yml
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
- `gh api repos/appwerkstatt-dev/openclaw-setup/branches/main/protection` (PASS)

## Open risks / decisions

- OpenClaw-Version bleibt bewusst verpflichtend via `OPENCLAW_VERSION` (Pinning).
- Security-Meldungen laufen bewusst per privatem Kanal (`mwiedmer@appwerkstatt.dev`) statt oeffentlichem Issue.
- Link-Check bleibt strikt; bekannte 403-URL wird gezielt exkludiert statt globaler 403-Akzeptanz.
- `main` ist nun geschuetzt: Merge nur per PR mit 1 Approval und gruener CI.
