#!/usr/bin/env bash
# Slide decks written as Markdown: one file, slides split by `---`, with
# a visual editor beside the text and a fullscreen presenter. Hype is
# Omarchy's presentation app (Qt Quick), and it exports a deck to PDF.
#
# It is published only in Omarchy's own package repository, not in Arch's
# or the AUR. Rather than give pacman a second package source for one
# app, it is built from that repository's recipe into a real pacman
# package. Built once; a system update does not rebuild it.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

OMARCHY_RECIPE=https://raw.githubusercontent.com/omacom/omarchy-pkgs/master/pkgbuilds/hype

# The recipe's test-only dependencies include qt6-webengine, a browser
# engine nothing here uses. The recipe has no test step, so skipping
# checks leaves the build unchanged and that package uninstalled.
build_hype_from_the_omarchy_recipe() {
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT

  curl -fsSL -o "$WORK/PKGBUILD" "$OMARCHY_RECIPE/PKGBUILD"
  curl -fsSL -o "$WORK/hype.install" "$OMARCHY_RECIPE/hype.install"

  ( cd "$WORK" && makepkg -fsi --nocheck --noconfirm )
}

# Qt's multimedia module plays nothing without a backend, and pacman
# offers two. qt6-multimedia-ffmpeg is named so the choice is the same
# one the video trimmer uses, rather than whichever --noconfirm picks.
# source-highlight colors the code blocks on a slide.
sudo pacman -S --needed --noconfirm \
  base-devel cmake curl pkgconf \
  ffmpeg hicolor-icon-theme libwebp zlib \
  qt6-base qt6-declarative qt6-imageformats qt6-multimedia \
  qt6-multimedia-ffmpeg qt6-svg qt6-wayland \
  source-highlight \
  xdg-desktop-portal xdg-desktop-portal-gtk

if ! pacman -Qq hype >/dev/null 2>&1; then
  build_hype_from_the_omarchy_recipe
fi

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
