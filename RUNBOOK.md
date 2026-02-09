# OpenClaw Runbook (Operations)

## Backup

```bash
sudo mkdir -p /var/backups/openclaw
TS=$(date +%Y%m%d-%H%M%S)
sudo tar -C / -czf /var/backups/openclaw/openclaw-$TS.tar.gz \
  etc/openclaw var/lib/openclaw/state
sudo ls -lh /var/backups/openclaw/openclaw-$TS.tar.gz
```

## Restore

```bash
sudo systemctl stop openclaw
sudo tar -C / -xzf /var/backups/openclaw/openclaw-<TIMESTAMP>.tar.gz
sudo chown -R openclaw:openclaw /var/lib/openclaw
sudo chmod 600 /etc/openclaw/openclaw.env
sudo systemctl start openclaw
sudo systemctl status openclaw --no-pager
```

## Update (Pinned)

```bash
export OPENCLAW_VERSION=<EXAKTE_VERSION>
sudo npm install -g "openclaw@$OPENCLAW_VERSION"
sudo systemctl restart openclaw
sudo journalctl -u openclaw -n 50 --no-pager
```

## Token Rotation (Gateway)

```bash
NEW_TOKEN=$(openssl rand -hex 32)
sudo sed -i "s|^OPENCLAW_GATEWAY_TOKEN=.*|OPENCLAW_GATEWAY_TOKEN=$NEW_TOKEN|" /etc/openclaw/openclaw.env
sudo systemctl restart openclaw
```

## Incident: Service down

```bash
sudo systemctl status openclaw --no-pager
sudo journalctl -u openclaw -n 100 --no-pager
sudo bash scripts/99-checklist.sh
```

## Telegram Re-Pairing

```bash
sudo systemctl restart openclaw
sudo bash scripts/04-telegram-setup.sh
```

## CI Ownership (GitHub Actions)

- Owner: Repository-Maintainer (`mwiedmer@appwerkstatt.dev`)
- Policy: `main` nur per Pull Request, nur mit gruener CI
- Required checks:
  - `Shellcheck`
  - `Markdown Lint`
  - `Link Check`

## CI Failure Triage

1. Fehlerhaften Job im PR oeffnen (`Actions` Tab).
2. Ursache zuordnen:
   - `Shellcheck`: Shell-Fehler/Unsicherheiten in `scripts/*.sh`
   - `Markdown Lint`: Formatprobleme in `*.md`
   - `Link Check`: Defekte/instabile Links in Doku
3. Fix committen und in denselben PR pushen.
4. Merge erst nach erneut gruener CI.

## Wenn Link-Check flaked

Externe Seiten koennen zeitweise ausfallen/rate-limiten.
Wenn ein Link stabil korrekt ist, aber CI sporadisch rot:

1. PR einmal neu ausfuehren (`Re-run failed jobs`).
2. Bei wiederholtem Flake:
   - Link pruefen und ggf. ersetzen
   - oder gezielt in `.lychee.toml` exkludieren (mit Begruendung im PR)
