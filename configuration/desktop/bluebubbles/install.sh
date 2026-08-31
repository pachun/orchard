#!/usr/bin/env bash
# BlueBubbles desktop client — pairs with BlueBubbles Server running on an
# always-on Mac (the Mac handles iMessage; this is the Linux UI).
#
# Installed from the AUR (bluebubbles-bin), which tracks upstream's stable
# releases — so system-update's `yay -Sua` keeps it current and the app's
# own "App Update Check" nag stays quiet. This feature used to carry its
# own PKGBUILD for the 2.0.0 beta, when stable couldn't paste with ctrl+V
# on Linux and the AUR's beta packages forced XWayland and renamed the
# binary (breaking the window-class wiring in hyprland.conf,
# launch-hidden and orchard-notifications). The paste fix reached stable
# in 2.0.0, and bluebubbles-bin ships a native-Wayland launcher with the
# binary still called `bluebubbles`, so none of those reasons survive.
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
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

replace_the_packaged_beta() {
  # Ours conflicts with bluebubbles-bin, and pacman answers its own conflict
  # prompt with "no" under --noconfirm — which fails the install rather than
  # replacing the package. Take the beta out first. Pairing and prefs live
  # under ~/.local/share and aren't owned by the package, so they survive.
  if pacman -Qq bluebubbles-beta-wayland >/dev/null 2>&1; then
    sudo pacman -R --noconfirm bluebubbles-beta-wayland
  fi
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

drop_the_debug_package() {
  # The AUR PKGBUILD doesn't set options=(!debug), so makepkg builds an empty
  # -debug package alongside and yay installs both. Junk at best, and the
  # kind of leftover that trips up later `yay -Sua` runs.
  if pacman -Qq bluebubbles-bin-debug >/dev/null 2>&1; then
    sudo pacman -R --noconfirm bluebubbles-bin-debug
  fi
}

replace_the_packaged_beta
bash "$TOOLS/install-yay.sh"
bash "$TOOLS/aur-install.sh" bluebubbles-bin
drop_the_debug_package
apply_preferred_client_settings
