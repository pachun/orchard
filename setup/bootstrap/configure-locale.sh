#!/usr/bin/env bash
# Idempotent: sed only matches lines that are still commented.
set -euo pipefail
sed -i 's/^#\(en_US\.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
