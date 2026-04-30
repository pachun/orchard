#!/usr/bin/env bash
# User-mode setup. Each line is one idempotent step. Re-run any time.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Pin hyprland to vendored .pkg before install-packages.sh runs `pacman -Syu`,
# so the IgnorePkg entry takes effect and the upgrade skips the hypr stack.
bash "$HERE/install/install-hyprland.sh"

bash "$HERE/install/install-packages.sh"
bash "$HERE/install/install-yay.sh"
bash "$HERE/install/install-aur.sh"
bash "$HERE/install/install-ghostty.sh"
bash "$HERE/install/install-cargo-binaries.sh"
bash "$HERE/install/set-default-shell.sh"
bash "$ROOT/dotfiles/link.sh"
bash "$HERE/install/configure-git-identity.sh"
bash "$HERE/install/configure-backlight-permissions.sh"
bash "$HERE/install/configure-input-permissions.sh"
bash "$HERE/install/configure-audio.sh"
bash "$HERE/install/palm-filter/install.sh"
