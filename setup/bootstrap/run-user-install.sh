#!/usr/bin/env bash
set -euo pipefail
USERNAME="$1"
sudo -u "$USERNAME" -H bash "/home/$USERNAME/code/orchard/setup/install.sh"
