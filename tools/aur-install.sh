#!/usr/bin/env bash
# Install AUR packages, fetching each package's signing keys first. Every
# argument is passed straight to `yay -S`; the ones that aren't flags are
# looked up on the AUR for their validpgpkeys.
#
# Why not let makepkg fetch the keys: it asks exactly one keyserver, the one
# in gpg.conf, and no single keyserver has everything. pgpkeys.eu carries the
# kernel signers but not eww's author; keyserver.ubuntu.com is the reverse;
# keys.openpgp.org serves most keys stripped of their user IDs, which gpg
# then refuses. dirmngr's own multi-keyserver support doesn't help either —
# it stops at the first server that answers, even when the answer is "not
# found". So each missing key is tried on each server in turn until one
# imports it with user IDs intact, and only then does yay run.
set -euo pipefail

keyservers=(hkps://pgpkeys.eu hkps://keyserver.ubuntu.com hkps://keys.openpgp.org)

packages_among() {
  local argument
  for argument in "$@"; do
    [[ "$argument" == -* ]] || printf '%s\n' "$argument"
  done
}

signing_keys_for() {
  curl -fsL "https://aur.archlinux.org/cgit/aur.git/plain/.SRCINFO?h=$1" 2>/dev/null \
    | sed -n 's/^[[:space:]]*validpgpkeys = //p' \
    || true
}

key_is_in_keyring() {
  gpg --batch --list-keys "$1" >/dev/null 2>&1
}

import_key_from_any_keyserver() {
  local key="$1" keyserver
  for keyserver in "${keyservers[@]}"; do
    gpg --batch --keyserver "$keyserver" --recv-keys "$key" >/dev/null 2>&1 || true
    key_is_in_keyring "$key" && return 0
  done
  echo "aur-install: no keyserver has signing key $key" >&2
  return 1
}

import_missing_signing_keys() {
  local package key
  for package in $(packages_among "$@"); do
    for key in $(signing_keys_for "$package"); do
      key_is_in_keyring "$key" || import_key_from_any_keyserver "$key"
    done
  done
}

import_missing_signing_keys "$@"
yay -S --needed --noconfirm "$@"
