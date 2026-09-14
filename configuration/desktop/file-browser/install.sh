#!/usr/bin/env bash
# The file browser, and Quick Look for it.
#
# Nautilus was only ever here as a dependency of xdg-desktop-portal-gnome, even
# though Cmd+E in hyprland.lua launches it by name — so it's installed on
# purpose now.
#
# sushi is GNOME's Quick Look: Space on a selected file opens a preview window,
# the arrow keys walk the rest of the folder, Space closes it. Images, PDFs,
# text and source, audio and video, and (with libreoffice) office documents.
# Anything it can't render falls back to a name-and-type card.
#
# sushi sizes its window wrong on a HiDPI Wayland desktop (half size) and
# shows a transparent image as if it had a solid background, so patched
# copies of its window and image scripts (see bin/patch-quick-look) are
# rendered to ~/.config/sushi and handed to it through GLib's resource
# overlay variable. The variable has to reach the D-Bus-activated previewer,
# which the user's systemd manager launches, so it is set both for this
# session and in environment.d for the next login.
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

patch_quick_look() {
  "$HOME/.local/bin/patch-quick-look"
  local resources=/org/gnome/NautilusPreviewer/js
  local overlay="G_RESOURCE_OVERLAYS=$resources/ui/mainWindow.js=$HOME/.config/sushi/mainWindow.js:$resources/viewers/image.js=$HOME/.config/sushi/image.js"
  mkdir -p "$HOME/.config/environment.d"
  printf '%s\n' "$overlay" > "$HOME/.config/environment.d/quick-look.conf"
  systemctl --user set-environment "$overlay"
}
patch_quick_look
