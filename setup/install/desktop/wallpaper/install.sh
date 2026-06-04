#!/usr/bin/env bash
# Wallpaper daemon. Invoked from hyprland.conf with `-i <image> -m
# fill`; no config file. swaybg over hyprpaper because hyprpaper 0.8.x
# crashes on Asahi (empty EDID/monitor description → null std::string
# deref in the hyprtoolkit rewrite). swaybg is the Hyprland wiki's
# recommended simple alternative and just calls into wlr-layer-shell,
# no monitor introspection. Idempotent.
#
# Wallpaper images live alongside this script and are symlinked into
# ~/.local/share/wallpapers/ so hyprland.conf can reference them via
# a stable path.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm swaybg

bash "$TOOLS/link.sh" "$HERE/wallpapers" "$HOME/.local/share/wallpapers"
