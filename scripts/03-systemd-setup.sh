#!/usr/bin/env bash
# =============================================================================
# 03-systemd-setup.sh -- Systemd Service + Environment File
# =============================================================================
# Ausfuehren als awadmin:
#   sudo bash 03-systemd-setup.sh
# =============================================================================
set -euo pipefail

echo "=== [03] Systemd Service Setup ==="
echo ""

# --- Root-Check ---
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "FEHLER: Bitte mit sudo/root ausfuehren."
  exit 1
fi

OC_USER="openclaw"
OC_HOME="/var/lib/openclaw"
OC_CONFIG_DIR="/etc/openclaw"
OC_ENV_FILE="$OC_CONFIG_DIR/openclaw.env"

ensure_env_key() {
  local key="$1"
  local default_value="$2"

  if grep -qE "^${key}=" "$OC_ENV_FILE"; then
    return 0
  fi
  echo "${key}=${default_value}" >> "$OC_ENV_FILE"
}

# --- 1. Environment File fuer Secrets ---
echo "[1/3] Environment File erstellen..."

mkdir -p "$OC_CONFIG_DIR"

if [ ! -f "$OC_ENV_FILE" ]; then
  cat > "$OC_ENV_FILE" <<'EOF'
# =============================================================================
# OpenClaw Secrets -- HIER DEINE WERTE EINTRAGEN
# =============================================================================

EOF
fi

ensure_env_key "OPENCLAW_HOME" "/var/lib/openclaw"
ensure_env_key "OPENCLAW_STATE_DIR" "/var/lib/openclaw/state"
ensure_env_key "OPENCLAW_CONFIG_PATH" "/etc/openclaw/openclaw.json"
ensure_env_key "OPENCLAW_DISABLE_BONJOUR" "1"
ensure_env_key "TELEGRAM_BOT_TOKEN" "__HIER_BOT_TOKEN_EINTRAGEN__"
ensure_env_key "ANTHROPIC_API_KEY" "__HIER_ANTHROPIC_KEY_EINTRAGEN__"
ensure_env_key "OPENAI_API_KEY" "__OPTIONAL_OPENAI_KEY__"

chmod 600 "$OC_ENV_FILE"
chown root:root "$OC_ENV_FILE"
echo "  -> Env-File bereit: $OC_ENV_FILE"
echo ""
echo "  WICHTIG: Telegram-Token und LLM-Keys eintragen mit:"
echo "    sudo nano $OC_ENV_FILE"
echo "  (Gateway-Token wurde bereits von 02-install-openclaw.sh generiert)"
echo ""

# --- 2. Systemd Service ---
echo "[2/3] Systemd Service erstellen..."

# openclaw binary Pfad ermitteln
OC_BIN=$(which openclaw 2>/dev/null || echo "/usr/bin/openclaw")

cat > /etc/systemd/system/openclaw.service <<EOF
[Unit]
Description=OpenClaw AI Agent Gateway
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$OC_USER
Group=$OC_USER
EnvironmentFile=$OC_CONFIG_DIR/openclaw.env
WorkingDirectory=$OC_HOME
ExecStart=$OC_BIN gateway
Restart=on-failure
RestartSec=5

# Sicherheits-Haertung
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadWritePaths=$OC_HOME

# Resource Limits
MemoryMax=2G
CPUQuota=150%

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=openclaw

[Install]
WantedBy=multi-user.target
EOF

echo "  -> Service-File: /etc/systemd/system/openclaw.service"

# --- 3. Service aktivieren ---
echo "[3/3] Service aktivieren..."
systemctl daemon-reload

echo ""
echo "========================================="
echo "  Systemd Setup abgeschlossen!"
echo "========================================="
echo ""
echo "NAECHSTE SCHRITTE:"
echo ""
echo "1. Telegram-Token und LLM-Keys eintragen:"
echo "   sudo nano $OC_CONFIG_DIR/openclaw.env"
echo ""
echo "2. Service starten:"
echo "   sudo systemctl enable --now openclaw"
echo ""
echo "3. Status pruefen:"
echo "   sudo systemctl status openclaw"
echo "   sudo journalctl -u openclaw -f"
echo ""
echo "4. Weiter mit: 04-telegram-setup.sh"
echo ""
