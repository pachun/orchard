#!/usr/bin/env bash
# User-mode setup. Each line is one idempotent step. Re-run any time.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

bash "$HERE/install/install-packages.sh"
bash "$HERE/install/install-yay.sh"
bash "$HERE/install/install-aur.sh"
bash "$HERE/install/set-default-shell.sh"
bash "$ROOT/dotfiles/link.sh"
bash "$HERE/install/configure-git-identity.sh"
bash "$HERE/install/configure-backlight-permissions.sh"
bash "$HERE/install/palm-filter/install.sh"
