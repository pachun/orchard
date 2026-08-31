#!/usr/bin/env bash
# Screenshot + recording stack (Cmd+Shift+3/4/5 in hyprland.conf).
# grim grabs pixels, slurp picks regions, wf-recorder writes mp4.
# hyprpicker freezes the screen during region-select (used by
# ~/.local/bin/screenshot) so on-screen UI (fuzzel menus, the bar)
# stays visible while you draw the box. Each shot also goes to the
# clipboard via wl-copy (provided by the clipboard feature).
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm grim slurp wf-recorder hyprpicker

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
