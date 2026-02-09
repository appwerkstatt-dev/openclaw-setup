# OpenClaw auf Strato VC 2-4 -- Vorbereitung

## Was du JETZT schon erledigen kannst (vor Server-Zugang)

### 1. SSH-Keypair erstellen (falls noch keins vorhanden)

```bash
ssh-keygen -t ed25519 -C "openclaw-strato" -f ~/.ssh/openclaw_strato
```

Den Public Key (`~/.ssh/openclaw_strato.pub`) brauchst du beim Strato-Server-Setup.

### 2. Telegram Bot erstellen

1. Telegram oeffnen, @BotFather suchen
2. `/newbot` senden
3. Name eingeben: z.B. "MeinOpenClaw"
4. Username eingeben: z.B. "mein_openclaw_bot" (muss auf `_bot` enden)
5. **Bot-Token kopieren** (Format: `123456789:ABCdefGhIjKlMnOpQrStUvWxYz`)

### 3. Deine Telegram Chat-ID ermitteln

1. Telegram: @userinfobot suchen und starten
2. `/start` senden
3. Die angezeigte ID notieren (z.B. `123456789`)

### 4. LLM API-Key erstellen

**Anthropic (Claude):**

- <https://console.anthropic.com/> -> API Keys -> Create Key
- Spending Limit setzen (z.B. 10 USD/Monat fuer Tests)
- Key beginnt mit `sk-ant-api03-...`

**OpenAI (optional):**

- <https://platform.openai.com/api-keys> -> Create new secret key
- Usage Limit setzen
- Key beginnt mit `sk-...`

### 5. Credentials sicher ablegen

```bash
mkdir -p ~/Dokumente/CREDENTIALS/openclaw-strato
chmod 700 ~/Dokumente/CREDENTIALS/openclaw-strato
```

Erstelle dort eine Datei `secrets.env` (wird NICHT auf den Server kopiert,
nur als lokale Referenz):

```bash
# ~/Dokumente/CREDENTIALS/openclaw-strato/secrets.env
TELEGRAM_BOT_TOKEN=<dein-bot-token>
TELEGRAM_CHAT_ID=<deine-chat-id>
ANTHROPIC_API_KEY=<dein-key>
OPENAI_API_KEY=<dein-key-optional>
```

```bash
chmod 600 ~/Dokumente/CREDENTIALS/openclaw-strato/secrets.env
```

### 6. OpenClaw Zielversion festlegen (Pinning)

Lege vorab fest, welche OpenClaw-Version installiert werden soll
(fuer reproduzierbare Deployments). Beim Installationsschritt auf dem Server:

```bash
export OPENCLAW_VERSION=<EXAKTE_VERSION>
sudo OPENCLAW_VERSION="$OPENCLAW_VERSION" bash 02-install-openclaw.sh
```

---

## Strato VC 2-4 -- Was du beim Bestellen/Einrichten beachtest

- **OS:** Ubuntu 24.04 LTS (oder Debian 12)
- **SSH-Key:** Deinen Public Key hinterlegen (`~/.ssh/openclaw_strato.pub`)
- **Hostname:** z.B. `openclaw-01`
- **Root-Passwort:** Stark, aber du wirst es nach SSH-Key-Setup nicht mehr brauchen
- **IP-Adresse:** Notieren sobald vergeben

### Strato VC 2-4 Specs (zur Referenz)

- 2 vCPU Kerne
- 4 GB RAM
- 80 GB SSD
- 1 IPv4 + IPv6

Das reicht fuer OpenClaw locker aus (Node.js + Gateway + Telegram-Bot).

---

## Manuelle Schritte auf dem Server (VNC-Konsole, BEVOR Scripts laufen)

**WICHTIG:** Diese Schritte muessen MANUELL ueber die Strato VNC-Konsole
oder ein lokales Terminal (als root) ausgefuehrt werden. Kein Script, kein
LLM, keine Fernsteuerung -- du gibst die Passwoerter selbst ein.

### Schritt 1: Admin-User anlegen

```bash
# Als root auf dem Server (VNC-Konsole):
adduser awadmin
# -> Passwort eingeben (interaktiv, wird NICHT angezeigt)

usermod -aG sudo awadmin
```

### Schritt 2: SSH-Key fuer awadmin einrichten

```bash
# Als root auf dem Server:
mkdir -p /home/awadmin/.ssh
chmod 700 /home/awadmin/.ssh

# Public Key eintragen (aus ~/.ssh/openclaw_strato.pub auf deinem Rechner):
nano /home/awadmin/.ssh/authorized_keys
# -> Inhalt von openclaw_strato.pub einfuegen, speichern

chmod 600 /home/awadmin/.ssh/authorized_keys
chown -R awadmin:awadmin /home/awadmin/.ssh
```

### Schritt 3: SSH-Verbindung testen (von deinem Rechner)

```bash
ssh awadmin@<SERVER-IP> -i ~/.ssh/openclaw_strato
# Sollte ohne Passwort-Abfrage verbinden
```

### Schritt 4: Scripts ausfuehren

Erst jetzt koennen die automatisierten Scripts laufen:

```bash
# Als awadmin auf dem Server:
sudo bash 01-bootstrap.sh
```

---

## Nach Server-Zugang: Reihenfolge

<!-- markdownlint-disable MD029 -->

1. **Manuell (VNC):** User `awadmin` anlegen, Passwort setzen, SSH-Key
2. `01-bootstrap.sh`  -- OS haerten, Firewall, SSH (Root-Login sperren)
3. `02-install-openclaw.sh` -- Node.js, OpenClaw, System-User, Config, Gateway-Token
4. `03-systemd-setup.sh` -- Service, Env-File Template, Autostart
5. **Manuell (SSH):** Secrets eintragen: `sudo nano /etc/openclaw/openclaw.env`
6. `04-telegram-setup.sh` -- Telegram konfigurieren und testen
7. `99-checklist.sh` -- Alles pruefen

<!-- markdownlint-enable MD029 -->

Jedes Script wird einzeln ausgefuehrt, damit du jeden Schritt kontrollieren kannst.

---

## Secrets eintragen (nach Script 03, per SSH)

Nach `03-systemd-setup.sh` existiert die Datei `/etc/openclaw/openclaw.env`
mit Platzhaltern. Das Gateway-Token ist bereits automatisch generiert (von
Script 02). Die restlichen Secrets musst du manuell eintragen:

```bash
sudo nano /etc/openclaw/openclaw.env
```

Folgende Werte eintragen (aus deiner lokalen `secrets.env`):

- `TELEGRAM_BOT_TOKEN` -- Bot-Token vom BotFather
- `ANTHROPIC_API_KEY` -- Dein Anthropic API Key
- `OPENAI_API_KEY` -- Optional, dein OpenAI API Key

**Danach:** Service starten und Telegram-Setup ausfuehren.
