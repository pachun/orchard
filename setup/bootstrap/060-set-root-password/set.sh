#!/usr/bin/env bash
# Mirror the primary user's password to root. The point is recovery:
# if a desktop config (hyprland, gdm, etc.) ever leaves you unable to
# reach a graphical session, Ctrl+Alt+F2 to a TTY and log in as root
# with the same password you'd use for your account. Without this,
# recovery means booting with `init=/bin/bash` from the bootloader or
# attaching a Live USB.
#
# Reads the encrypted hash via `getent shadow` and applies it with
# `chpasswd -e`, so the plaintext is never re-derived or stored.
# Reads USERNAME from the env (exported by the dispatcher).
set -euo pipefail

hash=$(getent shadow "$USERNAME" | cut -d: -f2)
case "$hash" in
  ""|"!"*|"*") echo "060-set-root-password: $USERNAME has no password set" >&2; exit 1 ;;
esac

echo "root:$hash" | chpasswd -e

cat <<EOF

Root password set to match ${USERNAME}'s. If your desktop login chain
breaks, switch to a TTY (Ctrl+Alt+F2) and log in as 'root' with your
normal password to recover. ${USERNAME} also has sudo via wheel.
EOF
