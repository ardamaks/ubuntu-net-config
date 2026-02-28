# ubuntu-net-config

Public bootstrap + autoinstall configs for Vibe-Sandbox.

This repo is intentionally **public** so Ubuntu Autoinstall can fetch config during install.

## What this repo is

- Autoinstall profiles (NoCloud) for:
  - Home control-plane node
  - Support node (extra storage + agent runner)
- Post-install scripts to standardize the server into the Vibe-Sandbox layout:
  - Docker + Compose
  - Tailscale
  - UFW baseline
  - Standard directories under `/opt/vibesandbox`

## Important security rules

- Do not commit any secrets (Tailscale auth keys, API keys, passwords beyond the autoinstall hash).
- Prefer bringing Tailscale up interactively (`tailscale up`) or with ephemeral auth keys.

## Autoinstall (NoCloud)

Use netboot.xyz: `Linux Network Installs -> Ubuntu -> Specify Autoinstall URL`.

- Home profile:
  - `https://raw.githubusercontent.com/ardamaks/ubuntu-net-config/main/autoinstall/home/`
- Support profile:
  - `https://raw.githubusercontent.com/ardamaks/ubuntu-net-config/main/autoinstall/support/`

## Post-install (recommended)

### 1) Standard bootstrap (all nodes)

```bash
curl -fSL https://raw.githubusercontent.com/ardamaks/ubuntu-net-config/main/bootstrap_v2.sh -o bootstrap_v2.sh
chmod +x bootstrap_v2.sh
bash -x bootstrap_v2.sh
```

Then:

```bash
sudo tailscale up --hostname <choose-name>
```

### 2) Support server: export storage to Home (NFS over Tailscale)

On the support server:

```bash
curl -fSL https://raw.githubusercontent.com/ardamaks/ubuntu-net-config/main/support_nfs_server_v1.sh -o support_nfs_server_v1.sh
chmod +x support_nfs_server_v1.sh
HOME_TS_IP=100.94.31.28 bash -x support_nfs_server_v1.sh
```

### 3) Home: mount support storage

On Home:

```bash
curl -fSL https://raw.githubusercontent.com/ardamaks/ubuntu-net-config/main/home_mount_support_nfs_v1.sh -o home_mount_support_nfs_v1.sh
chmod +x home_mount_support_nfs_v1.sh
SUPPORT_TS_IP=<support-tailscale-ip> bash -x home_mount_support_nfs_v1.sh
```
