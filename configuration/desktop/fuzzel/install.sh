#!/usr/bin/env bash
# fuzzel — fast minimal wlroots application launcher / menu. Shared
# infrastructure: emoji-picker, bluetooth-menu, theme-menu,
# nordvpn-menu, polkit-agent, etc. all spawn fuzzel for selection
# UIs. Owns the install + the orchard-tuned fuzzel.ini config.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm fuzzel

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/fuzzel"
