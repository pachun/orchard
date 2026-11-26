#!/usr/bin/env bash
# Slide decks written as Markdown: one file, slides split by `---`, with
# a visual editor beside the text and a fullscreen presenter. Hype is
# Omarchy's presentation app (Qt Quick), and it exports a deck to PDF.
#
# It is published only in Omarchy's own package repository, so the
# omarchy-apps feature builds it from that repository's recipe and
# system-update keeps it current.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Qt's multimedia module plays nothing without a backend, and pacman
# offers two. qt6-multimedia-ffmpeg is named so the choice is the same
# one the video trimmer uses, rather than whichever --noconfirm picks.
# source-highlight colors the code blocks on a slide.
sudo pacman -S --needed --noconfirm \
  ffmpeg hicolor-icon-theme libwebp zlib \
  qt6-base qt6-declarative qt6-imageformats qt6-multimedia \
  qt6-multimedia-ffmpeg qt6-svg qt6-wayland \
  source-highlight \
  xdg-desktop-portal xdg-desktop-portal-gtk

bash "$HERE/../omarchy-apps/install.sh"
bash "$TOOLS/link.sh" "$HERE/omarchy-recipe" "$HOME/.config/omarchy-recipes"
"$HOME/.local/bin/omarchy-apps" install hype

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
