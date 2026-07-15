#!/usr/bin/env bash
# Ranks the official Arch mirror list by speed with reflector, so pacman
# (and the official-repo dependencies yay pulls) download from fast, up-
# to-date servers instead of whatever shipped in the default mirrorlist.
# It only touches the official package mirrors — not AUR source builds or
# the wider internet. Runs once now and weekly via reflector.timer.
#
# x86 Arch only; the Apple-silicon Mac is on Arch Linux ARM, a separate
# mirror system reflector doesn't cover.
set -euo pipefail

. "$TOOLS/machine.sh"

is_apple_silicon && exit 0

sudo pacman -S --needed --noconfirm reflector

sudo mkdir -p /etc/xdg/reflector
sudo tee /etc/xdg/reflector/reflector.conf >/dev/null <<'EOF'
--save /etc/pacman.d/mirrorlist
--protocol https
--latest 20
--sort rate
EOF

sudo reflector @/etc/xdg/reflector/reflector.conf
sudo systemctl enable --now reflector.timer
