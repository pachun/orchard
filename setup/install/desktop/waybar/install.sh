#!/usr/bin/env bash
# Top status bar. Modules defined in config/config.jsonc. Helper
# scripts under bin/ feed each module (bluetooth state, DND state,
# NordVPN connection state, recording indicator, pending updates,
# weather, wifi status). Symbol-only Nerd Font + Phosphor Icons fill
# in the glyphs the modules use. pacman-contrib supplies the
# `checkupdates` binary that waybar-updates calls without locking
# the system pacman DB.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm \
    waybar ttf-nerd-fonts-symbols-mono pacman-contrib

bash "$TOOLS/install-yay.sh"
yay -S --needed --noconfirm ttf-phosphor-icons

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/waybar"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
