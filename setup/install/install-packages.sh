#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t pkgs < <(grep -v '^\s*\(#\|$\)' "$HERE/pacman.txt")
sudo pacman -Syu --needed --noconfirm "${pkgs[@]}"
