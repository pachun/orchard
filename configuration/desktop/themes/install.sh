#!/usr/bin/env bash
# Consolidated theming feature. Owns:
#   - Qt theming engine (kvantum + qt6ct settings) so the
#     xdg-desktop-portal-hyprland share picker and any future Qt apps
#     inherit a styled look instead of the default unstyled gray.
#   - GTK theming via gsettings (color-scheme + font-name).
#   - Catppuccin GTK themes from AUR (frappe + macchiato — one per
#     orchard-themes flavor) and the Catppuccin Kvantum theme.
#   - Everforest GTK theme built from upstream because the AUR package
#     (everforest-gtk-theme-git) pulls in gtk-engine-murrine, whose
#     autotools-era `configure` script can't auto-detect aarch64 and
#     fails to build on Asahi. murrine is a GTK2 runtime engine —
#     chromium's file picker uses GTK3 so skipping it is fine.
#   - apple-fonts (SF Pro / SF Mono / New York) used as the system UI
#     font in gsettings and as the primary font in waybar.
#   - ttf-phosphor-icons for the waybar status icons (set in waybar's
#     own install.sh too — duplicated install is a no-op).
#   - All theme config files (~/.config/gtk-3.0, gtk-4.0, Kvantum,
#     qt6ct, orchard-themes).
#   - set-theme / theme-menu scripts that swap the orchard-themes
#     active symlink and re-apply downstream policy.
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

# apple-fonts pulls SF Pro/Mono/New York straight from Apple's CDN; its AUR
# checksums go stale whenever Apple ships a font update, tripping makepkg's
# integrity check. Skip it — the source is Apple over HTTPS and we want the
# current fonts regardless.
yay -S --needed --noconfirm --mflags "--skipinteg" apple-fonts

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
# and `set-theme` applies it). `color-scheme` and `font-name` don't
# vary per theme yet (both shipped themes are dark; font is always SF
# Pro) so they're set unconditionally here.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface font-name 'SF Pro 11'

# Vendored fonts (MonoLisa) — symlinked into the fontconfig search path
# and registered with fc-cache so apps can pick them up by family name.
FONTS_DEST="$HOME/.local/share/fonts/orchard"
if [ ! -L "$FONTS_DEST" ] || [ "$(readlink -f "$FONTS_DEST")" != "$(readlink -f "$HERE/fonts")" ]; then
  rm -rf "$FONTS_DEST"
  mkdir -p "$(dirname "$FONTS_DEST")"
  ln -s "$HERE/fonts" "$FONTS_DEST"
  fc-cache -f >/dev/null
fi

# Seed the orchard-themes default on a fresh machine — only if the
# user hasn't picked one yet.
themes_dir="$HOME/.config/orchard-themes"
default_theme=catppuccin-frappe
if [ ! -L "$themes_dir/active" ]; then
    "$HOME/.local/bin/set-theme" "$default_theme"
fi
