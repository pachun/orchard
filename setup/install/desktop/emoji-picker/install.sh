#!/usr/bin/env bash
# Emoji picker (Ctrl+Cmd+Space in hyprland.conf, macOS-style).
# rofimoji is the picker; fuzzel (handled by the fuzzel feature) is
# the menu it draws into; ydotool injects the chosen emoji into the
# focused window via /dev/uinput. ydotool over wtype because wtype
# types via wlr-virtual-keyboard, which Chromium-on-Ozone/Wayland
# silently ignores for text inputs — ydotool's uinput path looks
# like a real keyboard so chromium URL bars and form fields receive
# the emoji. The ydotool daemon runs as a user service.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/../fuzzel/install.sh"
sudo pacman -S --needed --noconfirm rofimoji ydotool

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

systemctl --user daemon-reload
systemctl --user enable --now ydotool.service
