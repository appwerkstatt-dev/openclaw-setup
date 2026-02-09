#!/usr/bin/env bash
# =============================================================================
# 01-bootstrap.sh -- Strato VC 2-4 Server Hardening
# =============================================================================
# VORAUSSETZUNG: User 'awadmin' existiert bereits mit sudo-Rechten und
#                SSH-Key. Siehe VORBEREITUNG.md Abschnitt "Manuelle Schritte".
#
# Ausfuehren als awadmin:
#   sudo bash 01-bootstrap.sh
# =============================================================================
set -euo pipefail

echo "=== [01] Strato VC 2-4 Bootstrap ==="
echo ""

# --- Root-Check ---
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "FEHLER: Bitte mit sudo ausfuehren."
  exit 1
fi

# --- Variablen (bei Bedarf anpassen) ---
ADMIN_USER="awadmin"
SSH_PORT=22

# --- Preflight: User muss existieren ---
if ! id "$ADMIN_USER" >/dev/null 2>&1; then
  echo "FEHLER: User '$ADMIN_USER' existiert nicht."
  echo "Bitte zuerst manuell anlegen (siehe VORBEREITUNG.md)."
  exit 1
fi

if ! groups "$ADMIN_USER" | grep -q sudo; then
  echo "FEHLER: User '$ADMIN_USER' ist nicht in der sudo-Gruppe."
  echo "  -> Als root: usermod -aG sudo $ADMIN_USER"
  exit 1
fi

if [ ! -f "/home/$ADMIN_USER/.ssh/authorized_keys" ]; then
  echo "FEHLER: Kein SSH-Key fuer '$ADMIN_USER' gefunden."
  echo "  -> Als root: cp -r /root/.ssh /home/$ADMIN_USER/ && chown -R $ADMIN_USER:$ADMIN_USER /home/$ADMIN_USER/.ssh"
  exit 1
fi

echo "  -> Preflight OK: User '$ADMIN_USER' existiert, sudo + SSH-Key vorhanden."
echo ""

# --- 1. System aktualisieren ---
echo "[1/6] System aktualisieren..."
apt update && apt upgrade -y
apt install -y \
  curl wget git vim nano \
  ufw fail2ban \
  htop ncdu \
  unattended-upgrades

# --- 2. Automatische Sicherheitsupdates ---
echo "[2/6] Automatische Sicherheitsupdates aktivieren..."
dpkg-reconfigure -plow unattended-upgrades || true

# --- 3. SSH haerten ---
echo "[3/6] SSH haerten..."
cat > /etc/ssh/sshd_config.d/99-openclaw-hardening.conf <<EOF
# OpenClaw Server Hardening
Port $SSH_PORT
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
AllowUsers $ADMIN_USER
MaxAuthTries 3
LoginGraceTime 30
EOF

sshd -t && systemctl restart ssh
echo "  -> SSH gehaertet (Port $SSH_PORT, nur Key-Auth, nur $ADMIN_USER)"

# --- 4. Firewall ---
echo "[4/6] Firewall konfigurieren..."
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT/tcp" comment 'SSH'
ufw --force enable
echo "  -> UFW aktiv. Nur SSH ($SSH_PORT) offen."

# --- 5. Fail2ban ---
echo "[5/6] Fail2ban konfigurieren..."
cat > /etc/fail2ban/jail.local <<EOF
[sshd]
enabled = true
port = $SSH_PORT
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
EOF

systemctl enable fail2ban
systemctl restart fail2ban
echo "  -> Fail2ban aktiv (3 Versuche, 1h Ban)"

# --- 6. Timezone ---
echo "[6/6] Timezone setzen..."
timedatectl set-timezone Europe/Berlin
echo "  -> Timezone: Europe/Berlin"

echo ""
echo "========================================="
echo "  Bootstrap abgeschlossen!"
echo "========================================="
echo ""
echo "Root-Login ist jetzt deaktiviert."
echo "Naechster Schritt: sudo bash 02-install-openclaw.sh"
echo ""
