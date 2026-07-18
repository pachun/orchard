#!/usr/bin/env bash
# Media playback keys. playerctl is the MPRIS backend for the prev/play-pause/
# next binds (XF86AudioPrev/Play/Next in hyprland.conf). No on-screen indicator,
# matching macOS, which shows nothing for the media keys — the volume and
# brightness keys are the ones that get the OSD square (see
# volume-and-brightness-controls).
# Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm playerctl
