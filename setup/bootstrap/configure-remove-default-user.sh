#!/usr/bin/env bash
# Delete the `alarm` user that ships with the Arch Linux ARM image used by
# the Asahi installer. It's a stray sudo-capable account we never use,
# and its presence in `wheel` makes polkit prompts ambiguous about which
# identity to authenticate as. Idempotent — no-op if alarm is already gone.
set -euo pipefail

if id alarm >/dev/null 2>&1; then
    sudo userdel -r alarm
fi
