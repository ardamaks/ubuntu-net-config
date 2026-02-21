#!/usr/bin/env bash
set -euo pipefail

# ===== Settings =====
USERNAME="${SUDO_USER:-$USER}"
PROJECT_ROOT="/opt/vibesandbox"
DOCKER_NETWORK="vibe-net"
TIMEZONE="Europe/Amsterdam"

echo "[1/9] apt update/upgrade"
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y

echo "[2/9] Base packages"
sudo apt install -y \
  curl wget git ca-certificates gnupg lsb-release \
  jq unzip make ufw fail2ban htop tmux \
  software-properties-common apt-transport-https

echo "[3/9] Timezone"
sudo timedatectl set-timezone "$TIMEZONE"

echo "[4/9] Docker install (official repo)"
if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt update
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

echo "[5/9] Docker permissions"
sudo usermod -aG docker "$USERNAME"

echo "[6/9] Tailscale install"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
sudo systemctl enable --now tailscaled

echo "[7/9] UFW firewall"
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 8000/tcp   # Coolify UI (optional)
sudo ufw --force enable

echo "[8/9] Project dirs"
sudo mkdir -p "$PROJECT_ROOT"/{apps,data,compose,scripts,backups}
sudo chown -R "$USERNAME":"$USERNAME" "$PROJECT_ROOT"

echo "[9/9] Docker network"
if ! docker network ls --format '{{.Name}}' | grep -qx "$DOCKER_NETWORK"; then
  docker network create "$DOCKER_NETWORK"
fi

echo "DONE."
echo "Next:"
echo "  1) sudo tailscale up"
echo "  2) relogin (or run: newgrp docker)"
echo "  3) docker ps"
