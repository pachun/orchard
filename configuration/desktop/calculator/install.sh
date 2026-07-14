#!/usr/bin/env bash
# The calculator. Basic, scientific, financial and programming modes, plus unit
# and currency conversion — the same ground macOS's Calculator covers.
#
# gnome-calculator rather than qalculate, which is the more powerful tool and
# the wrong one: it is GTK3, so it wears a different theme from everything else
# here, and its window is a workbench rather than a calculator. This is GTK4, so
# it looks like Nautilus, and it follows the desktop's light and dark with the
# theme because set-theme already writes color-scheme.
#
# Bound to the keyboard's own calculator key, which the XPS declares. If your
# keyboard has no such key, use the bind in hyprland.conf.
# Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm gnome-calculator
