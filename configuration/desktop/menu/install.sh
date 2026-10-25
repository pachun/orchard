#!/usr/bin/env bash
# The picker behind the bar's menus. Wi-Fi, Bluetooth, sound, VPN, theme and
# the system menu each build their rows in their own script and hand them to
# orchard-menu, which shows them in the launcher's frame — type to narrow,
# Enter or Ctrl+L to choose, Escape to dismiss — and prints the choice. The
# scripts keep fuzzel's dmenu contract (rows in, choice out), so this is the
# picker swapped under them, not a rewrite of them.
#
# A Quickshell program like the launcher, resident so a menu opens the
# instant its rows are ready; orchard-menu talks to it over Quickshell's IPC.
# Themed the same way: colors rendered from the active palette into a file it
# watches, so set-theme only re-renders. Every feature with a menu calls this
# installer before linking its script, so a standalone run of any of them
# brings the picker along; re-running is a no-op.
#
# This does not depend on the themes feature, although its colors come from
# there: the themes feature's own menu depends on this one, and the palette is
# read again at the first theme switch regardless.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm quickshell jq

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

"$HOME/.local/bin/render-menu-theme"
"$HOME/.local/bin/restart-menu"
