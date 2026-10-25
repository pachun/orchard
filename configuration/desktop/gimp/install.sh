#!/usr/bin/env bash
# General-purpose raster image editor. GIMP 3.x — GTK3, native
# Wayland/HiDPI, non-destructive editing.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm gimp

bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
