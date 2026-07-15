#!/usr/bin/env bash
# All font installation, split out of themes/ because fonts aren't
# theme-specific — the typeface doesn't change when the color scheme
# does. Owns:
#   - noto-fonts / noto-fonts-cjk: fallback coverage so text in other
#     languages (Chinese / Japanese / Korean) and rare symbols render as
#     real glyphs instead of tofu boxes.
#   - noto-fonts-emoji: the only color emoji font on the box; ships its
#     own fontconfig rule wiring Noto Color Emoji in as the emoji
#     fallback for the sans / serif / mono generics.
#   - apple-fonts (SF Pro / SF Mono / New York): the system UI font (set
#     via gsettings below) and waybar's primary font. Pulled from Apple's
#     CDN by the AUR package; --skipinteg because Apple bumps the files
#     and the AUR checksums go stale, tripping makepkg's integrity check.
#   - MonoLisa: a paid font with no package or public download, so the
#     .ttf files are vendored under vendored/ and symlinked into the
#     fontconfig search path.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji

bash "$TOOLS/install-yay.sh"
yay -S --needed --noconfirm --mflags "--skipinteg" apple-fonts

# The system UI font. Doesn't vary per theme (always SF Pro), so it's set
# here rather than by the orchard-themes switcher.
gsettings set org.gnome.desktop.interface font-name 'SF Pro 11'

# Vendored MonoLisa — symlinked into the fontconfig search path and
# registered with fc-cache so apps pick it up by family name.
FONTS_DEST="$HOME/.local/share/fonts/orchard"
if [ ! -L "$FONTS_DEST" ] || [ "$(readlink -f "$FONTS_DEST")" != "$(readlink -f "$HERE/vendored")" ]; then
  rm -rf "$FONTS_DEST"
  mkdir -p "$(dirname "$FONTS_DEST")"
  ln -s "$HERE/vendored" "$FONTS_DEST"
  fc-cache -f >/dev/null
fi
