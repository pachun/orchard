#!/usr/bin/env bash
# User-mode setup. Each line is one idempotent step. Re-run any time.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

# Build patched aquamarine before install-packages.sh runs `pacman -Syu`,
# so the IgnorePkg entry takes effect and the upgrade leaves our build
# alone. See install-aquamarine.sh for the full why.
bash "$HERE/install/install-aquamarine.sh"

bash "$HERE/install/install-packages.sh"
bash "$HERE/install/install-yay.sh"
bash "$HERE/install/configure-yay-flags.sh"
bash "$HERE/install/install-aur.sh"
bash "$HERE/install/install-ghostty.sh"
bash "$HERE/install/install-cargo-binaries.sh"
bash "$HERE/install/install-claude.sh"
bash "$HERE/install/set-default-shell.sh"
bash "$ROOT/dotfiles/link.sh"
bash "$HERE/install/install-fonts.sh"
bash "$HERE/install/configure-git-identity.sh"
bash "$HERE/install/configure-default-apps.sh"
bash "$HERE/install/configure-backlight-permissions.sh"
bash "$HERE/install/configure-input-permissions.sh"
bash "$HERE/install/configure-audio.sh"
bash "$HERE/install/configure-gtk-theme.sh"
bash "$HERE/install/configure-claude.sh"
bash "$HERE/install/configure-xdg-dirs.sh"
bash "$HERE/install/configure-user-services.sh"
bash "$HERE/install/configure-nordvpn.sh"
bash "$HERE/install/configure-nvim.sh"
bash "$HERE/install/palm-filter/install.sh"
