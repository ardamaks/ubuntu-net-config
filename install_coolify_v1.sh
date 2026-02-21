#!/usr/bin/env bash
set -euo pipefail

echo "[1/3] Ensure Docker is running"
sudo systemctl enable --now docker

echo "[2/3] Install Coolify"
sudo -E bash -c 'curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash'

echo "[3/3] Done"
echo "Open: https://<server-ip-or-tailscale-ip>:8000"
