#!/usr/bin/env bash
# Install tmux and symlink the orchard-managed config. Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm tmux

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/tmux"
bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
