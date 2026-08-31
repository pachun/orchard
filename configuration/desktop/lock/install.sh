#!/usr/bin/env bash
# Locking, and what leads to it. Dim at 5 minutes, lock at 10, panel off at
# 10:30 — hypridle runs the clock, hyprlock is the lock screen itself.
#
# The reason any of this exists is the OLED panel. Before it, the screen never
# turned off at all: no idle daemon, and logind's IdleAction left at `ignore`.
# On OLED every lit pixel ages, so a display that is on for eleven hours a day
# showing the same bar in the same pixels is the thing that eventually burns in.
# Turning it off is the only real protection — a screensaver would light the
# panel to prevent a failure mode (CRT phosphor burn) this display can't have.
#
# hyprlock authenticates through PAM. Arch ships /etc/pam.d/hyprlock with the
# package; without it hyprlock cannot check a password and the session is
# unenterable. install.sh checks for it rather than trusting it, because the
# failure mode is being locked out of your own machine.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm hypridle hyprlock

if [ ! -f /etc/pam.d/hyprlock ]; then
  echo "lock: /etc/pam.d/hyprlock is missing — hyprlock cannot authenticate." >&2
  echo "      Do not let the screen lock until this is fixed; you would not" >&2
  echo "      be able to get back in. (Ctrl+Alt+F3 for a TTY if it happens.)" >&2
  exit 1
fi

bash "$TOOLS/link.sh" "$HERE/config/hypr" "$HOME/.config/hypr"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
