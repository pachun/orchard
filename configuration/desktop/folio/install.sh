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
#     left out of the package built here.
#   - Open and Save dialogs are unchanged. Folio ships its own, but the
#     wallpaper feature's portals.conf names the backends in use.
#
# It is published only in Omarchy's own package repository, not in Arch's
# or the AUR. Rather than give pacman a second package source for one
# app, it is built from that repository's recipe into a real pacman
# package. Built once; a system update does not rebuild it.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OMARCHY_RECIPE=https://raw.githubusercontent.com/omacom/omarchy-pkgs/master/pkgbuilds/folio

leave_show_in_folder_to_nautilus() {
  local recipe="$1"
  cat >> "$recipe" <<'EOF'

eval "omarchy_$(declare -f package)"
package() {
  omarchy_package
  rm "$pkgdir/usr/share/dbus-1/services/org.freedesktop.FileManager1.service"
}
EOF
}

build_folio_from_the_omarchy_recipe() {
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT

  curl -fsSL -o "$WORK/PKGBUILD" "$OMARCHY_RECIPE/PKGBUILD"
  leave_show_in_folder_to_nautilus "$WORK/PKGBUILD"

  ( cd "$WORK" && makepkg -fsi --nocheck --noconfirm )
}

# ffmpegthumbnailer, glycin and papers draw Folio's video, image and PDF
# thumbnails; gvfs and jq are its browsing of tailnet machines.
sudo pacman -S --needed --noconfirm \
  base-devel cmake curl \
  glib2 hicolor-icon-theme libarchive xdg-utils zlib \
  qt6-base qt6-declarative qt6-imageformats qt6-multimedia \
  qt6-multimedia-ffmpeg qt6-svg qt6-wayland \
  ffmpegthumbnailer glycin gvfs jq papers

if ! pacman -Qq folio >/dev/null 2>&1; then
  build_folio_from_the_omarchy_recipe
fi

xdg-mime default org.gnome.Nautilus.desktop inode/directory

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
