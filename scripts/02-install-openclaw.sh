#!/usr/bin/env bash
# =============================================================================
# 02-install-openclaw.sh -- OpenClaw Installation + Hardening
# =============================================================================
# Ausfuehren als awadmin:
#   export OPENCLAW_VERSION=<VERSION>
#   sudo OPENCLAW_VERSION="$OPENCLAW_VERSION" bash 02-install-openclaw.sh
# =============================================================================
set -euo pipefail

echo "=== [02] OpenClaw Installation ==="
echo ""

# --- Root-Check ---
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "FEHLER: Bitte mit sudo ausfuehren."
  exit 1
fi

# --- Variablen ---
OC_USER="openclaw"
OC_HOME="/var/lib/openclaw"
OC_CONFIG_DIR="/etc/openclaw"
OC_ENV_FILE="$OC_CONFIG_DIR/openclaw.env"
OC_PORT=18789
OPENCLAW_VERSION="${OPENCLAW_VERSION:-__SET_OPENCLAW_VERSION__}"

if [ "$OPENCLAW_VERSION" = "__SET_OPENCLAW_VERSION__" ]; then
  echo "FEHLER: Bitte Version explizit setzen, z.B.:"
  echo "  export OPENCLAW_VERSION=0.0.0"
  echo "  sudo -E bash 02-install-openclaw.sh"
  exit 1
fi

# --- 1. Node.js 22 installieren ---
echo "[1/5] Node.js 22 installieren..."
if ! command -v node >/dev/null 2>&1 || [ "$(node -v | cut -d. -f1 | tr -d v)" -lt 22 ]; then
  curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
  apt install -y nodejs
  echo "  -> Node.js $(node -v) installiert"
else
  echo "  -> Node.js $(node -v) bereits vorhanden"
fi

# --- 2. OpenClaw System-User ---
echo "[2/5] System-User '$OC_USER' anlegen..."
if ! id "$OC_USER" >/dev/null 2>&1; then
  useradd --system \
    --create-home \
    --home-dir "$OC_HOME" \
    --shell /usr/sbin/nologin \
    "$OC_USER"
  echo "  -> User '$OC_USER' erstellt (Home: $OC_HOME)"
else
  echo "  -> User '$OC_USER' existiert bereits"
fi

mkdir -p "$OC_HOME"/{state,workspace}
mkdir -p "$OC_CONFIG_DIR"
chown -R "$OC_USER:$OC_USER" "$OC_HOME"
chmod 700 "$OC_HOME"

# --- 3. OpenClaw installieren ---
echo "[3/5] OpenClaw installieren..."
npm install -g "openclaw@$OPENCLAW_VERSION"
echo "  -> OpenClaw $(openclaw --version 2>/dev/null || echo "$OPENCLAW_VERSION") installiert"

# --- 4. Gateway-Token ---
echo "[4/5] Gateway-Token pruefen..."
touch "$OC_ENV_FILE"
chmod 600 "$OC_ENV_FILE"
chown root:root "$OC_ENV_FILE"

CURRENT_TOKEN=$(grep -E '^OPENCLAW_GATEWAY_TOKEN=' "$OC_ENV_FILE" 2>/dev/null | tail -n1 | cut -d= -f2- || true)
if [ -n "$CURRENT_TOKEN" ] && [[ "$CURRENT_TOKEN" != __* ]]; then
  echo "  -> Vorhandenes Gateway-Token wird beibehalten"
else
  # Token generieren und direkt in Datei schreiben, NICHT ausgeben
  GATEWAY_TOKEN=$(openssl rand -hex 32)
  if grep -qE '^OPENCLAW_GATEWAY_TOKEN=' "$OC_ENV_FILE" 2>/dev/null; then
    sed -i "s|^OPENCLAW_GATEWAY_TOKEN=.*|OPENCLAW_GATEWAY_TOKEN=$GATEWAY_TOKEN|" "$OC_ENV_FILE"
  else
    echo "OPENCLAW_GATEWAY_TOKEN=$GATEWAY_TOKEN" >> "$OC_ENV_FILE"
  fi
  unset GATEWAY_TOKEN
  echo "  -> Gateway-Token generiert und in $OC_ENV_FILE gespeichert"
fi

# --- 5. OpenClaw Config ---
echo "[5/5] OpenClaw Konfiguration erstellen..."

cat > "$OC_CONFIG_DIR/openclaw.json" <<EOF
{
  "gateway": {
    "mode": "local",
    "bind": "127.0.0.1",
    "port": $OC_PORT,
    "auth": {
      "mode": "token"
    }
  },
  "discovery": {
    "mdns": {
      "mode": "off"
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "pairing"
    }
  },
  "agents": {
    "defaults": {
      "workspace": "$OC_HOME/workspace"
    }
  }
}
EOF

chmod 600 "$OC_CONFIG_DIR/openclaw.json"
chown "$OC_USER:$OC_USER" "$OC_CONFIG_DIR/openclaw.json"

echo "  -> Config: $OC_CONFIG_DIR/openclaw.json"
echo "  -> Gateway: 127.0.0.1:$OC_PORT (loopback-only)"
echo "  -> Auth: Token-basiert"
echo "  -> Telegram: DM-Pairing aktiviert"
echo "  -> mDNS: deaktiviert"

echo ""
echo "========================================="
echo "  OpenClaw Installation abgeschlossen!"
echo "========================================="
echo ""
echo "OpenClaw-Version: $OPENCLAW_VERSION"
echo "Naechster Schritt: sudo bash 03-systemd-setup.sh"
echo ""
