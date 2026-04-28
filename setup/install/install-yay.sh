#!/usr/bin/env bash
# Bootstrap yay (AUR helper) from the AUR's git repo. Skipped if already installed.
set -euo pipefail

if command -v yay >/dev/null 2>&1; then
  exit 0
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
( cd "$tmp/yay-bin" && makepkg -si --noconfirm )
