#!/usr/bin/env bash
# Install packages from Arch's repositories, and make them stay.
#
# pacman remembers why each package is installed: asked for by name, or
# pulled in as another package's dependency. Asking for a package that is
# already present as a dependency changes nothing, so it stays marked as
# one, and removing whatever brought it removes it too. That is how the
# PDF viewer disappeared when the Nautilus previewer it arrived with was
# uninstalled. Every package an installer names is therefore also marked
# as explicitly installed.
#
# A package held back in pacman.conf (IgnorePkg) is left at the version it
# has. pacman skips held packages only during a full upgrade; naming one
# upgrades it, and --noconfirm answers yes to "install anyway?". That is
# how the kernel headers moved ahead of a held kernel and took the camera
# drivers built for it with them.
set -euo pipefail

is_installed() {
  pacman -Qq "$1" >/dev/null 2>&1
}

is_held_back() {
  pacman-conf IgnorePkg | grep -qxF "$1"
}

packages_free_to_install_among() {
  local name
  for name in "$@"; do
    if is_installed "$name" && is_held_back "$name"; then
      echo "install-packages: $name is held back in pacman.conf; leaving it as it is" >&2
    else
      printf '%s\n' "$name"
    fi
  done
}

mapfile -t free_to_install < <(packages_free_to_install_among "$@")
if [ "${#free_to_install[@]}" -gt 0 ]; then
  sudo pacman -S --needed --noconfirm "${free_to_install[@]}"
fi

# A group's name is not a package and cannot be marked.
packages_among() {
  local name
  for name in "$@"; do
    if is_installed "$name"; then
      printf '%s\n' "$name"
    fi
  done
}

mapfile -t installed_by_name < <(packages_among "$@")
if [ "${#installed_by_name[@]}" -gt 0 ]; then
  sudo pacman -D --asexplicit "${installed_by_name[@]}" >/dev/null
fi
