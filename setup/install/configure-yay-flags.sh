#!/usr/bin/env bash
# Persist `--ignorearch` as yay's default makepkg flag. Many AUR
# PKGBUILDs hardcode `arch=('x86_64')` even when the source builds fine
# on aarch64; --ignorearch tells makepkg to attempt the build anyway.
# Source packages that genuinely need x86 still fail at compile time, so
# the worst case stays a noisy error rather than a silent breakage. The
# realistic risk is binary AUR packages installing as x86_64 on aarch64;
# those are rare in this stack and would fail on first run.
set -euo pipefail

mkdir -p "$HOME/.config/yay"
printf '%s\n' '{"mflags": "--ignorearch"}' > "$HOME/.config/yay/config.json"
