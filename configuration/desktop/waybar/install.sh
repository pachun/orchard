#!/usr/bin/env bash
# Top status bar. Modules defined in config/config.jsonc. Helper
# scripts under bin/ feed each module (bluetooth state, DND state,
# NordVPN connection state, recording indicator, pending updates,
# weather, wifi status). Symbol-only Nerd Font + Phosphor Icons fill
# in the glyphs the modules use. pacman-contrib supplies the
# `checkupdates` binary that waybar-updates calls without locking
# the system pacman DB.
#
# waybar comes from the AUR's git package, not extra, until the release
# after 0.15.0. The workspace buttons switch desktops by sending Hyprland
# the old `dispatch workspace N` string, which Hyprland's Lua config
# manager rejects, so under hyprland.lua the numbers in the bar stopped
# responding to clicks. Upstream fixed it on main (Alexays/Waybar#5013,
# then #5231 to detect the protocol) but has not released it. Once a
# release carries it, put `waybar` back in the pacman line and drop the
# AUR one.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm \
    cava playerctl ttf-nerd-fonts-symbols-mono pacman-contrib

bash "$TOOLS/install-yay.sh"

# waybar-git conflicts with extra's waybar, and a --noconfirm install answers
# no to pacman's "remove it?", so the swap has to be explicit. The running
# bar keeps its binary until restart-waybar below replaces it.
if pacman -Qq waybar >/dev/null 2>&1; then
    sudo pacman -R --noconfirm waybar
fi
bash "$TOOLS/aur-install.sh" ttf-phosphor-icons waybar-git

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/waybar"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

# Which slots the clock and the DND toggle occupy depends on the screen, so
# config.jsonc leaves modules-center and modules-right undefined and includes
# ~/.config/waybar/layout.jsonc for them. Point that at the right layout.
#
# The Mac's camera cutout sits in the middle of the notch strip the bar is
# sized to, so the centre of the bar is not somewhere anything can be read —
# a clock there would be bisected. Every other machine has an unobstructed
# screen, and a clock belongs in the middle of it.
#
# layouts/ deliberately sits outside config/ so link.sh doesn't stage both
# files into ~/.config/waybar; only the chosen one is linked, as layout.jsonc.
. "$TOOLS/machine.sh"
if is_apple_silicon; then
    layout=with-notch
else
    layout=without-notch
fi
ln -sfn "$HERE/layouts/$layout.jsonc" "$HOME/.config/waybar/layout.jsonc"

# Refresh the bar the moment the network returns rather than waiting on the
# next poll. A NetworkManager dispatcher pings waybar with SIGRTMIN+9 on
# interface-up, the signal the network and nordvpn modules refresh on. (The
# file keeps its original name from when the weather module listened too;
# weather now rides in the clock module and polls on its own.) It lives here
# rather than in a base installer so both machines get it, not just the Mac.
sudo tee /etc/NetworkManager/dispatcher.d/99-waybar-weather-refresh >/dev/null <<'EOF'
#!/bin/bash
case "$2" in
    up|connectivity-change)
        pkill -RTMIN+9 -x waybar
        ;;
esac
EOF
sudo chmod 755 /etc/NetworkManager/dispatcher.d/99-waybar-weather-refresh

# Waybar reads its config once at startup and its binary is whatever was
# there when it launched, so a bar that has been up since before a re-run
# would keep drawing the old modules on the old build until the next login.
"$HOME/.local/bin/restart-waybar"
