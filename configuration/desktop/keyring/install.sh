#!/usr/bin/env bash
# The keyring, unlocked by signing in. gnome-keyring is the Secret Service
# that chromium, the Claude desktop app and Claude Code keep their credentials
# in. It is a locked vault, and left to itself it asks for its password the
# first time anything reaches for it after login — a "keyring is locked"
# dialog over the terminal every time the machine starts.
#
# PAM fixes that the way macOS's Keychain does: pam_gnome_keyring captures the
# password you type at the tty1 login prompt and unlocks the keyring with it,
# so by the time Hyprland is up the vault is already open. This only works
# while the keyring's password and the login password are the same. If the
# dialog still appears after this, they differ — open seahorse, right-click
# the keyring, Change Password, and set it to the login password.
#
# A keyring password that doesn't match falls through to the normal prompt;
# the modules are `optional`, so a broken keyring can never keep you from
# logging in.
#
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm gnome-keyring seahorse

login_pam=/etc/pam.d/login

unlock_keyring_with_the_login_password() {
  grep -q pam_gnome_keyring "$login_pam" && return 0
  sudo tee -a "$login_pam" >/dev/null <<'PAM'

auth     optional  pam_gnome_keyring.so
session  optional  pam_gnome_keyring.so auto_start
PAM
}

unlock_keyring_with_the_login_password
