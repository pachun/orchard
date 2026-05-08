#!/usr/bin/env bash
# GTK settings written via gsettings (which writes dconf, the layer
# GTK reads before settings.ini). Idempotent.
#
# `gtk-theme` is no longer set here — it's owned by the orchard-themes
# switcher: each theme dir holds a `gtk-theme-name` file and `set-theme`
# applies it via gsettings on swap. configure-themes.sh runs `set-theme`
# on a fresh install (only if no active theme is set yet), so the
# initial gtk-theme value still gets written here as a side-effect.
#
# `color-scheme` and `font-name` are still set unconditionally because
# they don't vary per theme yet (both currently-installed themes are
# dark; the font is always SF Pro).
set -euo pipefail

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface font-name 'SF Pro 11'
