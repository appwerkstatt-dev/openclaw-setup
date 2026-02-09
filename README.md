# OpenClaw Setup (Strato VC 2-4)

Praxisnahes, gehaertetes Setup fuer OpenClaw auf einem kleinen VPS.

## Vision

Ein reproduzierbarer Einstieg, der nicht bei "laeuft irgendwie" aufhoert, sondern Security, Betrieb und Wartbarkeit von Anfang an mitdenkt.

Dieses Repository soll:
- eine sichere Basis fuer Einzelpersonen und kleine Teams liefern,
- typische Fehlkonfigurationen (offene Ports, schwache SSH-Defaults, unklare Secrets) vermeiden,
- konkrete Verbesserungsvorschlaege aus der Community aufnehmen.

## Fuer wen ist das nuetzlich?

- Du willst OpenClaw schnell auf einem VPS betreiben.
- Du willst dabei nicht auf Security-Hygiene verzichten.
- Du willst ein Setup, das du spaeter nachvollziehen, upgraden und wiederherstellen kannst.

## Was du bekommst

- 5 Setup-Skripte mit klarer Reihenfolge in `scripts/`
- Vorbereitungsschritte in `VORBEREITUNG.md`
- Betriebs-Runbook in `RUNBOOK.md` (Backup, Restore, Updates, Incident)
- Verifikationsskript in `scripts/99-checklist.sh`

## Nicht-Ziele

- Kein offizieller OpenClaw-Installer
- Kein Managed Hosting
- Kein Ersatz fuer eigenes Threat Modeling oder Security-Audit

## Architektur

```text
[Dein Laptop] --SSH-Tunnel--> [VPS] --API--> [Anthropic/OpenAI]
      |                          |
      |                     OpenClaw Gateway
      |                     (127.0.0.1:18789)
      |                          |
[Telegram App] <--Bot-API--> [Telegram Bot]
```

## Sicherheitsprinzipien

- Gateway nur auf Loopback (`127.0.0.1`)
- UI-Zugriff nur via SSH Port-Forwarding
- SSH key-only, Root-Login aus, Fail2ban aktiv
- `awadmin` ohne `NOPASSWD:ALL`
- Secrets in `/etc/openclaw/openclaw.env` mit `600`
- Reproduzierbare Installation per `OPENCLAW_VERSION` Pinning

## Quickstart

1. Vorbereitung lesen: `VORBEREITUNG.md`
2. Skripte in Reihenfolge ausfuehren:
   `01-bootstrap.sh` -> `02-install-openclaw.sh` -> `03-systemd-setup.sh` -> `04-telegram-setup.sh` -> `99-checklist.sh`
3. Betrieb und Notfaelle: `RUNBOOK.md`

## Lokaler Ablauf (Beispiel)

```bash
# 1) Scripts auf Server kopieren
scp scripts/*.sh root@<SERVER-IP>:/root/

# 2) Bootstrap als root
ssh root@<SERVER-IP> -i ~/.ssh/openclaw_strato
bash /root/01-bootstrap.sh

# 3) Installation als awadmin mit Version-Pinning
ssh awadmin@<SERVER-IP> -i ~/.ssh/openclaw_strato
export OPENCLAW_VERSION=<EXAKTE_VERSION>
sudo -E bash /root/02-install-openclaw.sh
sudo bash /root/03-systemd-setup.sh
sudo nano /etc/openclaw/openclaw.env
sudo systemctl enable --now openclaw
sudo bash /root/04-telegram-setup.sh
sudo bash /root/99-checklist.sh
```

## Web-UI Zugriff

```bash
ssh -L 18789:127.0.0.1:18789 awadmin@<SERVER-IP> -i ~/.ssh/openclaw_strato
# Browser: http://127.0.0.1:18789
```

## Mitmachen

Hinweise, Korrekturen und Härtungs-Ideen sind explizit erwuenscht.
Siehe `CONTRIBUTING.md` und `SECURITY.md`.

## Wichtige Hinweise

- Dieses Repository ist nicht offiziell von OpenClaw.
- Nutze es als Ausgangspunkt und passe es an deine Sicherheitsanforderungen an.

## Quellen

- OpenClaw Docs: https://docs.openclaw.ai/
- Security Guide: https://docs.openclaw.ai/gateway/security
- Getting Started: https://docs.openclaw.ai/start/getting-started
