#!/usr/bin/env bash
# First-boot setup. Run as root from the freshly-installed Arch ARM
# system after wifi is up. Iterates the numbered folders under
# bootstrap/ in lexical order so the FS listing matches the run order;
# adding a step is `mkdir bootstrap/NNN-action/` + drop a script in.
# Idempotent — every step is safe to re-run.
set -euo pipefail
shopt -s nullglob

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "bootstrap.sh must run as root" >&2
  exit 1
fi

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"

read -rp "username: " USERNAME </dev/tty
export USERNAME ROOT

for d in "$HERE/bootstrap"/*/; do
  for script in "$d"*.sh; do
    bash "$script"
  done
done

# Step 160 moved the repo into the new user's home; hand off to install.sh
# at its new path, running as the user.
sudo -u "$USERNAME" -H bash "/home/$USERNAME/code/orchard/setup/install.sh"

reboot
