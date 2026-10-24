#!/usr/bin/env bash
# The window switcher. Hold Cmd and press Tab: a strip of live window
# previews appears mid-screen in most-recently-used order with the previous
# window already selected. Tab moves forward, Shift+Tab or ` back, releasing
# Cmd focuses the selection, Escape cancels. Windows on other desktops are in
# the strip too, and picking one goes there.
#
# This replaces Hyprland's cycle_next on Cmd+Tab, which walked the current
# desktop's windows blind: no sign of what the next press would land on, and
# nothing from any other desktop. The design follows lsongdev's
# omarchy-switcher plugin, re-done for this setup, which has no Omarchy shell
# to plug into. It is a Quickshell program (the one thing here on Quickshell;
# the other panels are eww) because Quickshell's ScreencopyView can show a
# window that is on another desktop, which nothing in eww can. Hyprland's
# focus history is the order, so there is no window history of our own.
#
# Colors are rendered from the active orchard palette into colors.json, which
# the switcher watches, so set-theme only re-renders. Hyprland binds the keys
# to the switcher's global shortcuts from its own config.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The colors come from the active theme, so the theme system has to be in
# place before the switcher starts; configure runs features alphabetically,
# which puts themes before this one anyway, but a standalone run should not
# depend on that.
bash "$HERE/../themes/install.sh"

sudo pacman -S --needed --noconfirm quickshell

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

"$HOME/.local/bin/render-window-switcher-theme"
"$HOME/.local/bin/restart-window-switcher"
