#!/usr/bin/env bash
# Generate an SSH key if missing and authenticate gh with GitHub. Idempotent —
# exits early if already authed. Ctrl+C is safe: install.sh will continue.
set -euo pipefail

if gh auth status >/dev/null 2>&1; then
  exit 0
fi

if [ ! -t 0 ]; then
  echo "github auth skipped (no tty)"
  exit 0
fi

if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
  ssh-keygen -t ed25519 -N "" -f "$HOME/.ssh/id_ed25519" -C "$(whoami)@$(hostname)"
fi

trap 'echo; echo "github auth skipped — re-run install.sh later to retry"; exit 0' INT

echo "(Ctrl+C to skip — install.sh will continue with the next step)"
gh auth login --hostname github.com --git-protocol ssh
