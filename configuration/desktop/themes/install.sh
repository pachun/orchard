#!/usr/bin/env bash
# Consolidated theming feature. Owns:
#   - Qt theming engine (kvantum + qt6ct settings) so the
#     xdg-desktop-portal-hyprland share picker and any future Qt apps
#     inherit a styled look instead of the default unstyled gray.
#   - GTK theming via gsettings (color-scheme).
#   - Catppuccin GTK themes from AUR (frappe + macchiato — one per
#     orchard-themes flavor) and the Catppuccin Kvantum theme.
#   - Everforest GTK theme built from upstream because the AUR package
#     (everforest-gtk-theme-git) pulls in gtk-engine-murrine, whose
#     autotools-era `configure` script can't auto-detect aarch64 and
#     fails to build on Asahi. murrine is a GTK2 runtime engine —
#     chromium's file picker uses GTK3 so skipping it is fine.
#   - ttf-phosphor-icons for the waybar status icons (set in waybar's
#     own install.sh too — duplicated install is a no-op).
#   - All theme config files (~/.config/gtk-3.0, gtk-4.0, Kvantum,
#     qt6ct, orchard-themes).
#   - set-theme / theme-menu scripts that swap the orchard-themes
#     active symlink and re-apply downstream policy.
# Fonts used to live here; they moved to the fonts/ component.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Qt theming runtime + sassc for the everforest from-source build.
sudo pacman -S --needed --noconfirm kvantum qt6ct sassc

bash "$TOOLS/install-yay.sh"
yay -S --needed --noconfirm \
    catppuccin-gtk-theme-frappe \
    catppuccin-gtk-theme-macchiato \
    kvantum-theme-catppuccin-git

# Everforest GTK from upstream (Fausto-Korpsvart). `--tweaks medium`
# matches the medium variant used by neanias/everforest-nvim and the
# ghostty palette, keeping the dark family consistent across apps.
WORK_DIR=/tmp/everforest-gtk-build
rm -rf "$WORK_DIR"
git clone --depth=1 https://github.com/Fausto-Korpsvart/Everforest-GTK-Theme.git "$WORK_DIR"
( cd "$WORK_DIR/themes" && sudo bash install.sh --dest /usr/share/themes --color dark --tweaks medium )

# Config files + theme switcher scripts.
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

# gsettings for system-wide GTK appearance. `gtk-theme` is owned by the
# orchard-themes switcher (each theme dir holds a `gtk-theme-name` file
# and `set-theme` applies it). `color-scheme` doesn't vary per theme yet
# (both shipped themes are dark) so it's set unconditionally here.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

# No window-control buttons on GTK/libadwaita header bars. Hyprland closes
# windows by keybind, and the theme's red close blob was the only thing the
# layout added. The settings.ini `gtk-decoration-layout` line covers GTK
# apps that read settings.ini; the gsettings key covers those that go through
# the settings portal instead.
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:'

# Seed the orchard-themes default on a fresh machine — only if the
# user hasn't picked one yet.
themes_dir="$HOME/.config/orchard-themes"
default_theme=catppuccin-frappe
if [ ! -L "$themes_dir/active" ]; then
    "$HOME/.local/bin/set-theme" "$default_theme"
fi
