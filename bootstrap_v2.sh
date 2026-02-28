#!/usr/bin/env bash
set -euo pipefail

USERNAME="${SUDO_USER:-$USER}"
PROJECT_ROOT="${PROJECT_ROOT:-/opt/vibesandbox}"
DOCKER_NETWORK="${DOCKER_NETWORK:-vibe-net}"
TIMEZONE="${TIMEZONE:-Europe/Amsterdam}"

UFW_ENABLE="${UFW_ENABLE:-1}"
UFW_ALLOW_PUBLIC_HTTP="${UFW_ALLOW_PUBLIC_HTTP:-0}"
UFW_ALLOW_COOLIFY="${UFW_ALLOW_COOLIFY:-0}"
UFW_ALLOW_TAILSCALE_ALL="${UFW_ALLOW_TAILSCALE_ALL:-1}"

sudo -n true 2>/dev/null || true

echo "[1/8] apt update/upgrade"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "[2/8] base packages"
sudo apt-get install -y \
  curl wget git ca-certificates gnupg lsb-release jq unzip make \
  ufw fail2ban htop tmux software-properties-common

echo "[3/8] timezone"
sudo timedatectl set-timezone "$TIMEZONE"

echo "[4/8] docker (official repo)"
if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  UBUNTU_CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  ARCH="$(dpkg --print-architecture)"

  echo "deb [arch=$ARCH signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
sudo usermod -aG docker "$USERNAME" || true
sudo systemctl enable --now docker

echo "[5/8] tailscale"
if ! command -v tailscale >/dev/null 2>&1; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi
sudo systemctl enable --now tailscaled

echo "[6/8] project dirs"
sudo mkdir -p "$PROJECT_ROOT"/{apps,data,compose,scripts,backups,secrets}
sudo chown -R "$USERNAME:$USERNAME" "$PROJECT_ROOT"

echo "[7/8] docker network"
if ! docker network ls --format '{{.Name}}' | grep -qx "$DOCKER_NETWORK"; then
  docker network create "$DOCKER_NETWORK"
fi

echo "[8/8] ufw (optional)"
if [[ "$UFW_ENABLE" == "1" ]]; then
  sudo ufw allow OpenSSH

  if [[ "$UFW_ALLOW_PUBLIC_HTTP" == "1" ]]; then
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
  fi

  if [[ "$UFW_ALLOW_COOLIFY" == "1" ]]; then
    sudo ufw allow 8000/tcp
  fi

  if [[ "$UFW_ALLOW_TAILSCALE_ALL" == "1" ]] && ip link show tailscale0 >/dev/null 2>&1; then
    sudo ufw allow in on tailscale0
  fi

  sudo ufw --force enable
fi

echo "DONE"
echo "Next: sudo tailscale up --hostname <name>"
echo "Then re-login (or run: newgrp docker) to use docker without sudo"
