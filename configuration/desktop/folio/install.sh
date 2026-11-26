#!/usr/bin/env bash
# A second file browser, beside Nautilus rather than in place of it.
# Folio is Omarchy's file manager (Qt Quick): quiet, driven from the
# keyboard, with previews built in.
#
# It is here to be lived with before deciding whether it takes over, so
# everything that reaches for "the file browser" still gets Nautilus:
#   - Folders keep opening in Nautilus. Folio's desktop entry also claims
#     them, so the default is pinned rather than left to whichever entry
#     the system lists first.
#   - "Show in folder" from other apps keeps going to Nautilus. Both
#     packages ship the D-Bus service file that answers it, and pacman
#     refuses to install two packages owning one file, so Folio's copy is
#     left out of the package built here (omarchy-recipe/folio).
#   - Open and Save dialogs are unchanged. Folio ships its own, but the
#     wallpaper feature's portals.conf names the backends in use.
#
# It is published only in Omarchy's own package repository, so the
# omarchy-apps feature builds it from that repository's recipe and
# system-update keeps it current.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ffmpegthumbnailer, glycin and papers draw Folio's video, image and PDF
# thumbnails; gvfs and jq are its browsing of tailnet machines.
sudo pacman -S --needed --noconfirm \
  glib2 hicolor-icon-theme libarchive xdg-utils zlib \
  qt6-base qt6-declarative qt6-imageformats qt6-multimedia \
  qt6-multimedia-ffmpeg qt6-svg qt6-wayland \
  ffmpegthumbnailer glycin gvfs jq papers

bash "$HERE/../omarchy-apps/install.sh"
bash "$TOOLS/link.sh" "$HERE/omarchy-recipe" "$HOME/.config/omarchy-recipes"
"$HOME/.local/bin/omarchy-apps" install folio

xdg-mime default org.gnome.Nautilus.desktop inode/directory

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
