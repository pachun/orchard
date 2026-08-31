#!/usr/bin/env bash
# OpenSSH client + server, plus this machine's ed25519 identity key.
#
# The key is generated here (unattended, no login) so it exists before
# anything needs it; registering its public half with GitHub needs an
# account login and so lives in connections/github.
#
# Every orchard machine runs sshd so the others can reach it — over the
# tailnet by name (`ssh xps`) or the LAN. Only keys get in: password auth
# and root login are off via the drop-in, and the keys that get in are the
# ones under authorized-keys/, one per machine, which this script writes
# out as ~/.ssh/authorized_keys. It also copies this machine's own public
# key into that directory, so the flow for a new machine is: run this,
# commit the new <hostname>.pub, and re-run it on the machines that should
# let the new one in. Public keys are safe to commit; the private half
# never leaves ~/.ssh.
# Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm openssh

KEY="$HOME/.ssh/id_ed25519"
PUB="$KEY.pub"
if [ ! -f "$KEY" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  ssh-keygen -t ed25519 -N "" -C "$USER@$(uname -n)" -f "$KEY"
fi

register_this_machines_key() {
  local registered="$HERE/authorized-keys/$(uname -n).pub"
  if ! cmp -s "$PUB" "$registered"; then
    cp "$PUB" "$registered"
    echo "openssh: registered this machine's key as $(basename "$registered") — commit it so other machines let you in"
  fi
}

install_authorized_keys() {
  local authorized="$HOME/.ssh/authorized_keys"
  cat "$HERE"/authorized-keys/*.pub > "$authorized"
  chmod 600 "$authorized"
}

register_this_machines_key
install_authorized_keys

sudo install -Dm644 "$HERE/sshd_config.d/orchard.conf" /etc/ssh/sshd_config.d/orchard.conf
sudo systemctl enable sshd.service
sudo systemctl restart sshd.service
