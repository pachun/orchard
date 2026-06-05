#!/usr/bin/env bash
# Idempotent: skips useradd if the user exists, and skips the password
# prompt if a password is already set (passwd -S reports 'P' for set).
# Reads USERNAME from the env (exported by the dispatcher).
set -euo pipefail

if ! id "$USERNAME" >/dev/null 2>&1; then
  useradd -m -G wheel -s /bin/bash "$USERNAME"
fi

if [ "$(passwd -S "$USERNAME" 2>/dev/null | awk '{print $2}')" != "P" ]; then
  passwd "$USERNAME" </dev/tty
fi
