#!/usr/bin/env bash
# =============================================================================
# 01-bootstrap.sh -- Strato VC 2-4 Server Hardening
# =============================================================================
# Ausfuehren als root via SSH:
#   ssh root@<SERVER-IP> -i ~/.ssh/openclaw_strato
#   bash 01-bootstrap.sh
# =============================================================================
set -euo pipefail

echo "=== [01] Strato VC 2-4 Bootstrap ==="
echo ""

# --- Root-Check ---
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "FEHLER: Bitte als root ausfuehren."
  exit 1
fi

# --- Variablen (bei Bedarf anpassen) ---
ADMIN_USER="awadmin"
SSH_PORT=22  # Aendern auf z.B. 2222 wenn gewuenscht

# --- 1. System aktualisieren ---
echo "[1/7] System aktualisieren..."
apt update && apt upgrade -y
apt install -y \
  curl wget git vim nano \
  ufw fail2ban \
  htop ncdu \
  unattended-upgrades

# --- 2. Automatische Sicherheitsupdates ---
echo "[2/7] Automatische Sicherheitsupdates aktivieren..."
dpkg-reconfigure -plow unattended-upgrades || true

# --- 3. Admin-User anlegen ---
echo "[3/7] Admin-User '$ADMIN_USER' anlegen..."
if ! id "$ADMIN_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$ADMIN_USER"
  usermod -aG sudo "$ADMIN_USER"

  # Passwort fuer sudo setzen (Sicherheitsgewinn gegen reine Key-Kompromittierung)
  if [ -t 0 ]; then
    echo ""
    echo "Setze jetzt ein sudo-Passwort fuer '$ADMIN_USER':"
    passwd "$ADMIN_USER"
  else
    echo "  WARNUNG: Kein TTY erkannt, Passwort wurde nicht gesetzt."
    echo "  -> Nach Login als root ausfuehren: passwd $ADMIN_USER"
  fi

  # SSH-Key vom root-User uebernehmen
  mkdir -p "/home/$ADMIN_USER/.ssh"
  if [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys "/home/$ADMIN_USER/.ssh/authorized_keys"
  fi
  chown -R "$ADMIN_USER:$ADMIN_USER" "/home/$ADMIN_USER/.ssh"
  chmod 700 "/home/$ADMIN_USER/.ssh"
  chmod 600 "/home/$ADMIN_USER/.ssh/authorized_keys" 2>/dev/null || true

  echo "  -> User '$ADMIN_USER' erstellt, SSH-Keys kopiert."
else
  echo "  -> User '$ADMIN_USER' existiert bereits."
fi

# Erzwinge sudo mit Passwort (kein NOPASSWD:ALL)
echo "$ADMIN_USER ALL=(ALL:ALL) ALL" > "/etc/sudoers.d/$ADMIN_USER"
chmod 440 "/etc/sudoers.d/$ADMIN_USER"

# --- 4. SSH haerten ---
echo "[4/7] SSH haerten..."
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

# Pruefen ob Config gueltig ist bevor wir SSH neu starten
sshd -t && systemctl restart ssh
echo "  -> SSH gehaertet (Port $SSH_PORT, nur Key-Auth, nur $ADMIN_USER)"

# --- 5. Firewall ---
echo "[5/7] Firewall konfigurieren..."
ufw default deny incoming
ufw default allow outgoing
ufw allow "$SSH_PORT/tcp" comment 'SSH'
# Kein Port 18789 oeffnen! Zugriff nur via SSH-Tunnel.
ufw --force enable
echo "  -> UFW aktiv. Nur SSH ($SSH_PORT) offen."

# --- 6. Fail2ban ---
echo "[6/7] Fail2ban konfigurieren..."
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

# --- 7. Timezone ---
echo "[7/7] Timezone setzen..."
timedatectl set-timezone Europe/Berlin
echo "  -> Timezone: Europe/Berlin"

echo ""
echo "========================================="
echo "  Bootstrap abgeschlossen!"
echo "========================================="
echo ""
echo "WICHTIG: Ab jetzt NUR NOCH als '$ADMIN_USER' einloggen:"
echo "  ssh $ADMIN_USER@<SERVER-IP> -p $SSH_PORT -i ~/.ssh/openclaw_strato"
echo ""
echo "Root-Login ist deaktiviert."
echo "Naechster Schritt: 02-install-openclaw.sh (als $ADMIN_USER)"
echo ""
