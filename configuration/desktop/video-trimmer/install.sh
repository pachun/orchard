#!/usr/bin/env bash
# Trim a video the way iOS does: drag a handle at either end, cut pieces
# out of the middle, join clips, export an MP4. Omacut is Omarchy's
# trimmer (Qt Quick over ffmpeg).
#
# It is published only in Omarchy's own package repository, not in Arch's
# or the AUR. Rather than give pacman a second package source for one
# app, it is built from that repository's recipe into a real pacman
# package. Built once; a system update does not rebuild it.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OMARCHY_RECIPE=https://raw.githubusercontent.com/omacom/omarchy-pkgs/master/pkgbuilds/omacut

build_omacut_from_the_omarchy_recipe() {
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT

  curl -fsSL -o "$WORK/PKGBUILD" "$OMARCHY_RECIPE/PKGBUILD"
  curl -fsSL -o "$WORK/omacut.install" "$OMARCHY_RECIPE/omacut.install"

  ( cd "$WORK" && makepkg -fsi --noconfirm )
}

# Qt's multimedia module plays nothing without a backend, and pacman
# offers two. qt6-multimedia-ffmpeg is named so the choice is the one
# Omacut is tested against, rather than whichever --noconfirm picks.
# The portal pair is Omacut's file picker.
sudo pacman -S --needed --noconfirm \
  base-devel cmake curl \
  ffmpeg hicolor-icon-theme \
  qt6-base qt6-declarative qt6-multimedia qt6-multimedia-ffmpeg qt6-wayland \
  xdg-desktop-portal xdg-desktop-portal-gtk

if ! pacman -Qq omacut >/dev/null 2>&1; then
  build_omacut_from_the_omarchy_recipe
fi

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
