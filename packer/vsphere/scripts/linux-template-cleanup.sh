#!/usr/bin/env bash
set -euo pipefail

sudo rm -f /etc/ssh/ssh_host_*
sudo rm -f /etc/machine-id
sudo touch /etc/machine-id
sudo rm -rf /var/lib/cloud/instances /var/lib/cloud/instance
sudo cloud-init clean --logs --seed 2>/dev/null || true

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get clean
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf clean all
elif command -v zypper >/dev/null 2>&1; then
  sudo zypper clean --all
fi

sudo find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true
sync
