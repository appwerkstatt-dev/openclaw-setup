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
sudo -E bash 02-install-openclaw.sh
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

## Nach Server-Zugang: Reihenfolge

1. `01-bootstrap.sh`  -- OS haerten, Firewall, SSH, Admin-User
2. `02-install-openclaw.sh` -- Node.js, OpenClaw, System-User, Config
3. `03-systemd-setup.sh` -- Service, Env-File, Autostart
4. `04-telegram-setup.sh` -- Telegram konfigurieren und testen
5. `99-checklist.sh` -- Alles pruefen

Jedes Script wird einzeln ausgefuehrt, damit du jeden Schritt kontrollieren kannst.
