#!/usr/bin/env bash
# Backlight control — `brightnessctl` binary + udev rules that let the
# user adjust screen/keyboard backlight without sudo. Wired to
# F1/F2/F5/F6 hyprland binds via dotfiles/local/bin/screen-brightness.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm brightnessctl

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"

RULES=/etc/udev/rules.d/90-brightnessctl.rules
sudo tee "$RULES" >/dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="leds", RUN+="/bin/chgrp video /sys/class/leds/%k/brightness", RUN+="/bin/chmod g+w /sys/class/leds/%k/brightness"
EOF

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
  sudo usermod -aG video "$USER"
fi

sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=backlight --subsystem-match=leds
