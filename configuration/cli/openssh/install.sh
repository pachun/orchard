#!/usr/bin/env bash
# OpenSSH client + server, plus this machine's ed25519 identity key.
# The key is generated here (unattended, no login) so it exists before
# anything needs it; registering its public half with GitHub needs an
# account login and so lives in connections/github. Idempotent.
set -euo pipefail

sudo pacman -S --needed --noconfirm openssh

KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$KEY" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -N "" -C "$USER@$(uname -n)" -f "$KEY"
fi
