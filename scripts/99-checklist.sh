#!/usr/bin/env bash
# =============================================================================
# 99-checklist.sh -- Deployment Verification
# =============================================================================
# Ausfuehren als awadmin:
#   sudo bash 99-checklist.sh
# =============================================================================
set -euo pipefail

echo "=== OpenClaw Deployment Checklist ==="
echo ""

PASSED=0
FAILED=0
WARNINGS=0

check() {
  local name="$1"
  local cmd="$2"
  printf "  %-50s " "$name"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "[OK]"
    ((PASSED++))
  else
    echo "[FAIL]"
    ((FAILED++))
  fi
}

warn() {
  local name="$1"
  local cmd="$2"
  printf "  %-50s " "$name"
  if eval "$cmd" >/dev/null 2>&1; then
    echo "[OK]"
    ((PASSED++))
  else
    echo "[WARN]"
    ((WARNINGS++))
  fi
}

echo "--- System ---"
check "SSH: Root-Login deaktiviert" "grep -q 'PermitRootLogin no' /etc/ssh/sshd_config.d/99-openclaw-hardening.conf"
check "SSH: Passwort-Auth deaktiviert" "grep -q 'PasswordAuthentication no' /etc/ssh/sshd_config.d/99-openclaw-hardening.conf"
check "Sudo: kein NOPASSWD:ALL fuer awadmin" "! grep -q 'awadmin .*NOPASSWD:ALL' /etc/sudoers.d/awadmin"
check "UFW: Firewall aktiv" "ufw status | grep -q 'Status: active'"
check "UFW: Port 18789 NICHT offen" "! ufw status | grep -q '18789'"
check "Fail2ban: aktiv" "systemctl is-active fail2ban"
check "Timezone: Europe/Berlin" "timedatectl | grep -q 'Europe/Berlin'"
check "Node.js: Version 22+" "node -v | grep -qE '^v2[2-9]|^v[3-9]'"

echo ""
echo "--- OpenClaw ---"
check "OpenClaw: installiert" "command -v openclaw"
check "User 'openclaw': existiert" "id openclaw"
check "Home: /var/lib/openclaw existiert" "test -d /var/lib/openclaw"
check "Config: existiert" "test -f /etc/openclaw/openclaw.json"
check "Config: loopback-only" "grep -q '127.0.0.1' /etc/openclaw/openclaw.json"
check "Config: Token-Auth" "grep -q 'token' /etc/openclaw/openclaw.json"
check "Config: mDNS off" "grep -q 'off' /etc/openclaw/openclaw.json"

echo ""
echo "--- Secrets ---"
check "Env-File: existiert" "test -f /etc/openclaw/openclaw.env"
check "Env-File: korrekte Rechte (600)" "test \$(stat -c %a /etc/openclaw/openclaw.env) = '600'"
warn  "Gateway-Token: gesetzt" "grep -q 'OPENCLAW_GATEWAY_TOKEN=' /etc/openclaw/openclaw.env && ! grep -q '__HIER' /etc/openclaw/openclaw.env"
warn  "Telegram-Token: gesetzt" "grep -q 'TELEGRAM_BOT_TOKEN=' /etc/openclaw/openclaw.env && ! grep -q '__HIER' /etc/openclaw/openclaw.env"
warn  "LLM-Key: gesetzt" "grep -qE '^ANTHROPIC_API_KEY=[^[:space:]#]{20,}$|^OPENAI_API_KEY=[^[:space:]#]{20,}$' /etc/openclaw/openclaw.env && ! grep -q '__HIER' /etc/openclaw/openclaw.env"

echo ""
echo "--- Service ---"
check "Systemd: Unit vorhanden" "test -f /etc/systemd/system/openclaw.service"
check "Systemd: Service enabled" "systemctl is-enabled openclaw"
warn  "Systemd: Service laeuft" "systemctl is-active openclaw"

echo ""
echo "--- Netzwerk ---"
check "Port 18789: nur localhost" "! ss -tlnp | grep '18789' | grep -v '127.0.0.1' | grep -q '18789' || ss -tlnp | grep '18789' | grep -q '127.0.0.1'"
check "Kein offener Port 18789 auf 0.0.0.0" "! ss -tlnp | grep '0.0.0.0:18789'"

echo ""
echo "========================================="
echo "  Ergebnis: $PASSED OK, $FAILED FAIL, $WARNINGS WARN"
echo "========================================="

if [ $FAILED -gt 0 ]; then
  echo ""
  echo "  $FAILED Check(s) fehlgeschlagen -- bitte pruefen!"
  exit 1
elif [ $WARNINGS -gt 0 ]; then
  echo ""
  echo "  $WARNINGS Warning(s) -- Secrets/Service noch konfigurieren."
  exit 0
else
  echo ""
  echo "  Alles OK. OpenClaw ist einsatzbereit."
  exit 0
fi
