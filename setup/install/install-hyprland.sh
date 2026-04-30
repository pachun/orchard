#!/usr/bin/env bash
# Install (or leave alone) hyprland from vendored .pkg files pinned to a
# known-good combination. Arch's rolling repo bumped hyprland + aquamarine
# in lockstep once with a regression that broke cell-background rendering
# in GTK4 apps; we don't want fresh installs to gamble on whatever's
# current upstream at install time.
#
# To bump: replace files in ./hyprland/ with new versions, re-run.
# Pin is enforced via pacman.conf's IgnorePkg so subsequent `pacman -Syu`
# (including the one in install-packages.sh) won't auto-upgrade the stack.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENDOR="$HERE/hyprland"

PINNED="hyprland aquamarine hyprtoolkit hyprland-guiutils hyprwayland-scanner hyprwire"

# Append IgnorePkg if not already present. Using an explicit grep-and-append
# rather than uncommenting the canonical commented IgnorePkg line, so we
# can coexist with install-ghostty.sh which also writes IgnorePkg entries.
if ! grep -qE "^[[:space:]]*IgnorePkg.*\bhyprland\b" /etc/pacman.conf; then
  printf 'IgnorePkg = %s\n' "$PINNED" | sudo tee -a /etc/pacman.conf >/dev/null
fi

# Already installed? Don't touch — the pinned IgnorePkg keeps it that way.
if pacman -Qi hyprland >/dev/null 2>&1; then
  exit 0
fi

# Install all vendored packages together so interdependencies resolve.
sudo pacman -U --noconfirm "$VENDOR"/*.pkg.tar.xz
