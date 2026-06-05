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
  # These end up in every commit's author + committer fields, visible in
  # `git log` and on GitHub. NOT a GitHub username — the human-readable
  # name and email you want associated with your commits.
  read -rp "Name for git commits: " NAME </dev/tty
  read -rp "Email for git commits: " EMAIL </dev/tty
  cat > "$LOCAL" <<EOF
[user]
	name = $NAME
	email = $EMAIL
EOF
fi
