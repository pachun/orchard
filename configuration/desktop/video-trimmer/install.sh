#!/usr/bin/env bash
# Trim a video the way iOS does: drag a handle at either end, cut pieces
# out of the middle, join clips, export an MP4. Omacut is Omarchy's
# trimmer (Qt Quick over ffmpeg).
#
# It is published only in Omarchy's own package repository, so the
# omarchy-apps feature builds it from that repository's recipe and
# system-update keeps it current.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Qt's multimedia module plays nothing without a backend, and pacman
# offers two. qt6-multimedia-ffmpeg is named so the choice is the one
# Omacut is tested against, rather than whichever --noconfirm picks.
# The portal pair is Omacut's file picker.
bash "$TOOLS/install-packages.sh" \
  ffmpeg hicolor-icon-theme \
  qt6-base qt6-declarative qt6-multimedia qt6-multimedia-ffmpeg qt6-wayland \
  xdg-desktop-portal xdg-desktop-portal-gtk

bash "$HERE/../omarchy-apps/install.sh"
bash "$TOOLS/link.sh" "$HERE/omarchy-recipe" "$HOME/.config/omarchy-recipes"
"$HOME/.local/bin/omarchy-apps" install omacut

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
