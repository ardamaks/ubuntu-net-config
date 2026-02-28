#!/usr/bin/env bash
set -euo pipefail

SUPPORT_TS_IP="${SUPPORT_TS_IP:-}"
EXPORT_DIR="${EXPORT_DIR:-/srv/vibesandbox-storage}"
MOUNTPOINT="${MOUNTPOINT:-/opt/vibesandbox/data/support}"

if [[ -z "$SUPPORT_TS_IP" ]]; then
  echo "SUPPORT_TS_IP is required (example: SUPPORT_TS_IP=100.99.166.80)" >&2
  exit 2
fi

echo "[1/5] packages"
sudo apt-get update
sudo apt-get install -y nfs-common

echo "[2/5] mountpoint"
sudo mkdir -p "$MOUNTPOINT"

echo "[3/5] fstab"
FSTAB_LINE="$SUPPORT_TS_IP:$EXPORT_DIR $MOUNTPOINT nfs4 defaults,_netdev,noatime 0 0"
if ! grep -Fqx "$FSTAB_LINE" /etc/fstab; then
  echo "$FSTAB_LINE" | sudo tee -a /etc/fstab >/dev/null
fi

echo "[4/5] mount"
sudo mount "$MOUNTPOINT" || sudo mount -a

echo "[5/5] done"
mount | grep -F "$MOUNTPOINT" || true
