#!/usr/bin/env bash
# Control the Apple TVs with the vim keys. pyatv speaks Apple's Companion
# protocol (what the Siri Remote uses); Cmd+Shift+T or the bar's TV glyph
# opens a which-key card in the corner and a Hyprland submap hands hjkl to
# the TV (see hyprland.conf's appletv submap and waybar's custom/apple-tv).
# pyatv arrives as a uv tool — per-user, no AUR build. Pairing needs a PIN
# read off each TV, so it lives in ./connect apple-tv.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The card's colours are rendered from the active orchard theme, so the
# theme system has to be in place before the daemon starts.
bash "$HERE/../themes/install.sh"

sudo pacman -S --needed --noconfirm uv
uv tool install --quiet pyatv

bash "$TOOLS/install-yay.sh"
bash "$TOOLS/aur-install.sh" eww

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

"$HOME/.local/bin/render-apple-tv-remote-theme"
"$HOME/.local/bin/restart-apple-tv-remote"
