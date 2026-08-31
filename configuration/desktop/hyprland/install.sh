#!/usr/bin/env bash
# Hyprland compositor + its Wayland portal backend. Other hypr*
# packages (hyprutils, hyprlang, hyprcursor, hyprgraphics, hyprtoolkit,
# hyprwayland-scanner, hyprwire, hyprland-guiutils) and aquamarine
# (its render backend) are pulled transitively from extra.
# xdg-desktop-portal-hyprland is the Screencast/Screenshot portal
# implementation — browser tab sharing, Discord screen share, etc.
# Config is dropped at ~/.config/hypr/ via the per-file linker.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm hyprland xdg-desktop-portal-hyprland

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/hypr"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

# zprofile auto-execs start-hyprland on tty1. Symlinked directly to
# $HOME since it lives outside ~/.config.
ln -sfn "$HERE/zprofile" "$HOME/.zprofile"
