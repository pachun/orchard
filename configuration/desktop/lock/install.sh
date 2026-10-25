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
# hyprlock authenticates through PAM, and the stack it uses is this feature's
# own (pam/hyprlock): the package's stack makes a wrong password wait two
# seconds before it is called wrong, which at a lock screen is two seconds
# before you can try again. Ours drops the delay and keeps the lockout that
# actually stops a brute force — with the lockout's own numbers set in
# pam/faillock.conf, since the package's three misses then ten minutes out is
# tuned for a server, not a laptop. The failure mode of a broken PAM file is
# being locked out of your own machine, so each file is only replaced when its
# content differs, and hyprlock refuses to start on a stack it cannot parse
# rather than locking with no way back in.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm hypridle hyprlock

install_unless_identical() {
  if ! cmp -s "$1" "$2"; then
    sudo install -m 644 "$1" "$2"
  fi
}
install_unless_identical "$HERE/pam/hyprlock" /etc/pam.d/hyprlock
install_unless_identical "$HERE/pam/faillock.conf" /etc/security/faillock.conf

bash "$TOOLS/link.sh" "$HERE/config/hypr" "$HOME/.config/hypr"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
bash "$TOOLS/link.sh" "$HERE/launcher" "$HOME/.config/launcher"
