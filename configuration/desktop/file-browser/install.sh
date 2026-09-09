#!/usr/bin/env bash
# The file browser, and Quick Look for it.
#
# Nautilus was only ever here as a dependency of xdg-desktop-portal-gnome, even
# though Cmd+E in hyprland.conf launches it by name — so it's installed on
# purpose now.
#
# sushi is GNOME's Quick Look: Space on a selected file opens a preview window,
# the arrow keys walk the rest of the folder, Space closes it. Images, PDFs,
# text and source, audio and video, and (with libreoffice) office documents.
# Anything it can't render falls back to a name-and-type card.
#
# The sidebar shows exactly the places listed in ./sidebar-places, in that
# order, with the icons named there, then any mounts, and no dividers.
# bin/render-nautilus-sidebar turns that list into GTK's bookmarks file and
# ~/.config/gtk-4.0/nautilus-sidebar.css (imported by the themes feature's
# gtk.css); the header of that script explains what Nautilus hardcodes and
# why CSS is the only lever. The bookmarks file is rendered rather than
# symlinked because Nautilus rewrites it whenever a bookmark is added in-app.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm nautilus sushi ydotool python-gobject at-spi2-core

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

"$HOME/.local/bin/render-nautilus-sidebar" "$HERE/sidebar-places"
