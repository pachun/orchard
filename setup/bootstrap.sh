#!/usr/bin/env bash
# First-boot setup. Run as root after wifi is up. Each line is one step.
set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "bootstrap.sh must run as root" >&2
  exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

read -rp "username: " USERNAME </dev/tty

bash "$HERE/bootstrap/update-system.sh"
bash "$HERE/bootstrap/install-base.sh"
bash "$HERE/bootstrap/configure-locale.sh"
bash "$HERE/bootstrap/create-user.sh"      "$USERNAME"
bash "$HERE/bootstrap/enable-wheel-sudo.sh"

# System-level setup that doesn't need the new user. Runs at first boot
# so it's done before the user logs in (rather than re-prompting on every
# install.sh re-run later).
bash "$HERE/bootstrap/configure-hostname.sh"
bash "$HERE/bootstrap/configure-timezone.sh"
bash "$HERE/bootstrap/configure-kernel-cmdline.sh"
bash "$HERE/bootstrap/configure-network-dispatcher.sh"
bash "$HERE/bootstrap/configure-remove-default-user.sh"

bash "$HERE/bootstrap/move-repo-to-home.sh" "$USERNAME" "$ROOT"

# Repo has moved; call the user-install via its new path.
bash "/home/$USERNAME/code/orchard/setup/bootstrap/run-user-install.sh" "$USERNAME"

reboot
