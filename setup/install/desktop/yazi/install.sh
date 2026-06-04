#!/usr/bin/env bash
# Yazi TUI file manager (Cmd+E in hyprland). imagemagick and
# ffmpegthumbnailer extend its preview support to extra image formats
# and video thumbnails. Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm yazi imagemagick ffmpegthumbnailer
