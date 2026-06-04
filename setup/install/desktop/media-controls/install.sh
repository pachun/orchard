#!/usr/bin/env bash
# Media playback control via MPRIS (F7/F8/F9 binds in hyprland.conf
# through swayosd-client's --playerctl wrapper). swayosd also shows
# the on-screen pill that pops up when volume / brightness changes.
# Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm playerctl swayosd
