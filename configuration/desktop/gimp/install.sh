#!/usr/bin/env bash
# General-purpose raster image editor. GIMP 3.x — GTK3, native
# Wayland/HiDPI, non-destructive editing.
# Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm gimp
