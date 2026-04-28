#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mapfile -t pkgs < <(grep -v '^\s*\(#\|$\)' "$HERE/aur.txt")
yay -S --needed --noconfirm "${pkgs[@]}"
