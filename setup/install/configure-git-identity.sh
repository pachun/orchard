#!/usr/bin/env bash
# Prompt for git name + email on first run and write them to ~/.gitconfig.local,
# which dotfiles/gitconfig pulls in via its [include] directive. Idempotent —
# skipped if the file already exists.
set -euo pipefail

LOCAL="$HOME/.gitconfig.local"
if [ -f "$LOCAL" ]; then
  exit 0
fi

read -rp "git user name: " NAME </dev/tty
read -rp "git user email: " EMAIL </dev/tty

cat > "$LOCAL" <<EOF
[user]
	name = $NAME
	email = $EMAIL
EOF
