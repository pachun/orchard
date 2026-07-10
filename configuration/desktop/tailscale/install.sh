#!/usr/bin/env bash
# Tailscale mesh VPN. Installs the package and enables the system
# daemon. Joining the tailnet (`tailscale up`) needs an interactive
# browser OAuth and lives in connections/tailscale — not here.
# Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm tailscale
sudo systemctl enable --now tailscaled.service
