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
set -euo pipefail

sudo pacman -S --needed --noconfirm "$@"

# A group's name is not a package and cannot be marked.
packages_among() {
  local name
  for name in "$@"; do
    if pacman -Qq "$name" >/dev/null 2>&1; then
      printf '%s\n' "$name"
    fi
  done
}

mapfile -t installed_by_name < <(packages_among "$@")
if [ "${#installed_by_name[@]}" -gt 0 ]; then
  sudo pacman -D --asexplicit "${installed_by_name[@]}" >/dev/null
fi
