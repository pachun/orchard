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
# next poll — up to 10 minutes for the weather module. A NetworkManager
# dispatcher pings waybar with SIGRTMIN+9 on interface-up, the signal the
# weather, network, and nordvpn modules all refresh on. It lives here rather
# than in a base installer so both machines get it, not just the Mac.
sudo tee /etc/NetworkManager/dispatcher.d/99-waybar-weather-refresh >/dev/null <<'EOF'
#!/bin/bash
case "$2" in
    up|connectivity-change)
        pkill -RTMIN+9 -x waybar
        ;;
esac
EOF
sudo chmod 755 /etc/NetworkManager/dispatcher.d/99-waybar-weather-refresh
