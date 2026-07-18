#!/usr/bin/env bash
# On-screen volume and brightness controls, styled like macOS's HUD.
#
# Changing volume, screen brightness, or keyboard brightness (F1/F2 and the
# audio keys — see hyprland.conf) pops a frosted rounded square: a themed glyph
# over a level bar, drawn by an eww widget. The glyphs are GTK symbolic icons,
# so GTK rasterises them at the display scale (crisp on a HiDPI panel) and
# recolours them from the theme. render-osd-theme regenerates the square's
# colours from the active orchard theme, which set-theme re-runs on every
# switch. wpctl (audio) and brightnessctl (backlight) do the actual level
# changes.
#
# Also sets up backlight control itself: udev rules that let the user adjust
# screen/keyboard backlight without sudo, and a fix for the keyboard backlight
# turning itself off. That was never software doing it: the Dell firmware runs
# its own timer, exposed as stop_timeout on the LED, and it ships set to 1m.
# Sixty seconds after your last keypress the keys go dark — exactly wrong for
# the case where you need them lit, sitting in a dark room not typing, hunting
# for the volume key. Nothing in userspace can win that fight; the timer has to
# be turned off where it lives.
#
# There is genuinely no "never" here: 0 is rejected, and so is anything past
# 12h — the firmware advertises a maximum per unit and the driver refuses to
# exceed it, so 1d and 24h are both Invalid argument. 12h is the longest value
# this BIOS will take, and it's the whole point: half a day without a keypress
# is longer than any evening you'd spend not typing.
#
# It's a udev rule rather than a startup command because the node is root-owned
# and the value resets to the firmware default whenever the LED is
# re-enumerated, not just at boot.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$TOOLS/install-yay.sh"
yay -S --needed --noconfirm eww
# brightnessctl drives the backlight levels; adwaita-icon-theme provides the
# symbolic glyphs and librsvg is the gdk-pixbuf loader GTK draws them with.
sudo pacman -S --needed --noconfirm brightnessctl adwaita-icon-theme librsvg

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config"

RULES=/etc/udev/rules.d/90-brightnessctl.rules
sudo tee "$RULES" >/dev/null <<'EOF'
ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp video /sys/class/backlight/%k/brightness", RUN+="/bin/chmod g+w /sys/class/backlight/%k/brightness"
ACTION=="add", SUBSYSTEM=="leds", RUN+="/bin/chgrp video /sys/class/leds/%k/brightness", RUN+="/bin/chmod g+w /sys/class/leds/%k/brightness"
ACTION=="add", SUBSYSTEM=="leds", KERNEL=="*kbd_backlight", ATTR{stop_timeout}="12h"
EOF

if ! id -nG "$USER" | tr ' ' '\n' | grep -qx video; then
  sudo usermod -aG video "$USER"
fi

sudo udevadm control --reload-rules
# --action=add, not the default. Every rule in this file matches ACTION=="add",
# and `udevadm trigger` sends ACTION=change unless told otherwise — so without
# this the rules reload and then match nothing, and you'd have to reboot before
# any of it took effect.
sudo udevadm trigger --action=add --subsystem-match=backlight --subsystem-match=leds

# Generate the themed colours for the current theme, then (re)start the eww
# daemon so it's ready to pop the window on the first keypress.
"$HOME/.local/bin/render-osd-theme"
"$HOME/.local/bin/restart-osd"
