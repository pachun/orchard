#!/usr/bin/env bash
# The file browser: Folio, Omarchy's file manager (Qt Quick). One quiet
# window driven from the keyboard, with columns, a list and a grid, and a
# full-size preview on Space. Cmd+E opens one beside what you're doing
# (hyprland.lua), and h/j/k/l move around in it (xremap's config).
#
# It is published only in Omarchy's own package repository, so the
# omarchy-apps feature builds it from that repository's recipe and
# system-update keeps it current.
#
# Folio is what everything reaching for "the file browser" gets:
#   - Folders open in it: the default for inode/directory is pinned,
#     because Nautilus claims folders too.
#   - Other apps' "Show in folder" goes to it. A machine may still have
#     Nautilus (GNOME's portal and settings panel depend on it), whose
#     package owns the D-Bus service file that answers "Show in folder";
#     pacman won't install a second package owning that file. So Folio's
#     copy is left out of the package built here (omarchy-recipe/folio)
#     and a copy in the user's own D-Bus services, which outrank the
#     system's, names Folio either way.
#   - Open and Save dialogs are not Folio's. It ships one, but its dialog
#     opens as a window of its own instead of over the app that asked, so
#     the wallpaper feature's portals.conf keeps GTK's.
#
# Folio has no "Set as Wallpaper" of its own; folio-plugins/wallpaper adds
# it to the right-click menu of pictures, calling the wallpaper feature's
# set-wallpaper.
#
# The pinned places in the sidebar are GTK's bookmarks, which Folio shares
# with GTK's file dialogs. bin/render-nautilus-sidebar writes them from
# ./sidebar-places; the bookmarks file is rendered rather than symlinked
# because both apps rewrite it when a folder is pinned in-app.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ffmpegthumbnailer, glycin and papers draw Folio's video, image and PDF
# thumbnails; gvfs and jq are its browsing of tailnet machines.
# python-gobject is render-nautilus-sidebar's.
bash "$TOOLS/install-packages.sh" \
  glib2 hicolor-icon-theme libarchive xdg-utils zlib \
  qt6-base qt6-declarative qt6-imageformats qt6-multimedia \
  qt6-multimedia-ffmpeg qt6-svg qt6-wayland \
  ffmpegthumbnailer glycin gvfs jq papers python-gobject

bash "$HERE/../omarchy-apps/install.sh"
bash "$TOOLS/link.sh" "$HERE/omarchy-recipe" "$HOME/.config/omarchy-recipes"
"$HOME/.local/bin/omarchy-apps" install folio

xdg-mime default folio.desktop inode/directory

# Folio opens in columns, which need more room than half of a laptop
# panel: beside its sidebar the current column slides partly out of view.
# The list fits. Folio keeps this file itself and saves the view chosen
# there, so it is only written where Folio has never run.
start_in_list_view_on_a_new_machine() {
  local folio_settings="$HOME/.config/folio/folio.conf"
  if [ ! -f "$folio_settings" ]; then
    mkdir -p "$(dirname "$folio_settings")"
    printf '[General]\nviewMode=list\n' > "$folio_settings"
  fi
}
start_in_list_view_on_a_new_machine

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
bash "$TOOLS/link.sh" "$HERE/folio-plugins" "$HOME/.local/share/folio/plugins"
bash "$TOOLS/link.sh" "$HERE/dbus-services" "$HOME/.local/share/dbus-1/services"

# The session bus reads its service files when it starts; without this,
# "Show in folder" keeps going to Nautilus until the next login.
busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig >/dev/null 2>&1 || true

"$HOME/.local/bin/render-nautilus-sidebar" "$HERE/sidebar-places"
