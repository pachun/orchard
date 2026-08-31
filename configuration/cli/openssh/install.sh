#!/usr/bin/env bash
# OpenSSH client + server, plus this machine's ed25519 identity key.
#
# The key is generated here (unattended, no login) so it exists before
# anything needs it; registering its public half with GitHub needs an
# account login and so lives in connections/github.
#
# Every orchard machine runs sshd so the others can reach it — over the
# tailnet by name (`ssh xps`) or the LAN. Only keys get in: password auth
# and root login are off via the drop-in, and the keys that get in are
# whatever your GitHub account serves at https://github.com/<you>.keys —
# the same set connections/github uploads to. That keeps keys out of the
# repo (anyone can use this setup and gets their own keys, not the
# author's) with nothing to sync by hand: bring up a new machine with
# ./connect github, and every other machine admits it the next time this
# runs there.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm openssh

KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$KEY" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -N "" -C "$USER@$(uname -n)" -f "$KEY"
fi

install_authorized_keys_from_github() {
  local github_user your_keys
  if ! github_user="$(gh api user -q .login 2>/dev/null)"; then
    echo "openssh: not logged in to GitHub — run ./connect github, then re-run" >&2
    echo "openssh: this to let your other machines in. sshd is up either way." >&2
    return 0
  fi
  if ! your_keys="$(curl -fsS -m 15 "https://github.com/$github_user.keys")" \
      || ! printf '%s' "$your_keys" | grep -q '^ssh-'; then
    echo "openssh: could not fetch https://github.com/$github_user.keys —" >&2
    echo "openssh: keeping the existing authorized_keys untouched." >&2
    return 0
  fi
  printf '%s\n' "$your_keys" > "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
}

install_authorized_keys_from_github

sudo install -Dm644 "$HERE/sshd_config.d/orchard.conf" /etc/ssh/sshd_config.d/orchard.conf
sudo systemctl enable sshd.service
sudo systemctl restart sshd.service
