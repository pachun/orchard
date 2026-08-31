#!/usr/bin/env bash
# zsh + syntax highlighting + the orchard zshrc that fans out into
# zshrc.d/cli/ (always) and zshrc.d/desktop/ (in desktop mode). Sets
# zsh as the login shell if it isn't already. The active mode is
# persisted to ~/.config/orchard/mode so future shell startups know
# which subset to source — set from $ORCHARD_MODE (exported by the
# top-level dispatcher) or defaulting to 'desktop'.
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm zsh zsh-syntax-highlighting

if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then
  chsh -s /usr/bin/zsh
fi

# Top-level rc gets symlinked individually since it lives at $HOME, not
# under $HOME/.config/.
mkdir -p "$HOME"
ln -sfn "$HERE/config/zshrc" "$HOME/.zshrc"

# zshrc.d/ goes under ~/.config/zsh/ — the symlinked location the
# zshrc references via $HOME/.config/zsh/zshrc.d/.
bash "$TOOLS/link.sh" "$HERE/config/zshrc.d" "$HOME/.config/zsh/zshrc.d"

# Persist mode for future shell startups.
mkdir -p "$HOME/.config/orchard"
echo "${ORCHARD_MODE:-desktop}" > "$HOME/.config/orchard/mode"
