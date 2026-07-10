#!/usr/bin/env bash
# Install git + delta (the diff pager referenced from config), symlink
# the orchard-managed git config into place, and prompt for identity
# (name + email) on first run only. Idempotent — re-runs are no-ops
# once ~/.gitconfig.local exists.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source prompts so GIT_COMMIT_NAME/EMAIL are set. Idempotent — no-op
# if the dispatcher already sourced it, or if gitconfig.local exists.
source "$HERE/prompts.sh"

sudo pacman -S --needed --noconfirm git git-delta

bash "$TOOLS/link.sh" "$HERE/config" "$HOME/.config/git"

LOCAL="$HOME/.gitconfig.local"
if [ ! -f "$LOCAL" ]; then
  cat > "$LOCAL" <<EOF
[user]
	name = $GIT_COMMIT_NAME
	email = $GIT_COMMIT_EMAIL
EOF
fi
