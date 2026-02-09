#!/usr/bin/env bash
# =============================================================================
# 04-telegram-setup.sh -- Telegram Bot Integration + Test
# =============================================================================
# Ausfuehren als awadmin:
#   sudo bash 04-telegram-setup.sh
# =============================================================================
set -euo pipefail

echo "=== [04] Telegram Integration ==="
echo ""

OC_USER="openclaw"
OC_CONFIG_DIR="/etc/openclaw"
OC_ENV_FILE="$OC_CONFIG_DIR/openclaw.env"

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "FEHLER: Bitte mit sudo/root ausfuehren."
  exit 1
fi

read_env_value() {
  local key="$1"
  local file="$2"
  local line
  local value

  line="$(grep -E "^${key}=" "$file" | tail -n1 || true)"
  if [ -z "$line" ]; then
    return 1
  fi

  value="${line#*=}"
  value="${value#\"}"
  value="${value%\"}"
  value="${value#\'}"
  value="${value%\'}"
  echo "$value"
}

# --- Env laden ---
if [ -f "$OC_ENV_FILE" ]; then
  TELEGRAM_BOT_TOKEN="$(read_env_value "TELEGRAM_BOT_TOKEN" "$OC_ENV_FILE" || true)"
  OPENCLAW_GATEWAY_TOKEN="$(read_env_value "OPENCLAW_GATEWAY_TOKEN" "$OC_ENV_FILE" || true)"
fi

# --- 1. Telegram Bot Token pruefen ---
echo "[1/4] Telegram Bot Token pruefen..."
if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [[ "$TELEGRAM_BOT_TOKEN" == *"__HIER"* ]]; then
  echo "  FEHLER: TELEGRAM_BOT_TOKEN nicht gesetzt!"
  echo "  -> sudo nano $OC_CONFIG_DIR/openclaw.env"
  exit 1
fi

# API-Test
BOT_INFO=$(curl -sf "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe" 2>/dev/null || echo "FAIL")
if echo "$BOT_INFO" | grep -q '"ok":true'; then
  BOT_NAME=$(echo "$BOT_INFO" | grep -o '"first_name":"[^"]*"' | cut -d'"' -f4)
  BOT_USERNAME=$(echo "$BOT_INFO" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
  echo "  -> Bot OK: $BOT_NAME (@$BOT_USERNAME)"
else
  echo "  FEHLER: Bot-Token ungueltig!"
  echo "  Response: $BOT_INFO"
  exit 1
fi

# --- 2. OpenClaw Service Status ---
echo "[2/4] OpenClaw Service pruefen..."
if systemctl is-active --quiet openclaw; then
  echo "  -> OpenClaw laeuft"
else
  echo "  OpenClaw startet..."
  systemctl start openclaw
  sleep 3
  if systemctl is-active --quiet openclaw; then
    echo "  -> OpenClaw gestartet"
  else
    echo "  FEHLER: OpenClaw startet nicht!"
    journalctl -u openclaw --no-pager -n 20
    exit 1
  fi
fi

# --- 3. Telegram Pairing ---
echo "[3/4] Telegram Pairing..."
echo ""
echo "  Oeffne jetzt Telegram und sende /start an @$BOT_USERNAME"
echo "  Der Bot sollte dir einen Pairing-Code senden."
echo ""
read -rp "  Pairing-Code eingeben (oder Enter zum Ueberspringen): " PAIRING_CODE

if [ -n "$PAIRING_CODE" ]; then
  echo "  Pairing bestaetigen..."
  sudo -u "$OC_USER" env \
    OPENCLAW_HOME=/var/lib/openclaw \
    OPENCLAW_CONFIG_PATH=/etc/openclaw/openclaw.json \
    OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-}" \
    openclaw pairing approve telegram "$PAIRING_CODE" 2>&1 || \
    echo "  (Falls Fehler: manuell mit 'openclaw pairing approve telegram $PAIRING_CODE' versuchen)"
  echo ""
fi

# --- 4. Test-Nachricht ---
echo "[4/4] Test..."
echo ""
echo "  Sende eine Testnachricht an @$BOT_USERNAME in Telegram."
echo "  Z.B.: 'Hallo, bist du da?'"
echo ""
echo "  Logs beobachten mit:"
echo "    sudo journalctl -u openclaw -f"
echo ""

echo "========================================="
echo "  Telegram Setup abgeschlossen!"
echo "========================================="
echo ""
echo "ZUGRIFF AUF WEB-UI (von deinem lokalen Rechner):"
echo ""
echo "  ssh -L 18789:127.0.0.1:18789 awadmin@<SERVER-IP> -i ~/.ssh/openclaw_strato"
echo "  -> Browser: http://127.0.0.1:18789"
echo "  -> Token: (aus openclaw.env)"
echo ""
echo "Naechster Schritt: 99-checklist.sh"
echo ""
