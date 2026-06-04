#!/usr/bin/env bash
# Install git + delta (the diff pager referenced from config), symlink
# the orchard-managed git config into place, and prompt for identity
# (name + email) on first run only. Idempotent — re-runs are no-ops
# once ~/.gitconfig.local exists.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm git git-delta

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/git"

LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$LOCAL" ]; then
  read -rp "git user name: " NAME </dev/tty
  read -rp "git user email: " EMAIL </dev/tty
  cat > "$LOCAL" <<EOF
[user]
	name = $NAME
	email = $EMAIL
EOF
fi
