#!/usr/bin/env bash
# Bootstrap yay (AUR helper) from the AUR's git repo. Idempotent — skipped
# if already installed. Called by any install script that needs AUR
# packages.
set -euo pipefail

# Persist `--ignorearch` as yay's default makepkg flag. Many AUR
# PKGBUILDs hardcode arch=('x86_64') even when the source builds fine
# on aarch64; --ignorearch tells makepkg to attempt the build anyway.
# Source packages that genuinely need x86 still fail at compile time,
# so the worst case stays a noisy error rather than a silent breakage.
mkdir -p "$HOME/.config/yay"
printf '%s\n' '{"mflags": "--ignorearch"}' > "$HOME/.config/yay/config.json"

if command -v yay >/dev/null 2>&1; then
  exit 0
fi

sudo pacman -S --needed --noconfirm base-devel git

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
( cd "$tmp/yay-bin" && makepkg -si --noconfirm )
