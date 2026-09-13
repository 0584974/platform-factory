#!/usr/bin/env bash
set -euo pipefail

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y open-vm-tools python3 cloud-init
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf install -y open-vm-tools python3 cloud-init
elif command -v zypper >/dev/null 2>&1; then
  sudo zypper --non-interactive install open-vm-tools python3 cloud-init
else
  echo "Unsupported package manager; install open-vm-tools manually" >&2
  exit 1
fi

sudo systemctl enable vmtoolsd 2>/dev/null || true
sudo systemctl enable cloud-init 2>/dev/null || true
