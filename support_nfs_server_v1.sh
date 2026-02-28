#!/usr/bin/env bash
set -euo pipefail

EXPORT_DIR="${EXPORT_DIR:-/srv/vibesandbox-storage}"
HOME_TS_IP="${HOME_TS_IP:-}"

if [[ -z "$HOME_TS_IP" ]]; then
  echo "HOME_TS_IP is required (example: HOME_TS_IP=100.94.31.28)" >&2
  exit 2
fi

echo "[1/5] packages"
sudo apt-get update
sudo apt-get install -y nfs-kernel-server

echo "[2/5] export dir"
sudo mkdir -p "$EXPORT_DIR"
sudo chown root:root "$EXPORT_DIR"
sudo chmod 755 "$EXPORT_DIR"

echo "[3/5] exports"
EXPORTS_FILE="/etc/exports.d/vibesandbox.exports"
LINE="$EXPORT_DIR $HOME_TS_IP(rw,sync,no_subtree_check,no_root_squash)"
if [[ -f "$EXPORTS_FILE" ]]; then
  grep -Fxq "$LINE" "$EXPORTS_FILE" || echo "$LINE" | sudo tee -a "$EXPORTS_FILE" >/dev/null
else
  echo "$LINE" | sudo tee "$EXPORTS_FILE" >/dev/null
fi

sudo exportfs -ra
sudo systemctl enable --now nfs-server

echo "[4/5] firewall (tailscale)"
if command -v ufw >/dev/null 2>&1 && ip link show tailscale0 >/dev/null 2>&1; then
  sudo ufw allow in on tailscale0 to any port 2049 proto tcp
  sudo ufw allow in on tailscale0 to any port 2049 proto udp || true
fi

echo "[5/5] done"
echo "Exported: $EXPORT_DIR to $HOME_TS_IP"
