#!/usr/bin/env bash
# The launcher. Cmd+Space opens a search field over the desktop; typing
# narrows a list of everything on this machine worth opening — the apps on
# the Cmd+letter keys and the bar's menus and panels alike — Enter opens the
# selection, Escape closes.
#
# Nothing is indexed, and there is no central list. A feature that has
# something worth opening ships a launcher/<Name>.json and links it into
# ~/.config/launcher/ from its own install.sh; the launcher reads that
# directory each time it opens. So the list is exactly the features on the
# machine, a feature that is removed takes its row with it, and the many
# features that are plumbing (fonts, polkit, codecs) ship nothing. The file's
# name is the entry's name, spelled as it should appear (Wi-Fi.json, Apple TV
# remote.json), so no name is written twice; inside:
#
#   { "icon": "<Phosphor glyph>", "command": "wifi-menu",
#     "aliases": ["network", "internet"] }
#
# Aliases are the other things you might call it, and search as names do.
# The command runs with ~/.local/bin on the path. Phosphor glyphs match the
# bar and the menus; look codepoints up as waybar's modules do.
#
# After xmsadik's YourOmaLauncher plugin for Omarchy, cut down for this setup:
# one list rather than folders, entries edited in the repo rather than in the
# panel. A Quickshell program like the window switcher, and themed the same
# way: colors rendered from the active palette into a file it watches, so
# set-theme only re-renders.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The colors come from the active theme, so the theme system has to be in
# place before the launcher starts.
bash "$HERE/../themes/install.sh"

sudo pacman -S --needed --noconfirm quickshell jq

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

"$HOME/.local/bin/render-launcher-theme"
"$HOME/.local/bin/restart-launcher"
