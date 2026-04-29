#!/usr/bin/env bash
# Allow the user to write screen + keyboard backlight values without sudo.
# Arch's brightnessctl package ships only the binary, so we install the
# upstream udev rules manually and add the user to the `video` group.
# Idempotent — safe to re-run.
set -euo pipefail

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
