#!/usr/bin/env bash
# BlueBubbles desktop client — pairs with BlueBubbles Server running on an
# always-on Mac (the Mac handles iMessage; this is the Linux UI).
#
# The client is the 2.0.0 beta, built here from upstream's release tarball
# rather than pulled from the AUR. The PKGBUILD alongside this script explains
# why: stable can't paste text with ctrl+V on Linux, and the AUR's beta
# packages fix that only by forcing the window onto XWayland, where it renders
# soft on a HiDPI display.
#
# Preferred client settings: the app defaults a couple of Private API options
# off that we want on. They live in the app's own shared_preferences file —
# alongside the server address and password, which are per-machine secrets, so
# we can't ship the file; we patch just these two keys into it and leave the
# rest untouched. That file only exists once BlueBubbles has been run and
# paired, so on a fresh machine these take hold after you've set it up and
# re-run configure. They apply on the next BlueBubbles launch (it reads prefs
# at startup).
#   privateAPIAttachmentSend — send images/files over the Private API; the
#     legacy AppleScript attachment send times out on macOS Tahoe.
#   privateMarkChatAsRead — reading a chat here marks it read on the Mac, so
#     the phone's unread count clears the way it would on a real Mac.
# Idempotent.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

packaged_version() {
  local version release
  version="$(awk -F= '/^pkgver=/ {print $2; exit}' "$here/PKGBUILD")"
  release="$(awk -F= '/^pkgrel=/ {print $2; exit}' "$here/PKGBUILD")"
  printf '%s-%s' "$version" "$release"
}

installed_version() {
  pacman -Q bluebubbles-beta-wayland 2>/dev/null | awk '{print $2}' || true
}

client_is_up_to_date() {
  [ "$(installed_version)" = "$(packaged_version)" ]
}

replace_any_stable_client() {
  # Ours conflicts with bluebubbles-bin, and pacman answers its own conflict
  # prompt with "no" under --noconfirm — which fails the install rather than
  # replacing the package. Take stable out first. Pairing and prefs live under
  # ~/.local/share and aren't owned by the package, so they survive this.
  if pacman -Qq bluebubbles-bin >/dev/null 2>&1; then
    sudo pacman -R --noconfirm bluebubbles-bin
  fi
}

build_and_install_client() {
  # makepkg drops src/, pkg/ and the built package beside the PKGBUILD, so it
  # builds from a copy and leaves the repo clean.
  local build_directory
  build_directory="$(mktemp -d)"
  cp "$here/PKGBUILD" "$build_directory/"
  ( cd "$build_directory" && makepkg --syncdeps --install --noconfirm )
  rm -rf "$build_directory"
}

apply_preferred_client_settings() {
  local prefs="$HOME/.local/share/app.bluebubbles.BlueBubbles/shared_preferences.json"
  [ -f "$prefs" ] || return 0
  python3 - "$prefs" <<'PY'
import json, os, sys
f = sys.argv[1]
d = json.load(open(f))
changed = False
for k in ("flutter.privateAPIAttachmentSend", "flutter.privateMarkChatAsRead"):
    if d.get(k) is not True:
        d[k] = True
        changed = True
if changed:
    tmp = f + ".tmp"
    json.dump(d, open(tmp, "w"), separators=(",", ":"), ensure_ascii=False)
    os.replace(tmp, f)
PY
}

if ! client_is_up_to_date; then
  sudo pacman -S --needed --noconfirm base-devel
  replace_any_stable_client
  build_and_install_client
fi

apply_preferred_client_settings
