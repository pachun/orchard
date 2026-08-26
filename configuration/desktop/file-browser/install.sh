#!/usr/bin/env bash
# The file browser, and Quick Look for it.
#
# Nautilus was only ever here as a dependency of xdg-desktop-portal-gnome, even
# though Cmd+E in hyprland.conf launches it by name — so it's installed on
# purpose now.
#
# sushi is GNOME's Quick Look: Space on a selected file opens a preview window,
# the arrow keys walk the rest of the folder, Space closes it. Images, PDFs,
# text and source, audio and video, and (with libreoffice) office documents.
# Anything it can't render falls back to a name-and-type card.
# Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm nautilus sushi
