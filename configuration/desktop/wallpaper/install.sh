#!/usr/bin/env bash
# Wallpaper. Owns:
#   - awww, the wallpaper daemon (upstream's rename of swww; the Arch
#     package Provides/Replaces swww). A persistent daemon with IPC, so
#     set-wallpaper can swap images with an animated transition — the
#     center-outward theme sweep — instead of swapping swaybg processes
#     the way this feature used to. Like swaybg it draws through
#     wlr-layer-shell with no monitor introspection, so it dodges the
#     hyprpaper-on-Asahi crash (empty EDID → null std::string deref) that
#     ruled hyprpaper out in the first place.
#   - set-wallpaper, which works out which image ought to be up and puts
#     it up. A choice made there outranks the active theme's own
#     wallpaper and survives theme switches — for trying an image on
#     before committing it to a theme. Called with no image at all by
#     hyprland.conf at login and by set-theme on a theme switch, both of
#     which need the desktop to be correct without choosing anything.
#   - orchard-wallpaper-portal, the missing XDG desktop portal backend
#     that makes Nautilus's built-in "Set as Wallpaper" work. See below.
# Idempotent.
#
# The images under wallpapers/ are symlinked into
# ~/.local/share/wallpapers/ so they can be referenced by a stable path.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# python-gobject is orchard-wallpaper-portal's only dependency — it talks
# D-Bus through Gio.
sudo pacman -S --needed --noconfirm awww python-gobject

# swaybg is what this feature installed before awww; nothing references it
# anymore. set-wallpaper kills any still-running instance on its next run.
if pacman -Q swaybg >/dev/null 2>&1; then
    sudo pacman -Rns --noconfirm swaybg
fi

bash "$TOOLS/link.sh" "$HERE/wallpapers" "$HOME/.local/share/wallpapers"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

# D-Bus starts the portal backend on demand from this, so it needs no
# exec-once and isn't running when nothing has asked for a wallpaper.
bash "$TOOLS/link.sh" "$HERE/dbus" "$HOME/.local/share/dbus-1/services"

# The .portal file is the one piece that can't live in $HOME:
# xdg-desktop-portal only scans XDG_DATA_DIRS for these, and with
# XDG_DATA_DIRS unset that means /usr/local/share and /usr/share. Copied
# rather than symlinked into the repo, since root-owned symlinks into a
# user checkout are a footgun if the checkout ever moves.
sudo install -Dm644 "$HERE/portals/orchard.portal" \
    /usr/share/xdg-desktop-portal/portals/orchard.portal

# xdg-desktop-portal reads the backend list and portals.conf once, at
# startup. Without a restart it goes on believing nothing implements the
# Wallpaper portal and Nautilus's menu item stays dead.
systemctl --user restart xdg-desktop-portal.service
