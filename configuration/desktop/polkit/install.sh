#!/usr/bin/env bash
# polkit auth agent — fuzzel-polkit-agent (vendored at
# dotfiles/local/bin/, now bin/ here) is a small wrapper that pipes
# JSON auth requests to/from fuzzel. cmd-polkit-git (AUR) provides
# `cmd-polkit-agent`, the backend that registers with polkit and
# emits the JSON. jq parses the requests. fuzzel is provided by the
# fuzzel feature.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bash "$HERE/../fuzzel/install.sh"

sudo pacman -S --needed --noconfirm jq

bash "$TOOLS/install-yay.sh"
yay -S --needed --noconfirm cmd-polkit-git

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
