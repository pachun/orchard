#!/usr/bin/env bash
# Wire up gnome-keyring auto-unlock at TTY login. PAM's `auth` line
# captures the login password during authentication; `session auto_start`
# starts gnome-keyring-daemon and unlocks the keyring with that captured
# password — same paradigm as macOS Keychain.
#
# If the keyring password doesn't match the login password, PAM silently
# fails to unlock and the user sees the normal first-app keyring prompt.
# No risk of lockout. Idempotent.
set -euo pipefail

PAM_FILE=/etc/pam.d/login

if grep -q 'pam_gnome_keyring' "$PAM_FILE"; then
    exit 0
fi

sudo tee -a "$PAM_FILE" >/dev/null <<'EOF'

# orchard: auto-unlock gnome-keyring with login password.
auth     optional  pam_gnome_keyring.so
session  optional  pam_gnome_keyring.so auto_start
EOF
