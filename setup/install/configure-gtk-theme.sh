#!/usr/bin/env bash
# Set the GTK theme via gsettings. GTK reads this from dconf before falling
# back to ~/.config/gtk-{3,4}.0/settings.ini, so the dotfile alone isn't
# enough — the value has to be written imperatively. Idempotent.
set -euo pipefail

gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-frappe-blue-standard+default'
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface font-name 'SF Pro 11'
