#!/usr/bin/env bash
# Wayland clipboard. wl-clipboard provides wl-paste/wl-copy; cliphist is
# the daemon that records every copy event and lets you paste older
# ones. Wired to Cmd+Shift+V via a fuzzel picker in hyprland.conf.
# Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm cliphist wl-clipboard
