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
# logging in. `passwd` gets the module too, so changing the login password
# re-keys the keyring with it and the two never drift apart.
#
# PAM only unlocks the keyring named "login". A machine that already had
# secrets before this ran keeps them in a "Default Keyring" gnome-keyring
# invented on its own, and that one stays locked. move-secrets-into-login-keyring
# folds it into "login"; it needs the desktop up, so run ./configure (or
# that script) from inside Hyprland once after the first login.
#
# Idempotent.
set -euo pipefail
TOOLS="${TOOLS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)/tools}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

sudo pacman -S --needed --noconfirm gnome-keyring seahorse

login_pam=/etc/pam.d/login
passwd_pam=/etc/pam.d/passwd

unlock_keyring_with_the_login_password() {
  grep -q pam_gnome_keyring "$login_pam" && return 0
  sudo tee -a "$login_pam" >/dev/null <<'PAM'

auth     optional  pam_gnome_keyring.so
session  optional  pam_gnome_keyring.so auto_start
PAM
}

rekey_keyring_when_the_login_password_changes() {
  grep -q pam_gnome_keyring "$passwd_pam" && return 0
  sudo tee -a "$passwd_pam" >/dev/null <<'PAM'
password	optional	pam_gnome_keyring.so
PAM
}

unlock_keyring_with_the_login_password
rekey_keyring_when_the_login_password_changes

bash "$TOOLS/link.sh" "$HERE/bin" "$HOME/.local/bin"
"$HERE/bin/move-secrets-into-login-keyring"
