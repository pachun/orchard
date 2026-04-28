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
bash "$HERE/bootstrap/move-repo-to-home.sh" "$USERNAME" "$ROOT"

# Repo has moved; call the user-install via its new path.
bash "/home/$USERNAME/code/orchard/setup/bootstrap/run-user-install.sh" "$USERNAME"

reboot
